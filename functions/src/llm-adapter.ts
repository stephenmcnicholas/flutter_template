/**
 * LLM adapter: calls Vertex AI (Gemini) with ADC. No API key in code.
 * Requires GCP project with Vertex AI API enabled and billing (see docs/MANUAL_SETUP_VERTEX_AI.md).
 *
 * Model selection (we want cheapest effective, not frontier/Pro):
 * - Set VERTEX_AI_MODEL to pin a model (e.g. gemini-2.5-flash or gemini-2.5-flash-lite for lower cost).
 * - Otherwise uses a default with fallback chain on 404 (deprecation/unavailable).
 * - Set VERTEX_AI_MODEL_AUTO=1 to resolve at runtime via the list-models API: picks the cheapest
 *   effective option (Flash-Lite if available, else Flash). Result is cached per process so the list
 *   API is only called once per cold start, not on every request.
 */

import { VertexAI } from "@google-cloud/vertexai";

const LOCATION = process.env.VERTEX_AI_LOCATION ?? "us-central1";

/** Default model; Flash tier is the cost-effective option for structured JSON generation. */
const DEFAULT_MODEL = "gemini-2.5-flash";

/** Fallback chain when the chosen model returns 404 (e.g. deprecated or not available in project). */
const MODEL_FALLBACK_CHAIN = [
  "gemini-2.5-flash",
  "gemini-2.5-flash-preview-05-20",
  "gemini-2.5-flash-lite",
  "gemini-2.0-flash-001",
];

/** Cached model ID when using VERTEX_AI_MODEL_AUTO; avoids list API on every request. */
let cachedAutoModelId: string | null = null;

async function resolveModelId(projectId: string): Promise<string> {
  const explicit = process.env.VERTEX_AI_MODEL;
  if (explicit?.trim()) return explicit.trim();

  if (process.env.VERTEX_AI_MODEL_AUTO === "1") {
    if (cachedAutoModelId) return cachedAutoModelId;
    const fromList = await pickModelFromList(projectId);
    if (fromList) {
      cachedAutoModelId = fromList;
      return fromList;
    }
  }

  return DEFAULT_MODEL;
}

/**
 * Call Vertex AI list publisher models and pick the cheapest effective Flash-style model:
 * prefer Flash-Lite (lowest cost), then Flash. We don't need Pro/frontier for programme generation.
 * See https://cloud.google.com/vertex-ai/docs/reference/rest/v1beta1/publishers.models/list
 */
async function pickModelFromList(projectId: string): Promise<string | null> {
  try {
    const { GoogleAuth } = await import("google-auth-library");
    const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });
    const client = await auth.getClient();
    const token = await client.getAccessToken();
    if (!token.token) return null;

    const baseUrl = `https://${LOCATION}-aiplatform.googleapis.com`;
    const url = `${baseUrl}/v1beta1/publishers/google/models?pageSize=50`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${token.token}` },
    });
    if (!res.ok) return null;

    const data = (await res.json()) as {
      publisherModels?: Array<{ name?: string; displayName?: string; deprecated?: boolean }>;
    };
    const models = data.publisherModels ?? [];
    const flashOrLite = models
      .filter(
        (m) =>
          m.name &&
          m.name.includes("gemini") &&
          (m.name.includes("flash") || m.name.toLowerCase().includes("flash")) &&
          !m.deprecated
      )
      .map((m) => ({
        id: m.name!.includes("/") ? m.name!.split("/").pop()! : m.name!,
        isLite: m.name!.toLowerCase().includes("lite"),
      }))
      .filter((m) => m.id);
    // Prefer Flash-Lite (cheapest), then Flash.
    const lite = flashOrLite.find((m) => m.isLite);
    const flash = flashOrLite.find((m) => !m.isLite);
    return (lite ?? flash)?.id ?? null;
  } catch {
    return null;
  }
}

/**
 * Calls the LLM with system and user prompts. Returns the raw text response.
 * Uses Application Default Credentials (ADC) when running on GCP or with gcloud auth.
 * On 404 (model not found), tries the next model in the fallback chain.
 */
export async function callLLM(
  projectId: string,
  systemPrompt: string,
  userPrompt: string
): Promise<string> {
  const modelId = await resolveModelId(projectId);
  const chain = process.env.VERTEX_AI_MODEL
    ? [modelId]
    : [modelId, ...MODEL_FALLBACK_CHAIN.filter((m) => m !== modelId)];

  let lastErr: Error | null = null;
  for (const model of chain) {
    const vertex = new VertexAI({ project: projectId, location: LOCATION });
    const generativeModel = vertex.getGenerativeModel({
      model,
      generationConfig: {
        maxOutputTokens: 8192,
        temperature: 0.4,
        responseMimeType: "application/json",
      },
      systemInstruction: {
        role: "system",
        parts: [{ text: systemPrompt }],
      },
    });

    let result;
    try {
      result = await generativeModel.generateContent({
        contents: [{ role: "user", parts: [{ text: userPrompt }] }],
      });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      const is404 = msg.includes("404") || msg.includes("NOT_FOUND");
      if (is404 && chain.length > 1) {
        lastErr = err instanceof Error ? err : new Error(msg);
        continue;
      }
      const extra =
        err && typeof err === "object" && "status" in err
          ? ` (status: ${(err as { status?: number }).status})`
          : "";
      throw new Error(`Vertex AI request failed: ${msg}${extra}`);
    }

    const response = result.response;
    if (!response?.candidates?.length) {
      const blockReason =
        response?.candidates?.[0]?.finishReason ?? response?.promptFeedback?.blockReason ?? "unknown";
      throw new Error(`LLM returned no candidates (finishReason/blockReason: ${blockReason})`);
    }
    const part = response.candidates[0].content?.parts?.[0];
    if (!part?.text) {
      throw new Error("LLM response had no text");
    }
    return part.text;
  }

  throw lastErr ?? new Error("Vertex AI: no model in fallback chain succeeded");
}
