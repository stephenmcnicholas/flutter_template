import Anthropic from '@anthropic-ai/sdk';
import { LLMAdapter, GenerateTextOptions, AnalyzeImageOptions, LLMResult } from '../adapter';

export class ClaudeAdapter implements LLMAdapter {
  private client: Anthropic;
  private model: string;

  constructor(apiKey: string, model: string) {
    this.client = new Anthropic({ apiKey });
    this.model = model;
  }

  async generateText(options: GenerateTextOptions): Promise<LLMResult> {
    const response = await this.client.messages.create({
      model: this.model,
      max_tokens: options.maxTokens ?? 1024,
      system: options.systemPrompt,
      messages: [{ role: 'user', content: options.userPrompt }],
    });
    const content = response.content[0].type === 'text' ? response.content[0].text : '';
    return { content, vendor: 'claude', model: this.model };
  }

  async analyzeImage(options: AnalyzeImageOptions): Promise<LLMResult> {
    const response = await this.client.messages.create({
      model: this.model,
      max_tokens: options.maxTokens ?? 1024,
      messages: [{
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: options.mimeType,
              data: options.imageBase64,
            },
          },
          { type: 'text', text: options.prompt },
        ],
      }],
    });
    const content = response.content[0].type === 'text' ? response.content[0].text : '';
    return { content, vendor: 'claude', model: this.model };
  }
}
