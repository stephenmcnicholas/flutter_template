import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';

/// Abstracts haptic delivery so the service can be replaced in tests.
abstract class HapticsService {
  void light();
  void medium();
  void heavy();
}

/// Production implementation: fires platform haptics when [enabled].
class SystemHapticsService implements HapticsService {
  final bool enabled;
  const SystemHapticsService({required this.enabled});

  @override
  void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  @override
  void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  @override
  void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}

/// Provides a [HapticsService] gated by the global haptics setting.
final hapticsServiceProvider = Provider<HapticsService>((ref) {
  final settings = ref.watch(restTimerSettingsProvider);
  return SystemHapticsService(enabled: settings.hapticsEnabled);
});
