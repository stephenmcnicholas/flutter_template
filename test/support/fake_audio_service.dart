import 'package:fytter/src/services/audio/audio_service.dart';

/// Test double for [AudioServiceInterface].
/// Records each [playSequence] call so tests can assert which specs were dispatched
/// without touching [just_audio] or real device audio hardware.
class FakeAudioService implements AudioServiceInterface {
  /// Ordered list of spec-lists passed to [playSequence].
  /// Index 0 is the first call, index 1 the second, etc.
  final List<List<AudioClipSpec>> dispatched = [];

  /// Set to true after [startBackgroundSession] is called.
  bool sessionStarted = false;

  /// Set to true after [stopBackgroundSession] is called.
  bool sessionStopped = false;

  void reset() {
    dispatched.clear();
    sessionStarted = false;
    sessionStopped = false;
  }

  @override
  Future<void> startBackgroundSession() async => sessionStarted = true;

  @override
  Future<void> stopBackgroundSession() async => sessionStopped = true;

  @override
  Future<void> playSequence(List<AudioClipSpec> specs) async {
    dispatched.add(List.unmodifiable(specs));
  }

  @override
  Future<void> playPath(String? path) async {}

  @override
  Future<void> playModular(String category, String clipId) async {}

  @override
  Future<void> playExercise(String exerciseId, String cueType) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancelSequenceAndPause() async {}

  @override
  void dispose() {}
}
