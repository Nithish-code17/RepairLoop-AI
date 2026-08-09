import {
  diagnosisResultSchema,
  type DiagnosisContext,
  type DiagnosisResult,
  type MultimodalDiagnosisProvider,
} from "./types.js";

export class OpenAiMultimodalProvider implements MultimodalDiagnosisProvider {
  readonly name = "openai";

  constructor(
    private readonly apiKey: string,
    readonly model: string,
    private readonly baseUrl = "https://api.openai.com/v1",
  ) {}

  async analyze(context: DiagnosisContext): Promise<DiagnosisResult> {
    const productContext = JSON.stringify({
      product: context.product,
      symptoms: context.symptoms,
      previous_repairs: context.previousRepairs,
      components: context.components,
    });

    const userContent: Array<Record<string, unknown>> = [
      {
        type: "input_text",
        text: `Analyze this electronic product fault context:\n${productContext}`,
      },
    ];
    if (context.imageDataUrl) {
      userContent.push({type: "input_image", image_url: context.imageDataUrl});
    }

    const response = await fetch(`${this.baseUrl}/responses`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: this.model,
        instructions:
          "You provide preliminary electronic-product troubleshooting guidance. " +
          "Never claim certainty or reveal private chain-of-thought. Return only a " +
          "concise user-facing assessment. Never instruct users to open high-voltage " +
          "equipment, puncture batteries, bypass safety systems, or handle hazardous " +
          "components. For swollen batteries, smoke, burning smells, sparks, heat, or " +
          "high-voltage risk, set severity high and recommend immediate professional service.",
        input: [{role: "user", content: userContent}],
        text: {
          format: {
            type: "json_schema",
            name: "repairloop_diagnosis",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              properties: {
                device_summary: {type: "string"},
                possible_issue: {type: "string"},
                confidence: {type: "number", minimum: 0, maximum: 1},
                reasoning_summary: {type: "string"},
                recommended_checks: {
                  type: "array",
                  items: {type: "string"},
                  maxItems: 6,
                },
                recommended_action: {type: "string"},
                severity: {type: "string", enum: ["low", "medium", "high"]},
                professional_service_recommended: {type: "boolean"},
                safety_warning: {type: "string"},
              },
              required: [
                "device_summary",
                "possible_issue",
                "confidence",
                "reasoning_summary",
                "recommended_checks",
                "recommended_action",
                "severity",
                "professional_service_recommended",
                "safety_warning",
              ],
            },
          },
        },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`AI provider request failed (${response.status}): ${body.slice(0, 300)}`);
    }
    const payload = (await response.json()) as Record<string, unknown>;
    const outputText = extractOutputText(payload);
    if (typeof outputText !== "string") {
      throw new Error("AI provider did not return structured output.");
    }
    return diagnosisResultSchema.parse(JSON.parse(outputText));
  }
}

function extractOutputText(payload: Record<string, unknown>): string | undefined {
  if (typeof payload.output_text === "string") return payload.output_text;
  if (!Array.isArray(payload.output)) return undefined;
  for (const item of payload.output) {
    if (!item || typeof item !== "object") continue;
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      if (!part || typeof part !== "object") continue;
      const text = (part as Record<string, unknown>).text;
      if (typeof text === "string") return text;
    }
  }
  return undefined;
}
