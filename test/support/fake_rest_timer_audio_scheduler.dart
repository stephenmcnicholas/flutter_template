import 'package:fytter/src/services/audio/rest_timer_audio_scheduler.dart';

/// Test double for [RestTimerAudioSchedulerBase].
/// Records each [scheduleWhenRestStarts] call so tests can assert on the
/// [RestTimerAudioContext] without touching file I/O or OS notifications.
class FakeRestTimerAudioScheduler extends RestTimerAudioSchedulerBase {
  /// Ordered list of contexts passed to [scheduleWhenRestStarts].
  final List<RestTimerAudioContext> calls = [];

  void reset() => calls.clear();

  @override
  void scheduleWhenRestStarts({
    required RestTimerAudioContext context,
    required DateTime restEndTime,
  }) {
    calls.add(context);
  }
}
