import { createAdapter } from '../factory';
import { ClaudeAdapter } from '../adapters/claude';
import { GeminiAdapter } from '../adapters/gemini';

describe('createAdapter', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('returns ClaudeAdapter when AI_VENDOR=claude', () => {
    process.env.AI_VENDOR = 'claude';
    process.env.AI_API_KEY = 'test-key';
    expect(createAdapter()).toBeInstanceOf(ClaudeAdapter);
  });

  it('defaults to Claude when AI_VENDOR is not set', () => {
    delete process.env.AI_VENDOR;
    process.env.AI_API_KEY = 'test-key';
    expect(createAdapter()).toBeInstanceOf(ClaudeAdapter);
  });

  it('returns GeminiAdapter when AI_VENDOR=gemini', () => {
    process.env.AI_VENDOR = 'gemini';
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    expect(createAdapter()).toBeInstanceOf(GeminiAdapter);
  });

  it('throws when Claude selected but AI_API_KEY is missing', () => {
    process.env.AI_VENDOR = 'claude';
    delete process.env.AI_API_KEY;
    expect(() => createAdapter()).toThrow('AI_API_KEY required for Claude');
  });

  it('throws when Gemini selected but GOOGLE_CLOUD_PROJECT is missing', () => {
    process.env.AI_VENDOR = 'gemini';
    delete process.env.GOOGLE_CLOUD_PROJECT;
    expect(() => createAdapter()).toThrow('GOOGLE_CLOUD_PROJECT required for Gemini');
  });
});
