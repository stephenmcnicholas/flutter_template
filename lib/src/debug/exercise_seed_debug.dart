import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug helpers for database seeding (no-ops in release).
class ExerciseSeedDebug {
  ExerciseSeedDebug._();

  static const String _kDebugForceReseedKey = 'debug_force_reseed';

  /// Sets a flag so the next database seed run performs a full upsert.
  /// Cleared automatically after that run. Only works when [kDebugMode] is true.
  static Future<void> requestForceReseedOnNextLaunch() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDebugForceReseedKey, true);
  }
}
