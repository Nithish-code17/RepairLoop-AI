import {HttpsError} from "firebase-functions/v2/https";
import type {ZodType} from "zod";

export function parseInput<T>(schema: ZodType<T>, input: unknown): T {
  const result = schema.safeParse(input);
  if (!result.success) {
    throw new HttpsError(
      "invalid-argument",
      result.error.issues.map((issue) => issue.message).join("; "),
    );
  }
  return result.data;
}
