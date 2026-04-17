import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/utils/pcm_to_wav.dart';

void main() {
  test('pcm16leMonoToWav produces RIFF WAV with correct data chunk size', () {
    final pcm = Uint8List.fromList(List<int>.filled(200, 0));
    final wav = pcm16leMonoToWav(pcm, sampleRate: 24000);
    expect(wav.length, 44 + 200);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
  });

  test('geminiInlineAudioToWavBytes passes through wav mime', () {
    final fake = Uint8List.fromList([1, 2, 3]);
    final out = geminiInlineAudioToWavBytes(fake, mimeType: 'audio/wav');
    expect(out, fake);
  });
}
