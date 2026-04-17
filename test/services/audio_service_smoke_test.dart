import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/audio/audio_clip_paths.dart';
import 'package:fytter/src/services/audio/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('playPath null is a no-op', () async {
    final paths = AudioClipPaths(assetBundle: rootBundle);
    final svc = AudioService(
      clipPaths: paths,
      getWorkoutIntroPath: (_) async => null,
    );
    await svc.playPath(null);
    svc.dispose();
  });
}
