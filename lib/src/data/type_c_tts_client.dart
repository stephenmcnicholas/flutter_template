import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/pcm_to_wav.dart';

/// Client wait for [synthesizeTypeCTts]. Default [HttpsCallableOptions] is 60s, which
/// yields `deadline-exceeded` while the function (and Gemini TTS) may still run — see
/// `functions/src/synthesize-type-c-tts.ts` `timeoutSeconds: 120`.
const Duration _kSynthesizeTypeCTtsCallableTimeout = Duration(seconds: 120);

/// Calls Cloud Function [synthesizeTypeCTts] (Gemini Pro TTS). Server holds API key.
class TypeCTtsClient {
  TypeCTtsClient({FirebaseFunctions? functions}) : _functionsOverride = functions;

  /// Injected for tests; otherwise [FirebaseFunctions.instance] is read only when calling [synthesizeToWavBytes].
  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  /// Returns WAV bytes suitable for [File.writeAsBytes], or null on failure.
  Future<Uint8List?> synthesizeToWavBytes(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final callable = _functions.httpsCallable(
        'synthesizeTypeCTts',
        options: HttpsCallableOptions(timeout: _kSynthesizeTypeCTtsCallableTimeout),
      );
      final result = await callable.call<dynamic>({'text': trimmed});
      final data = result.data;
      if (data is! Map) return null;
      final b64 = data['audioBase64'];
      final mimeType = data['mimeType'];
      if (b64 is! String || b64.isEmpty) return null;
      final raw = Uint8List.fromList(base64Decode(b64));
      final mime = mimeType is String ? mimeType : 'audio/L16';
      return geminiInlineAudioToWavBytes(raw, mimeType: mime);
    } on FirebaseFunctionsException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[TypeCTtsClient] synthesizeToWavBytes failed: code=${e.code} '
          'message=${e.message} details=${e.details}\n$st',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TypeCTtsClient] synthesizeToWavBytes failed: $e\n$st');
      }
      return null;
    }
  }
}

final typeCTtsClientProvider = Provider<TypeCTtsClient>((ref) {
  return TypeCTtsClient();
});
