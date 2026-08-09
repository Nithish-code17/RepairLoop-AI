import {getStorage} from "firebase-admin/storage";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {defineSecret, defineString} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {z} from "zod";

import {createDiagnosisProvider} from "../ai/provider-factory.js";
import type {DiagnosisResult} from "../ai/types.js";
import {requireAuth, requireProductAccess} from "../common/auth.js";
import {parseInput} from "../common/validation.js";

const aiApiKey = defineSecret("AI_API_KEY");
const aiProviderName = defineString("AI_PROVIDER", {default: "openai"});
const aiModel = defineString("AI_MODEL", {default: "gpt-4.1-mini"});
const aiBaseUrl = defineString("AI_BASE_URL", {default: "https://api.openai.com/v1"});

const inputSchema = z.object({
  productId: z.string().min(1).max(160),
  symptoms: z.string().trim().min(15).max(1500),
  imageStoragePath: z.string().max(600).nullable().optional(),
});

const hazardousPattern =
  /swollen|bulging|smoke|burning smell|fire|spark|very hot|overheat|high voltage|electric shock/i;

async function loadImageDataUrl(
  userId: string,
  storagePath?: string | null,
): Promise<{dataUrl?: string; downloadUrl?: string}> {
  if (!storagePath) return {};
  if (!storagePath.startsWith(`diagnosis-images/${userId}/`)) {
    throw new HttpsError("permission-denied", "Invalid diagnosis image path.");
  }
  const file = getStorage().bucket().file(storagePath);
  const [metadata] = await file.getMetadata();
  const contentType = metadata.contentType ?? "";
  const size = Number(metadata.size ?? 0);
  if (!contentType.startsWith("image/") || size > 10 * 1024 * 1024) {
    throw new HttpsError("invalid-argument", "Upload a valid image under 10 MB.");
  }
  const [buffer] = await file.download();
  return {
    dataUrl: `data:${contentType};base64,${buffer.toString("base64")}`,
    downloadUrl: storagePath,
  };
}

function applySafetyPolicy(result: DiagnosisResult, symptoms: string): DiagnosisResult {
  if (!hazardousPattern.test(symptoms)) return result;
  return {
    ...result,
    severity: "high",
    professional_service_recommended: true,
    recommended_action:
      "Stop using and charging the product. Move away from flammable materials only " +
      "if this can be done safely, and contact a qualified service professional.",
    safety_warning:
      "Potential electrical or battery hazard. Do not open, puncture, charge, or continue using the device.",
  };
}

export const analyzeDiagnosis = onCall(
  {
    region: "asia-south1",
    timeoutSeconds: 120,
    memory: "1GiB",
    secrets: [aiApiKey],
    enforceAppCheck: true,
  },
  async (request) => {
    const userId = requireAuth(request);
    const input = parseInput(inputSchema, request.data);
    const product = await requireProductAccess(userId, input.productId);
    const firestore = getFirestore();

    const [repairsSnapshot, componentsSnapshot, image] = await Promise.all([
      firestore
        .collection("repairs")
        .where("productId", "==", input.productId)
        .orderBy("updatedAt", "desc")
        .limit(5)
        .get(),
      firestore
        .collection("products")
        .doc(input.productId)
        .collection("components")
        .orderBy("installedAt", "desc")
        .limit(20)
        .get(),
      loadImageDataUrl(userId, input.imageStoragePath),
    ]);

    const provider = createDiagnosisProvider({
      provider: aiProviderName.value(),
      apiKey: aiApiKey.value(),
      model: aiModel.value(),
      baseUrl: aiBaseUrl.value(),
    });

    let result: DiagnosisResult;
    try {
      result = await provider.analyze({
        product: {
          brand: String(product.brand ?? ""),
          model: String(product.model ?? ""),
          category: String(product.category ?? ""),
          name: String(product.name ?? ""),
        },
        symptoms: input.symptoms,
        previousRepairs: repairsSnapshot.docs.map((document) => ({
          issueSummary: String(document.data().issueSummary ?? ""),
          status: String(document.data().status ?? ""),
          technicianNotes: document.data().technicianNotes
            ? String(document.data().technicianNotes)
            : undefined,
        })),
        components: componentsSnapshot.docs.map((document) => ({
          name: String(document.data().name ?? ""),
          condition: String(document.data().condition ?? ""),
          isOriginal: Boolean(document.data().isOriginal),
        })),
        imageDataUrl: image.dataUrl,
      });
      result = applySafetyPolicy(result, input.symptoms);
    } catch (error) {
      logger.error("Multimodal diagnosis provider failed", {
        provider: provider.name,
        model: provider.model,
        error,
      });
      throw new HttpsError(
        "internal",
        "The preliminary assessment could not be completed. Try again later.",
      );
    }

    const diagnosisReference = firestore.collection("diagnoses").doc();
    const lifecycleReference = firestore.collection("lifecycleEvents").doc();
    const batch = firestore.batch();
    const timestamp = FieldValue.serverTimestamp();
    batch.set(diagnosisReference, {
      productId: input.productId,
      userId,
      symptoms: input.symptoms,
      imageUrl: image.downloadUrl ?? null,
      deviceSummary: result.device_summary,
      possibleIssue: result.possible_issue,
      confidence: result.confidence,
      reasoningSummary: result.reasoning_summary,
      recommendedChecks: result.recommended_checks,
      recommendedAction: result.recommended_action,
      severity: result.severity,
      professionalServiceRecommended: result.professional_service_recommended,
      safetyWarning: result.safety_warning,
      provider: provider.name,
      model: provider.model,
      createdAt: timestamp,
    });
    batch.update(firestore.collection("products").doc(input.productId), {
      status: "diagnosisPending",
      updatedAt: timestamp,
    });
    batch.set(lifecycleReference, {
      productId: input.productId,
      type: "ai_diagnosis",
      title: "Preliminary assessment completed",
      description: result.possible_issue,
      actorId: userId,
      createdAt: timestamp,
    });
    await batch.commit();

    return {diagnosisId: diagnosisReference.id};
  },
);
