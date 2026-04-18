export type AIVendor = 'claude' | 'gemini';

export interface AIConfig {
  vendor: AIVendor;
  model: string;
  apiKey: string;
  projectId?: string;
}

const DEFAULT_MODELS: Record<AIVendor, string> = {
  claude: 'claude-sonnet-4-6',
  gemini: 'gemini-2.5-flash',
};

export function getAIConfig(): AIConfig {
  const vendor = (process.env.AI_VENDOR as AIVendor) ?? 'claude';
  return {
    vendor,
    model: process.env.AI_MODEL ?? DEFAULT_MODELS[vendor],
    apiKey: process.env.AI_API_KEY ?? '',
    projectId: process.env.GOOGLE_CLOUD_PROJECT,
  };
}
