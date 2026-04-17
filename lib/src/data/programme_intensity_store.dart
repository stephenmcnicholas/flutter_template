import 'package:fytter/src/domain/session_check_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-programme load scaling from mid-programme check-ins (Block 3).
/// Applied at pre-workout via [WorkoutAdjuster] when [programId] is set on args.
class ProgrammeIntensityStore {
  ProgrammeIntensityStore._();

  static String _scaleKey(String programId) => 'prog_load_scale_v1_$programId';

  /// Default 1.0 when unset or [programId] is null.
  static Future<double> loadScaleForProgram(String? programId) async {
    if (programId == null || programId.isEmpty) return 1.0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_scaleKey(programId)) ?? 1.0;
  }

  static Future<void> setLoadScaleForProgram(String programId, double scale) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = scale.clamp(0.75, 1.25);
    await prefs.setDouble(_scaleKey(programId), clamped);
  }

  /// Maps mid-programme rating to a new load scale (merged with existing in [applyMidProgrammeRating]).
  static double targetScaleForMidRating(CheckInRating rating) {
    switch (rating) {
      case CheckInRating.tooEasy:
        return 1.05;
      case CheckInRating.tooHard:
        return 0.92;
      case CheckInRating.aboutRight:
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// Sets load scale from the latest mid-programme check-in (replaces previous).
  static Future<void> applyMidProgrammeRating(String programId, CheckInRating rating) async {
    await setLoadScaleForProgram(programId, targetScaleForMidRating(rating));
  }
}
