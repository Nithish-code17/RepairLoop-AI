import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {z} from "zod";

import {requireAuth, requireProductAccess, requireRole} from "../common/auth.js";
import {parseInput} from "../common/validation.js";

const createSchema = z.object({
  productId: z.string().min(1).max(160),
  diagnosisId: z.string().min(1).max(160),
  issueSummary: z.string().trim().min(3).max(500),
});

const statuses = [
  "requested",
  "accepted",
  "inspecting",
  "awaitingParts",
  "repairing",
  "completed",
  "cancelled",
] as const;

const updateSchema = z.object({
  repairId: z.string().min(1).max(160),
  status: z.enum(statuses),
  technicianNotes: z.string().trim().max(3000).nullable().optional(),
});

const componentSchema = z.object({
  repairId: z.string().min(1).max(160),
  oldComponentId: z.string().max(160).nullable().optional(),
  name: z.string().trim().min(2).max(120),
  partNumber: z.string().trim().min(1).max(160),
  condition: z.string().trim().min(2).max(80).default("active"),
});

const allowedTransitions: Record<string, string[]> = {
  requested: ["accepted", "cancelled"],
  accepted: ["inspecting", "cancelled"],
  inspecting: ["awaitingParts", "repairing", "cancelled"],
  awaitingParts: ["repairing", "cancelled"],
  repairing: ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

export const createRepairRequest = onCall(
  {region: "asia-south1", enforceAppCheck: true},
  async (request) => {
    const userId = requireAuth(request);
    const input = parseInput(createSchema, request.data);
    const product = await requireProductAccess(userId, input.productId);
    if (product.ownerId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Only the current product owner can request a repair.",
      );
    }

    const firestore = getFirestore();
    const diagnosis = await firestore
      .collection("diagnoses")
      .doc(input.diagnosisId)
      .get();
    if (
      !diagnosis.exists ||
      diagnosis.data()?.productId !== input.productId ||
      diagnosis.data()?.userId !== userId
    ) {
      throw new HttpsError("failed-precondition", "A valid diagnosis is required.");
    }

    const repairReference = firestore.collection("repairs").doc();
    const lifecycleReference = firestore.collection("lifecycleEvents").doc();
    const timestamp = FieldValue.serverTimestamp();
    const batch = firestore.batch();
    batch.set(repairReference, {
      productId: input.productId,
      ownerId: userId,
      manufacturerId: product.manufacturerId,
      diagnosisId: input.diagnosisId,
      technicianId: null,
      status: "requested",
      issueSummary: input.issueSummary,
      technicianNotes: null,
      createdAt: timestamp,
      updatedAt: timestamp,
      completedAt: null,
    });
    batch.update(firestore.collection("products").doc(input.productId), {
      status: "repairPending",
      updatedAt: timestamp,
    });
    batch.set(lifecycleReference, {
      productId: input.productId,
      type: "repair_requested",
      title: "Repair requested",
      description: input.issueSummary,
      actorId: userId,
      createdAt: timestamp,
    });
    await batch.commit();
    return {repairId: repairReference.id};
  },
);

export const updateRepairStatus = onCall(
  {region: "asia-south1", enforceAppCheck: true},
  async (request) => {
    const userId = requireAuth(request);
    await requireRole(userId, ["technician", "admin"]);
    const input = parseInput(updateSchema, request.data);
    const firestore = getFirestore();
    const repairReference = firestore.collection("repairs").doc(input.repairId);

    await firestore.runTransaction(async (transaction) => {
      const repairSnapshot = await transaction.get(repairReference);
      if (!repairSnapshot.exists) {
        throw new HttpsError("not-found", "Repair case not found.");
      }
      const repair = repairSnapshot.data()!;
      if (repair.technicianId && repair.technicianId !== userId) {
        throw new HttpsError(
          "permission-denied",
          "This case is assigned to another technician.",
        );
      }
      const currentStatus = String(repair.status);
      if (!allowedTransitions[currentStatus]?.includes(input.status)) {
        throw new HttpsError(
          "failed-precondition",
          `Cannot move a repair from ${currentStatus} to ${input.status}.`,
        );
      }

      const timestamp = FieldValue.serverTimestamp();
      const updates: Record<string, unknown> = {
        status: input.status,
        technicianId: repair.technicianId ?? userId,
        technicianNotes: input.technicianNotes ?? repair.technicianNotes ?? null,
        updatedAt: timestamp,
      };
      if (input.status === "completed") updates.completedAt = timestamp;
      transaction.update(repairReference, updates);
      transaction.update(firestore.collection("products").doc(repair.productId), {
        status: input.status === "completed" ? "repaired" : "underRepair",
        updatedAt: timestamp,
      });
      transaction.set(firestore.collection("lifecycleEvents").doc(), {
        productId: repair.productId,
        type: "repair_status",
        title: `Repair ${input.status}`,
        description:
          input.technicianNotes || `Repair status changed to ${input.status}.`,
        actorId: userId,
        createdAt: timestamp,
      });
    });
    return {success: true};
  },
);

export const recordComponentReplacement = onCall(
  {region: "asia-south1", enforceAppCheck: true},
  async (request) => {
    const userId = requireAuth(request);
    await requireRole(userId, ["technician", "admin"]);
    const input = parseInput(componentSchema, request.data);
    const firestore = getFirestore();
    const repair = await firestore.collection("repairs").doc(input.repairId).get();
    if (!repair.exists) throw new HttpsError("not-found", "Repair case not found.");
    const repairData = repair.data()!;
    if (!repairData.technicianId || repairData.technicianId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Accept this repair before recording replacement parts.",
      );
    }

    const productReference = firestore
      .collection("products")
      .doc(repairData.productId);
    const timestamp = FieldValue.serverTimestamp();
    const batch = firestore.batch();
    if (input.oldComponentId) {
      batch.update(productReference.collection("components").doc(input.oldComponentId), {
        condition: "replaced",
        replacedAt: timestamp,
      });
    }
    batch.set(productReference.collection("components").doc(), {
      productId: repairData.productId,
      repairId: input.repairId,
      name: input.name,
      partNumber: input.partNumber,
      condition: input.condition,
      isOriginal: false,
      installedAt: timestamp,
      replacedAt: null,
    });
    batch.set(firestore.collection("lifecycleEvents").doc(), {
      productId: repairData.productId,
      type: "component_replaced",
      title: "Replacement component installed",
      description: `${input.name} (${input.partNumber}) was recorded.`,
      actorId: userId,
      createdAt: timestamp,
    });
    batch.update(repair.ref, {updatedAt: timestamp});
    await batch.commit();
    return {success: true};
  },
);
