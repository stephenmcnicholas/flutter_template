import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/utils/set_outcome_utils.dart';

/// Deterministic handling after a set is logged as [SetOutcomeValues.failed].
class FailedSetAdjuster {
  FailedSetAdjuster._();

  static const double remainingLoadFactor = 0.9;

  /// Same rounding as [WorkoutAdjuster].
  static double roundLoad(double v) => (v * 10).round() / 10;

  /// Scales weight on incomplete sets with index greater than [afterSetIndex].
  static List<Map<String, dynamic>> applyLoadReductionToRemaining({
    required List<Map<String, dynamic>> sets,
    required int afterSetIndex,
    double factor = remainingLoadFactor,
  }) {
    final out = sets.map((m) => Map<String, dynamic>.from(m)).toList();
    for (var j = afterSetIndex + 1; j < out.length; j++) {
      if (out[j]['isComplete'] == true) continue;
      final w = out[j]['weight'];
      if (w is num && w > 0) {
        out[j]['weight'] = roundLoad(w.toDouble() * factor);
      }
    }
    return out;
  }

  /// Counts consecutive [SetOutcomeValues.failed] from the newest logged entry
  /// (by [WorkoutEntry.timestamp]). Stops at first non-failure (completed, null, skipped).
  static int consecutiveFailedStreakFromNewest(List<WorkoutEntry> entries) {
    final dated = entries.where((e) => e.timestamp != null).toList()
      ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    var n = 0;
    for (final e in dated) {
      if (e.setOutcome == SetOutcomeValues.failed) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }
}
