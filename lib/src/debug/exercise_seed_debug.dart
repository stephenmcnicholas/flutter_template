import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fytter/src/data/exercise_seed_version.dart';

/// Debug helpers for exercise DB seeding (no-ops in release).
class ExerciseSeedDebug {
  ExerciseSeedDebug._();

  /// Sets a flag so the next `AppDatabase.seedInitialData` run performs a full
  /// exercise upsert from `assets/exercises/exercises.json` (same as hash mismatch).
  ///
  /// Cleared automatically after that run. Only works when [kDebugMode] is true.
  static Future<void> requestForceReseedOnNextLaunch() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kDebugForceReseedExercisesKey, true);
  }
}
