import 'package:flutter/services.dart';

abstract class RestTimerAlertService {
  Future<void> notifyComplete({
    required bool playHaptics,
    required bool playSound,
  });
}

class SystemRestTimerAlertService implements RestTimerAlertService {
  @override
  Future<void> notifyComplete({
    required bool playHaptics,
    required bool playSound,
  }) async {
    // Haptic feedback + system alert sound
    if (playHaptics) {
      await HapticFeedback.mediumImpact();
    }
    if (playSound) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
