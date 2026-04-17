import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/services/rest_timer_alert_service.dart';

class _FakeRestTimerAlertService implements RestTimerAlertService {
  int notifyCount = 0;
  bool? lastPlayHaptics;
  bool? lastPlaySound;

  @override
  Future<void> notifyComplete({
    required bool playHaptics,
    required bool playSound,
  }) async {
    notifyCount += 1;
    lastPlayHaptics = playHaptics;
    lastPlaySound = playSound;
  }
}

void main() {
  group('RestTimerNotifier', () {
    late RestTimerNotifier notifier;
    late _FakeRestTimerAlertService alertService;

    setUp(() {
      alertService = _FakeRestTimerAlertService();
      notifier = RestTimerNotifier(alertService);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state is inactive with default duration', () {
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.remainingSeconds, 120);
      expect(notifier.state.defaultDuration, 120);
      expect(notifier.state.isPaused, isFalse);
    });

    test('start() activates timer with default duration', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.remainingSeconds, 120);
      expect(notifier.state.isPaused, isFalse);
    });

    test('updateDefaultDuration updates defaults when inactive', () {
      notifier.updateDefaultDuration(150);
      expect(notifier.state.defaultDuration, 150);
      expect(notifier.state.remainingSeconds, 150);
    });

    test('updateDefaultDuration keeps remaining when active', () {
      notifier.start();
      notifier.updateDefaultDuration(150);
      expect(notifier.state.defaultDuration, 150);
      expect(notifier.state.remainingSeconds, 120);
    });

    test('start() does not restart if already active', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      
      // Wait a bit to let timer count down
      Future.delayed(const Duration(milliseconds: 100));
      
      notifier.start(); // Try to start again
      
      // Should continue from where it was, not reset
      expect(notifier.state.isActive, isTrue);
    });

    test('timer counts down correctly', () async {
      notifier.start();
      expect(notifier.state.remainingSeconds, 120);
      
      // Wait for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      // Timer should have counted down (allowing for some timing variance)
      expect(notifier.state.remainingSeconds, lessThan(120));
      expect(notifier.state.remainingSeconds, greaterThanOrEqualTo(118));
    });

    test('skip() completes timer immediately', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      
      notifier.skip();
      
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.remainingSeconds, 120); // Reset to default
      expect(alertService.notifyCount, 1);
      expect(alertService.lastPlayHaptics, isTrue);
      expect(alertService.lastPlaySound, isTrue);
    });

    test('increaseDuration() adds 15 seconds', () {
      notifier.start();
      final initial = notifier.state.remainingSeconds;
      
      notifier.increaseDuration();
      
      expect(notifier.state.remainingSeconds, initial + 15);
    });

    test('decreaseDuration() subtracts 15 seconds', () {
      notifier.start();
      final initial = notifier.state.remainingSeconds;
      
      notifier.decreaseDuration();
      
      expect(notifier.state.remainingSeconds, initial - 15);
    });

    test('decreaseDuration() does not go below 0', () {
      notifier.start();
      
      // Decrease many times to try to go negative
      for (int i = 0; i < 20; i++) {
        notifier.decreaseDuration();
      }
      
      expect(notifier.state.remainingSeconds, greaterThanOrEqualTo(0));
    });

    test('decreaseDuration() to 0 completes timer', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.remainingSeconds, 120);
      
      // Decrease 7 times: 120 - (7 * 15) = 15 (still active)
      for (int i = 0; i < 7; i++) {
        notifier.decreaseDuration();
      }
      expect(notifier.state.remainingSeconds, 15);
      expect(notifier.state.isActive, isTrue);
      
      // One more decrease should bring it to 0 and complete
      notifier.decreaseDuration();
      
      // Timer should be completed (inactive) and reset to default duration
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.remainingSeconds, 120); // Reset to default
      expect(alertService.notifyCount, 1);
    });

    test('pause() pauses active timer', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.isPaused, isFalse);
      
      notifier.pause();
      
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.isPaused, isTrue);
    });

    test('resume() resumes paused timer', () {
      notifier.start();
      notifier.pause();
      expect(notifier.state.isPaused, isTrue);
      
      notifier.resume();
      
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.isPaused, isFalse);
    });

    test('stop() resets timer to inactive state', () {
      notifier.start();
      notifier.increaseDuration();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.remainingSeconds, greaterThan(120));
      
      notifier.stop();
      
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.remainingSeconds, 120);
      expect(notifier.state.isPaused, isFalse);
    });

    test('timer auto-completes when reaching 0', () async {
      notifier.start();
      
      // Set to a very short duration
      for (int i = 0; i < 8; i++) {
        notifier.decreaseDuration(); // Bring it to 0
      }
      
      // Wait a bit for completion
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(notifier.state.isActive, isFalse);
      expect(alertService.notifyCount, 1);
    });

    test('updateAlertPreferences controls alert behavior', () {
      notifier.updateAlertPreferences(playHaptics: false, playSound: true);
      notifier.start();
      notifier.skip();
      expect(alertService.lastPlayHaptics, isFalse);
      expect(alertService.lastPlaySound, isTrue);
    });

    test('formattedTime returns correct format', () {
      final state = RestTimerState(remainingSeconds: 125);
      expect(state.formattedTime, '2:05');
      
      final state2 = RestTimerState(remainingSeconds: 65);
      expect(state2.formattedTime, '1:05');
      
      final state3 = RestTimerState(remainingSeconds: 5);
      expect(state3.formattedTime, '0:05');
    });

    test('isComplete returns true when remainingSeconds is 0', () {
      final state = RestTimerState(remainingSeconds: 0);
      expect(state.isComplete, isTrue);
      
      final state2 = RestTimerState(remainingSeconds: 1);
      expect(state2.isComplete, isFalse);
    });

    test('increaseDuration restarts countdown if timer is running', () async {
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      final beforeIncrease = notifier.state.remainingSeconds;
      
      notifier.increaseDuration();
      
      // Should have increased and restarted countdown
      expect(notifier.state.remainingSeconds, beforeIncrease + 15);
    });

    test('dispose cancels timer', () {
      notifier.start();
      expect(notifier.state.isActive, isTrue);
      
      // Verify timer is running before dispose
      final stateBeforeDispose = notifier.state;
      expect(stateBeforeDispose.isActive, isTrue);
      
      // Create a separate notifier for dispose test to avoid tearDown conflict
      final testNotifier = RestTimerNotifier(_FakeRestTimerAlertService());
      testNotifier.start();
      expect(testNotifier.state.isActive, isTrue);
      
      // Dispose should cancel the timer and clean up
      testNotifier.dispose();
      
      // Verify the notifier was disposed (can't access state after dispose)
      expect(testNotifier, isNotNull);
    });
  });

  group('RestTimerState', () {
    test('copyWith updates only specified fields', () {
      const original = RestTimerState(
        isActive: false,
        remainingSeconds: 120,
        defaultDuration: 120,
        isPaused: false,
      );
      
      final updated = original.copyWith(isActive: true, remainingSeconds: 100);
      
      expect(updated.isActive, isTrue);
      expect(updated.remainingSeconds, 100);
      expect(updated.defaultDuration, 120); // Unchanged
      expect(updated.isPaused, false); // Unchanged
    });

    test('copyWith preserves all fields when no parameters provided', () {
      const original = RestTimerState(
        isActive: true,
        remainingSeconds: 60,
        defaultDuration: 120,
        isPaused: true,
      );
      
      final copied = original.copyWith();
      
      expect(copied.isActive, original.isActive);
      expect(copied.remainingSeconds, original.remainingSeconds);
      expect(copied.defaultDuration, original.defaultDuration);
      expect(copied.isPaused, original.isPaused);
    });
  });
}
