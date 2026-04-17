import 'package:fytter/src/services/audio/audio_assembly_service.dart';
import 'package:fytter/src/services/audio/audio_coaching_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inter-clip silence matches assembly service', () {
    expect(AudioAssemblyService.silenceMs, kCoachingInterClipSilenceMs);
    expect(kCoachingInterClipSilenceMs, 175);
  });
}
