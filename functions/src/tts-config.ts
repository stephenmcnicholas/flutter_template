/**
 * Must stay aligned with lib/src/services/audio/tts_config.dart (Type C / batch TTS policy).
 */
export const TTS_MODEL = "gemini-2.5-pro-preview-tts";

/** Prebuilt voice name for Gemini Pro TTS (see Gemini speech-generation voice list). */
export const TTS_VOICE = "Erinome";

export const TTS_STYLE_PROMPT =
  "Speak as an encouraging female British personal trainer. " +
  "Use a natural, mild British accent. Warm and friendly. Clear and confident. " +
  "Conversational and relaxed — natural pacing, not overly formal or precisely enunciated.";
