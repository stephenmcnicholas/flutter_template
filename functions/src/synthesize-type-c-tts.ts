/**
 * Callable: synthesizeTypeCTts — Gemini Pro TTS for Type C (programme description + workout intros).
 * Uses Google AI Gemini API (API key), not Vertex — see docs/MANUAL_SETUP_TYPE_C_TTS.md.
 */

import * as functions from "firebase-functions";
import { TTS_MODEL, TTS_STYLE_PROMPT, TTS_VOICE } from "./tts-config";

export interface SynthesizeTypeCTtsResult {
  audioBase64: string;
  mimeType: string;
}

function getGeminiApiKey(): string | undefined {
  return process.env.GEMINI_API_KEY ?? functions.config().gemini?.api_key;
}

/** Best-effort parse of Generative Language API error JSON for callable messages. */
function extractGeminiErrorMessage(raw: string): string | undefined {
  try {
    const j = JSON.parse(raw) as { error?: { message?: string; status?: string } };
    const m = j.error?.message;
    if (typeof m === "string" && m.length > 0) {
      return m.length > 400 ? `${m.slice(0, 400)}…` : m;
    }
  } catch {
    // ignore
  }
  return undefined;
}

export const synthesizeTypeCTts = functions
  .runWith({
    timeoutSeconds: 120,
    memory: "512MB",
  })
  .region("us-central1")
  .https.onCall(async (payload: unknown, context): Promise<SynthesizeTypeCTtsResult> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    }

    const text =
      typeof (payload as { text?: unknown })?.text === "string"
        ? (payload as { text: string }).text.trim()
        : "";
    if (!text.length) {
      throw new functions.https.HttpsError("invalid-argument", "text is required");
    }
    if (text.length > 12000) {
      throw new functions.https.HttpsError("invalid-argument", "text exceeds maximum length");
    }

    const apiKey = getGeminiApiKey();
    if (!apiKey) {
      functions.logger.error("synthesizeTypeCTts: GEMINI_API_KEY / gemini.api_key not set");
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Type C TTS is not configured on the server"
      );
    }

    const fullPrompt = `${TTS_STYLE_PROMPT}\n\n${text}`;

    const body = {
      contents: [{ parts: [{ text: fullPrompt }] }],
      generationConfig: {
        responseModalities: ["AUDIO"],
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: { voiceName: TTS_VOICE },
          },
        },
      },
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${TTS_MODEL}:generateContent?key=${encodeURIComponent(apiKey)}`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const rawText = await res.text();
    if (!res.ok) {
      functions.logger.error("Gemini TTS HTTP error", {
        status: res.status,
        body: rawText.slice(0, 2000),
      });
      const snippet = extractGeminiErrorMessage(rawText) ?? rawText.slice(0, 280);
      // Map common HTTP statuses so the client is not always opaque `internal`.
      if (res.status === 400 || res.status === 404) {
        throw new functions.https.HttpsError("invalid-argument", `Gemini TTS: ${snippet}`);
      }
      if (res.status === 401 || res.status === 403) {
        throw new functions.https.HttpsError("permission-denied", `Gemini TTS: ${snippet}`);
      }
      if (res.status === 429) {
        throw new functions.https.HttpsError("resource-exhausted", `Gemini TTS: ${snippet}`);
      }
      throw new functions.https.HttpsError("internal", `Gemini TTS (${res.status}): ${snippet}`);
    }

    let json: {
      candidates?: Array<{
        content?: { parts?: Array<{ inlineData?: { data?: string; mimeType?: string } }> };
      }>;
    };
    try {
      json = JSON.parse(rawText) as typeof json;
    } catch {
      functions.logger.error("Gemini TTS invalid JSON", rawText.slice(0, 400));
      throw new functions.https.HttpsError("internal", "Invalid TTS response");
    }

    const part = json.candidates?.[0]?.content?.parts?.[0] as Record<string, unknown> | undefined;
    const inline = (part?.inlineData ?? part?.inline_data) as
      | { data?: string; mimeType?: string; mime_type?: string }
      | undefined;
    const audioB64 = inline?.data;
    if (!audioB64) {
      functions.logger.error("Gemini TTS no inline audio", rawText.slice(0, 1200));
      throw new functions.https.HttpsError("internal", "No audio in TTS response");
    }

    const mimeType = inline?.mimeType ?? inline?.mime_type ?? "audio/L16";

    return {
      audioBase64: audioB64,
      mimeType,
    };
  });
