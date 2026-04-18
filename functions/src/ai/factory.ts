import { LLMAdapter } from './adapter';
import { ClaudeAdapter } from './adapters/claude';
import { GeminiAdapter } from './adapters/gemini';
import { getAIConfig } from './config';

export function createAdapter(): LLMAdapter {
  const config = getAIConfig();
  switch (config.vendor) {
    case 'claude':
      if (!config.apiKey) throw new Error('AI_API_KEY required for Claude');
      return new ClaudeAdapter(config.apiKey, config.model);
    case 'gemini':
      if (!config.projectId) throw new Error('GOOGLE_CLOUD_PROJECT required for Gemini');
      return new GeminiAdapter(config.model, config.projectId);
    default:
      throw new Error(`Unsupported AI vendor: ${(config as { vendor: string }).vendor}`);
  }
}
