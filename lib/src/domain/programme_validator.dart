import 'package:flutter/foundation.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/generated_programme.dart';

/// Severity of a [ProgrammeViolation].
///
/// [hard] violations mean the programme is structurally unusable — callers
/// should discard it and fall back to the rule-based builder.
/// [soft] violations are warnings — the programme can be used but the
/// issue should be logged for monitoring.
enum ViolationSeverity { hard, soft }

/// Categories of violation the validator can detect.
enum ViolationType {
  /// Programme has no workouts — completely unusable.
  emptyWorkoutList,

  /// A workout contains no exercises.
  emptyExercisesInWorkout,

  /// An exercise ID is not present in the provided library.
  unknownExerciseId,

  /// sets list is empty — invalid prescription.
  invalidSets,

  /// reps <= 0 in a set — invalid prescription.
  invalidReps,

  /// A prescribed load is below the equipment-aware minimum (e.g. barbell below 20 kg).
  suspiciousLoad,

  /// An exercise with [SafetyTier.tier3] was prescribed; AI should never
  /// prescribe tier-3 exercises (logging-only).
  tier3ExerciseIncluded,

  /// Workout count doesn't match the requested [daysPerWeek].
  workoutCountMismatch,
}

/// A single issue detected during programme validation.
class ProgrammeViolation {
  final ViolationType type;
  final ViolationSeverity severity;
  final String message;

  const ProgrammeViolation({
    required this.type,
    required this.severity,
    required this.message,
  });

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] ${type.name}: $message';
}

/// Result returned by [ProgrammeValidator.validate].
///
/// [isValid] is `true` when there are no hard violations (the programme can
/// be used even if soft warnings were raised).
class ProgrammeValidationResult {
  final List<ProgrammeViolation> violations;

  const ProgrammeValidationResult({required this.violations});

  /// `true` when no hard violations were found.
  bool get isValid =>
      violations.every((v) => v.severity == ViolationSeverity.soft);

  List<ProgrammeViolation> get hardViolations =>
      violations.where((v) => v.severity == ViolationSeverity.hard).toList();

  List<ProgrammeViolation> get softViolations =>
      violations.where((v) => v.severity == ViolationSeverity.soft).toList();
}

/// Validates a [GeneratedProgramme] against structural and safety rules.
///
/// Pass [knownExerciseIds] (the IDs from the exercise library used for
/// generation) so the validator can flag any unknown IDs the LLM hallucinated.
///
/// Optionally pass [requestedDaysPerWeek] to detect workout-count mismatches,
/// and [exerciseById] to enable per-exercise safety-tier checks.
class ProgrammeValidator {
  const ProgrammeValidator();

  ProgrammeValidationResult validate(
    GeneratedProgramme programme, {
    required Set<String> knownExerciseIds,
    int? requestedDaysPerWeek,
    Map<String, Exercise>? exerciseById,
  }) {
    final violations = <ProgrammeViolation>[];

    // Hard: no workouts at all.
    if (programme.workouts.isEmpty) {
      violations.add(const ProgrammeViolation(
        type: ViolationType.emptyWorkoutList,
        severity: ViolationSeverity.hard,
        message: 'Programme contains no workouts.',
      ));
      return ProgrammeValidationResult(violations: violations);
    }

    for (final workout in programme.workouts) {
      // Hard: workout has no exercises.
      if (workout.exercises.isEmpty) {
        violations.add(ProgrammeViolation(
          type: ViolationType.emptyExercisesInWorkout,
          severity: ViolationSeverity.hard,
          message: 'Workout "${workout.workoutName}" has no exercises.',
        ));
        continue;
      }

      for (final ex in workout.exercises) {
        // Hard: exercise ID not in library (hallucinated ID).
        if (!knownExerciseIds.contains(ex.exerciseId)) {
          violations.add(ProgrammeViolation(
            type: ViolationType.unknownExerciseId,
            severity: ViolationSeverity.hard,
            message:
                'Exercise ID "${ex.exerciseId}" in "${workout.workoutName}" '
                'is not in the exercise library.',
          ));
        }

        // Hard: empty sets list.
        if (ex.sets.isEmpty) {
          violations.add(ProgrammeViolation(
            type: ViolationType.invalidSets,
            severity: ViolationSeverity.hard,
            message:
                'Exercise "${ex.exerciseId}" in "${workout.workoutName}" '
                'has an empty sets list — must have at least one set.',
          ));
        }

        // Hard: invalid reps in any set; Soft: suspicious load per set.
        final libEx = exerciseById?[ex.exerciseId];
        final eq = libEx?.equipment?.toLowerCase() ?? '';
        final isBarbell = eq.contains('barbell');
        final isKettlebell = eq.contains('kettlebell');
        final loadFloor = isBarbell ? 20.0 : isKettlebell ? 4.0 : 0.0;

        for (var si = 0; si < ex.sets.length; si++) {
          final s = ex.sets[si];
          if (s.reps <= 0) {
            violations.add(ProgrammeViolation(
              type: ViolationType.invalidReps,
              severity: ViolationSeverity.hard,
              message:
                  'Exercise "${ex.exerciseId}" in "${workout.workoutName}" '
                  'set $si has ${s.reps} reps — must be > 0.',
            ));
          }
          if (loadFloor > 0 && s.targetLoadKg != null && s.targetLoadKg! > 0 && s.targetLoadKg! < loadFloor) {
            violations.add(ProgrammeViolation(
              type: ViolationType.suspiciousLoad,
              severity: ViolationSeverity.soft,
              message:
                  'Exercise "${ex.exerciseId}" in "${workout.workoutName}" '
                  'set $si has targetLoadKg=${s.targetLoadKg} kg which is below '
                  'the equipment minimum of $loadFloor kg ($eq). '
                  'Client will clamp to $loadFloor kg.',
            ));
          }
        }

        // Soft: tier-3 exercise prescribed.
        if (libEx != null && libEx.safetyTier == SafetyTier.tier3) {
          violations.add(ProgrammeViolation(
            type: ViolationType.tier3ExerciseIncluded,
            severity: ViolationSeverity.soft,
            message:
                '"${libEx.name}" (${ex.exerciseId}) is SafetyTier.tier3 '
                'and should not be prescribed by AI.',
          ));
        }
      }
    }

    // Soft: workout count doesn't match requested daysPerWeek.
    if (requestedDaysPerWeek != null &&
        programme.workouts.length != requestedDaysPerWeek) {
      violations.add(ProgrammeViolation(
        type: ViolationType.workoutCountMismatch,
        severity: ViolationSeverity.soft,
        message:
            'Expected $requestedDaysPerWeek workouts but programme has '
            '${programme.workouts.length}.',
      ));
    }

    return ProgrammeValidationResult(violations: violations);
  }
}

/// Logs validation results using [debugPrint].
void logValidationResult(ProgrammeValidationResult result) {
  if (result.violations.isEmpty) {
    debugPrint('[ProgrammeValidator] OK — no violations.');
    return;
  }
  for (final v in result.violations) {
    debugPrint('[ProgrammeValidator] $v');
  }
}
