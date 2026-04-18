export interface GenerateTextOptions {
  systemPrompt: string;
  userPrompt: string;
  maxTokens?: number;
  temperature?: number;
  jsonMode?: boolean;
}

export interface AnalyzeImageOptions {
  imageBase64: string;
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp';
  prompt: string;
  maxTokens?: number;
}

export interface LLMResult {
  content: string;
  vendor: string;
  model: string;
}

export interface LLMAdapter {
  generateText(options: GenerateTextOptions): Promise<LLMResult>;
  analyzeImage(options: AnalyzeImageOptions): Promise<LLMResult>;
}
