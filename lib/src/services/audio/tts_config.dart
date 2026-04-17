/// Locked voice configuration for all TTS-generated audio (Type A, B, and C).
/// Use these parameters in every TTS API call, including batch generation.
class TtsConfig {
  TtsConfig._();

  /// Model: pin for product parity with batch tooling. Runtime Type C calls use
  /// `gemini-2.5-pro-preview-tts` on the Gemini API (see `functions/src/tts-config.ts`).
  static const String model = 'gemini-2.5-pro-tts';

  /// Voice name for Gemini Pro TTS.
  static const String voice = 'Erinome';

  /// Language code.
  static const String language = 'en-GB';

  /// Include this prompt in every TTS API call.
  static const String prompt =
      'Speak as an encouraging female British personal trainer. '
      'Use a natural, mild British accent. Warm and friendly. Clear and confident.';
}
