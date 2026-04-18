import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Global switch for haptics. Defaults to enabled.
///
/// In a concrete app, wire this to a user settings provider.
final hapticsEnabledProvider = Provider<bool>((ref) => true);

/// Provides a [HapticsService] gated by the global haptics setting.
final hapticsServiceProvider = Provider<HapticsService>((ref) {
  final enabled = ref.watch(hapticsEnabledProvider);
  return SystemHapticsService(enabled: enabled);
});
