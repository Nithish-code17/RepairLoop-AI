import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {z} from "zod";

import {requireAuth, requireRole} from "../common/auth.js";
import {parseInput} from "../common/validation.js";

const inputSchema = z.object({
  name: z.string().trim().min(2).max(120),
  brand: z.string().trim().min(1).max(80),
  model: z.string().trim().min(1).max(100),
  category: z.string().trim().min(2).max(60),
  serialNumber: z.string().trim().min(3).max(120),
  ownerEmail: z.email().transform((email) => email.toLowerCase()),
  purchaseDate: z.iso.datetime().nullable().optional(),
  warrantyEnd: z.iso.datetime().nullable().optional(),
  components: z.array(z.object({
    name: z.string().trim().min(2).max(120),
    partNumber: z.string().trim().min(1).max(160),
  })).max(50).default([]),
});

const categoryCodes: Record<string, string> = {
  laptop: "LP",
  "mobile phone": "MB",
  tablet: "TB",
  television: "TV",
  appliance: "AP",
  other: "OT",
};

export const registerProduct = onCall(
  {region: "asia-south1", enforceAppCheck: true},
  async (request) => {
    const manufacturerId = requireAuth(request);
    await requireRole(manufacturerId, ["manufacturer", "admin"]);
    const input = parseInput(inputSchema, request.data);
    const firestore = getFirestore();

    const ownerSnapshot = await firestore
      .collection("users")
      .where("email", "==", input.ownerEmail)
      .limit(1)
      .get();
    if (ownerSnapshot.empty) {
      throw new HttpsError(
        "not-found",
        "The owner must create a RepairLoop customer account first.",
      );
    }
    const ownerId = ownerSnapshot.docs[0].id;

    const duplicate = await firestore
      .collection("products")
      .where("manufacturerId", "==", manufacturerId)
      .where("serialNumber", "==", input.serialNumber)
      .limit(1)
      .get();
    if (!duplicate.empty) {
      throw new HttpsError(
        "already-exists",
        "A product with this serial number is already registered.",
      );
    }

    const counterReference = firestore.collection("counters").doc("passports");
    const productReference = firestore.collection("products").doc();
    const lifecycleReference = firestore.collection("lifecycleEvents").doc();
    const categoryCode = categoryCodes[input.category.toLowerCase()] ?? "OT";

    const passportId = await firestore.runTransaction(async (transaction) => {
      const counter = await transaction.get(counterReference);
      const nextNumber = ((counter.data()?.value as number | undefined) ?? 0) + 1;
      const generatedId =
        `RLP-${categoryCode}-${nextNumber.toString().padStart(6, "0")}`;
      const timestamp = FieldValue.serverTimestamp();

      transaction.set(counterReference, {value: nextNumber, updatedAt: timestamp});
      transaction.set(productReference, {
        passportId: generatedId,
        ownerId,
        manufacturerId,
        name: input.name,
        brand: input.brand,
        model: input.model,
        category: input.category,
        serialNumber: input.serialNumber,
        status: "active",
        purchaseDate: input.purchaseDate
          ? Timestamp.fromDate(new Date(input.purchaseDate))
          : null,
        warrantyEnd: input.warrantyEnd
          ? Timestamp.fromDate(new Date(input.warrantyEnd))
          : null,
        createdAt: timestamp,
        updatedAt: timestamp,
      });
      transaction.set(lifecycleReference, {
        productId: productReference.id,
        type: "product_registered",
        title: "Product passport issued",
        description: `${input.brand} ${input.model} was registered as ${generatedId}.`,
        actorId: manufacturerId,
        createdAt: timestamp,
      });
      for (const component of input.components) {
        transaction.set(productReference.collection("components").doc(), {
          productId: productReference.id,
          name: component.name,
          partNumber: component.partNumber,
          condition: "active",
          isOriginal: true,
          installedAt: timestamp,
          replacedAt: null,
        });
      }
      return generatedId;
    });

    return {productId: productReference.id, passportId};
  },
);
