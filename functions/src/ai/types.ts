import {z} from "zod";

export const diagnosisResultSchema = z.object({
  device_summary: z.string().min(1).max(500),
  possible_issue: z.string().min(1).max(500),
  confidence: z.number().min(0).max(1),
  reasoning_summary: z.string().min(1).max(900),
  recommended_checks: z.array(z.string().min(1).max(300)).max(6),
  recommended_action: z.string().min(1).max(600),
  severity: z.enum(["low", "medium", "high"]),
  professional_service_recommended: z.boolean(),
  safety_warning: z.string().max(700),
});

export type DiagnosisResult = z.infer<typeof diagnosisResultSchema>;

export interface DiagnosisContext {
  product: {
    brand: string;
    model: string;
    category: string;
    name: string;
  };
  symptoms: string;
  previousRepairs: Array<{
    issueSummary: string;
    status: string;
    technicianNotes?: string;
  }>;
  components: Array<{
    name: string;
    condition: string;
    isOriginal: boolean;
  }>;
  imageDataUrl?: string;
}

export interface MultimodalDiagnosisProvider {
  readonly name: string;
  readonly model: string;
  analyze(context: DiagnosisContext): Promise<DiagnosisResult>;
}
