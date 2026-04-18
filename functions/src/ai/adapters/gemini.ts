import { VertexAI } from '@google-cloud/vertexai';
import { LLMAdapter, GenerateTextOptions, AnalyzeImageOptions, LLMResult } from '../adapter';

export class GeminiAdapter implements LLMAdapter {
  private model: string;
  private projectId: string;

  constructor(model: string, projectId: string) {
    this.model = model;
    this.projectId = projectId;
  }

  async generateText(options: GenerateTextOptions): Promise<LLMResult> {
    const vertexAI = new VertexAI({ project: this.projectId, location: 'us-central1' });
    const generativeModel = vertexAI.getGenerativeModel({ model: this.model });
    const result = await generativeModel.generateContent({
      systemInstruction: { role: 'system', parts: [{ text: options.systemPrompt }] },
      contents: [{ role: 'user', parts: [{ text: options.userPrompt }] }],
    });
    const content = result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    return { content, vendor: 'gemini', model: this.model };
  }

  async analyzeImage(options: AnalyzeImageOptions): Promise<LLMResult> {
    const vertexAI = new VertexAI({ project: this.projectId, location: 'us-central1' });
    const generativeModel = vertexAI.getGenerativeModel({ model: this.model });
    const result = await generativeModel.generateContent({
      contents: [{
        role: 'user',
        parts: [
          { inlineData: { data: options.imageBase64, mimeType: options.mimeType } },
          { text: options.prompt },
        ],
      }],
    });
    const content = result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    return { content, vendor: 'gemini', model: this.model };
  }
}
