import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/generated_programme.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

/// Input constraints for the rule-based programme builder.
class ProgrammeBuilderInput {
  final int daysPerWeek;
  final int sessionLengthMinutes;
  final String goal; // get_stronger | build_muscle | lose_fat | general_fitness
  final List<String> blockedDays; // e.g. ['saturday', 'sunday']
  final String? equipment; // full_gym | home | bodyweight
  final List<Exercise> exerciseLibrary;
  /// Optional; adjusts sets/reps for rule-based fallback (not sent to the LLM).
  final UserScorecard? userScorecard;

  const ProgrammeBuilderInput({
    required this.daysPerWeek,
    required this.sessionLengthMinutes,
    this.goal = 'general_fitness',
    this.blockedDays = const [],
    this.equipment,
    required this.exerciseLibrary,
    this.userScorecard,
  });
}

const List<String> _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Deterministic programme generator. Used when LLM is unavailable or returns invalid output.
class ProgrammeBuilder {
  /// Builds a programme from constraints and exercise library.
  /// Ensures movement pattern balance (push, pull, squat, hinge) and respects equipment/safety.
  static GeneratedProgramme build(ProgrammeBuilderInput input) {
    final days = _chooseWorkoutDays(input.daysPerWeek, input.blockedDays);
    final filtered = _filterExercises(input.exerciseLibrary, input.equipment);
    final (sets, reps, restSeconds) =
        _prescriptionForGoal(input.goal, input.userScorecard);
    final workouts = <GeneratedProgrammeWorkout>[];

    for (var i = 0; i < days.length; i++) {
      final dayOfWeek = days[i];
      final exerciseCount = _exercisesPerSession(input.daysPerWeek, input.sessionLengthMinutes);
      final selected = _selectExercisesForDay(filtered, exerciseCount, dayIndex: i);
      workouts.add(GeneratedProgrammeWorkout(
        dayOfWeek: dayOfWeek,
        workoutName: _workoutNameForDay(i + 1, input.daysPerWeek),
        briefDescription: 'This session covers the main movement patterns for balanced, full-body development.',
        exercises: selected
            .map((e) => GeneratedProgrammeExercise(
                  exerciseId: e.id,
                  sets: List.generate(
                    sets,
                    (_) => GeneratedProgrammeSet(reps: reps, targetLoadKg: 0),
                  ),
                  restSeconds: restSeconds,
                  coachingNote: 'Included in this session as part of a balanced programme.',
                ))
            .toList(),
      ));
    }

    return GeneratedProgramme(
      programmeName: 'Rule-built programme',
      programmeDescription:
          'A balanced programme built from your preferences. Personalisation will improve with AI when available.',
      durationWeeks: 4,
      workouts: workouts,
      deloadWeek: const GeneratedProgrammeDeload(
        when: 'week_4',
        guidance: 'Reduce load or volume by ~40% for recovery.',
      ),
      weeklyProgression: 'Add a small amount of weight or one extra rep when sets feel easy.',
    );
  }

  static List<String> _chooseWorkoutDays(int daysPerWeek, List<String> blocked) {
    final blockedSet = blocked.map((d) => d.toLowerCase()).toSet();
    final available = _weekdays.where((d) => !blockedSet.contains(d)).toList();
    if (available.length <= daysPerWeek) return available;
    // Spread across the week (e.g. 3 days from 5 available -> mon, wed, fri)
    final indices = <int>{};
    for (var i = 0; i < daysPerWeek; i++) {
      indices.add((i * available.length) ~/ daysPerWeek);
    }
    final sorted = indices.toList()..sort();
    return sorted.map((i) => available[i]).toList();
  }

  /// Exclude rehab-level exercises unless user has indicated need (rule-engine has no user context, so we exclude by default).
  /// Matches DECISIONS.md / ai-program-generation: reserve Chair Sit-to-Stand, Wall Push-Up etc. for explicit rehab/frailty signals.
  static bool _isRehabLevel(Exercise e) =>
      e.suitability.any((s) => s.toLowerCase() == 'rehab_safe');

  static List<Exercise> _filterExercises(List<Exercise> library, String? equipment) {
    var list = library
        .where((e) => e.safetyTier != SafetyTier.tier3 && !_isRehabLevel(e))
        .toList();
    if (equipment == null || equipment.isEmpty || equipment == 'full_gym') {
      return list;
    }
    final eq = equipment.toLowerCase();
    if (eq == 'bodyweight') {
      list = list
          .where((e) =>
              e.equipment == null ||
              e.equipment!.toLowerCase().contains('body') ||
              e.equipment!.toLowerCase() == 'none' ||
              e.equipment!.toLowerCase() == 'bodyweight')
          .toList();
    } else if (eq == 'home') {
      list = list
          .where((e) {
            final ex = e.equipment?.toLowerCase() ?? '';
            return ex.contains('dumbbell') ||
                ex.contains('band') ||
                ex.contains('body') ||
                ex.contains('kettlebell') ||
                ex == 'none' ||
                ex == 'bodyweight';
          })
          .toList();
    }
    return list;
  }

