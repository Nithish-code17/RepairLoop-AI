import {OpenAiMultimodalProvider} from "./openai-provider.js";
import type {MultimodalDiagnosisProvider} from "./types.js";

interface ProviderConfiguration {
  provider: string;
  apiKey: string;
  model: string;
  baseUrl?: string;
}

export function createDiagnosisProvider(
  config: ProviderConfiguration,
): MultimodalDiagnosisProvider {
  switch (config.provider.toLowerCase()) {
  case "openai":
    return new OpenAiMultimodalProvider(
      config.apiKey,
      config.model,
      config.baseUrl,
    );
  default:
    throw new Error(`Unsupported AI provider: ${config.provider}`);
  }
}
