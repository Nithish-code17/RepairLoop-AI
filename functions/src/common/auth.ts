import {getFirestore} from "firebase-admin/firestore";
import type {CallableRequest} from "firebase-functions/v2/https";
import {HttpsError} from "firebase-functions/v2/https";

export type UserRole = "customer" | "manufacturer" | "technician" | "admin";

export function requireAuth(request: CallableRequest<unknown>): string {
  const userId = request.auth?.uid;
  if (!userId) throw new HttpsError("unauthenticated", "Sign in is required.");
  return userId;
}

export async function getUserRole(userId: string): Promise<UserRole> {
  const snapshot = await getFirestore().collection("users").doc(userId).get();
  const role = snapshot.data()?.role;
  if (!["customer", "manufacturer", "technician", "admin"].includes(role)) {
    throw new HttpsError("permission-denied", "A valid RepairLoop role is required.");
  }
  return role as UserRole;
}

export async function requireRole(
  userId: string,
  roles: UserRole[],
): Promise<UserRole> {
  const role = await getUserRole(userId);
  if (!roles.includes(role)) {
    throw new HttpsError("permission-denied", "Your role cannot perform this action.");
  }
  return role;
}

export async function requireProductAccess(
  userId: string,
  productId: string,
): Promise<Record<string, unknown>> {
  const firestore = getFirestore();
  const [productSnapshot, role] = await Promise.all([
    firestore.collection("products").doc(productId).get(),
    getUserRole(userId),
  ]);
  if (!productSnapshot.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  const product = productSnapshot.data()!;
  const hasAccess =
    product.ownerId === userId ||
    product.manufacturerId === userId ||
    role === "technician" ||
    role === "admin";
  if (!hasAccess) {
    throw new HttpsError("permission-denied", "You cannot access this product.");
  }
  return product;
}