  static (int sets, int reps, int restSeconds) _prescriptionForGoal(
    String goal,
    UserScorecard? scorecard,
  ) {
    final (int baseSets, int baseReps, int baseRest) = switch (goal) {
      'get_stronger' => (4, 5, 180),
      'build_muscle' => (3, 10, 90),
      'lose_fat' => (3, 12, 60),
      _ => (3, 10, 90),
    };

    var sets = baseSets;
    var reps = baseReps;
    var rest = baseRest;
    final s = scorecard;
    if (s != null) {
      if (s.consistency < 4.0) {
        sets = (sets - 1).clamp(2, 12);
        reps = (reps + 2).clamp(5, 30);
        rest = (rest + 15).clamp(60, 300);
      } else if (s.consistency >= 7.0 && s.progression >= 6.0) {
        if (sets < 5 && goal != 'lose_fat') {
          sets += 1;
        }
        if (goal == 'get_stronger' && reps <= 6) {
          reps = (reps - 1).clamp(3, 12);
        }
      }
    }
    return (sets, reps, rest);
  }

  static int _exercisesPerSession(int daysPerWeek, int sessionMinutes) {
    if (sessionMinutes <= 30) return 4;
    if (sessionMinutes <= 45) return 5;
    return 6;
  }

  static List<Exercise> _selectExercisesForDay(
    List<Exercise> filtered,
    int count, {
    required int dayIndex,
  }) {
    final byPattern = <MovementPattern, List<Exercise>>{};
    for (final e in filtered) {
      if (e.movementPattern == null) continue;
      byPattern.putIfAbsent(e.movementPattern!, () => []).add(e);
    }
    const basePriority = [
      MovementPattern.squat,
      MovementPattern.hinge,
      MovementPattern.pushHorizontal,
      MovementPattern.pullHorizontal,
      MovementPattern.pushVertical,
      MovementPattern.pullVertical,
      MovementPattern.lunge,
      MovementPattern.carry,
      MovementPattern.rotation,
      MovementPattern.isolationUpper,
      MovementPattern.isolationLower,
      MovementPattern.cardio,
      MovementPattern.mobility,
      MovementPattern.core,
      MovementPattern.sport,
    ];
    // Rotate priority by day so each workout gets a different mix.
    final offset = dayIndex % basePriority.length;
    final priority = [
      ...basePriority.skip(offset),
      ...basePriority.take(offset),
    ];
    final selected = <Exercise>[];
    final usedIds = <String>{};
    final usedPatterns = <MovementPattern>{};

    // One exercise per pattern first; never pick multiple from same pattern until we've used all available patterns.
    for (final pattern in priority) {
      if (selected.length >= count) break;
      final candidates = byPattern[pattern] ?? [];
      for (final ex in candidates) {
        if (usedIds.contains(ex.id)) continue;
        selected.add(ex);
        usedIds.add(ex.id);
        usedPatterns.add(pattern);
        break; // at most one per pattern in this pass
      }
    }

    // If we still need more, prefer exercises from patterns we haven't used yet.
    if (selected.length < count) {
      final unusedPatterns = priority.where((p) => !usedPatterns.contains(p)).toList();
      for (final pattern in unusedPatterns) {
        if (selected.length >= count) break;
        final candidates = byPattern[pattern] ?? [];
        for (final ex in candidates) {
          if (usedIds.contains(ex.id)) continue;
          selected.add(ex);
          usedIds.add(ex.id);
          usedPatterns.add(pattern);
          break;
        }
      }
    }

    // Only if we still need more (e.g. very small library) allow a second from a pattern — prefer patterns we've used least.
    if (selected.length < count) {
      final byPatternCount = <MovementPattern, int>{};
      for (final ex in selected) {
        if (ex.movementPattern != null) {
          byPatternCount[ex.movementPattern!] = (byPatternCount[ex.movementPattern!] ?? 0) + 1;
        }
      }
      final remaining = filtered.where((e) => !usedIds.contains(e.id)).toList();
      remaining.sort((a, b) {
        final aCount = a.movementPattern != null ? (byPatternCount[a.movementPattern!] ?? 0) : 0;
        final bCount = b.movementPattern != null ? (byPatternCount[b.movementPattern!] ?? 0) : 0;
        return aCount.compareTo(bCount); // prefer pattern we've used least
      });
      for (final e in remaining) {
        if (selected.length >= count) break;
        selected.add(e);
        usedIds.add(e.id);
      }
    }

    return selected.take(count).toList();
  }

  static String _workoutNameForDay(int dayIndex, int daysPerWeek) {
    if (daysPerWeek == 2) return dayIndex == 1 ? 'Full body A' : 'Full body B';
    if (daysPerWeek == 3) return 'Full body ${String.fromCharCode(64 + dayIndex)}';
    if (daysPerWeek == 4) {
      return dayIndex <= 2 ? 'Upper ${dayIndex == 1 ? "A" : "B"}' : 'Lower ${dayIndex == 3 ? "A" : "B"}';
    }
    return 'Workout $dayIndex';
  }
}
