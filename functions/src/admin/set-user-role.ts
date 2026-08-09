import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {z} from "zod";

import {requireAuth, requireRole} from "../common/auth.js";
import {parseInput} from "../common/validation.js";

const inputSchema = z.object({
  userId: z.string().min(1).max(160),
  role: z.enum(["customer", "manufacturer", "technician", "admin"]),
});

export const setUserRole = onCall(
  {region: "asia-south1", enforceAppCheck: true},
  async (request) => {
    const adminId = requireAuth(request);
    await requireRole(adminId, ["admin"]);
    const input = parseInput(inputSchema, request.data);
    const userReference = getFirestore().collection("users").doc(input.userId);
    const user = await userReference.get();
    if (!user.exists) throw new HttpsError("not-found", "User not found.");
    await Promise.all([
      userReference.update({
        role: input.role,
        updatedAt: FieldValue.serverTimestamp(),
        roleUpdatedBy: adminId,
      }),
      getAuth().setCustomUserClaims(input.userId, {role: input.role}),
    ]);
    return {success: true};
  },
);
