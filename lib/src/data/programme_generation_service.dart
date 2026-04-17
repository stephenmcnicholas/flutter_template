import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/generated_programme.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/domain/programme_validator.dart';
import 'package:fytter/src/domain/rule_engine/programme_builder.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_repository.dart';
import 'package:uuid/uuid.dart';

/// Input for programme generation (matches Cloud Function request shape).
class ProgrammeGenerationRequest {
  final int daysPerWeek;
  final int sessionLengthMinutes;
  final String goal;
  final List<String> blockedDays;
  final String? equipment;
  final int? age;
  final String? injuriesOrLimitations;
  final String? additionalContext;
  final String? scorecardNarrative;
  /// When set, [effectiveScorecardNarrative] uses [UserScorecard.toNarrative] unless [scorecardNarrative] is non-empty.
  final UserScorecard? userScorecard;
  final String? previousProgrammeSummary;
  final List<Exercise> exerciseLibrary;
  /// When the programme should start (e.g. next Monday). If null, service uses next Monday.
  final DateTime? startDate;
  /// Self-reported experience: "never" | "some" | "regular". If null, copy must not assume beginner.
  final String? experienceLevel;

  const ProgrammeGenerationRequest({
    required this.daysPerWeek,
    required this.sessionLengthMinutes,
    this.goal = 'general_fitness',
    this.blockedDays = const [],
    this.equipment,
    this.age,
    this.injuriesOrLimitations,
    this.additionalContext,
    this.scorecardNarrative,
    this.userScorecard,
    this.previousProgrammeSummary,
    required this.exerciseLibrary,
    this.startDate,
    this.experienceLevel,
  });

  /// Narrative sent to Cloud Functions: explicit string wins over [userScorecard].
  String? get effectiveScorecardNarrative =>
      (scorecardNarrative != null && scorecardNarrative!.trim().isNotEmpty)
          ? scorecardNarrative
          : userScorecard?.toNarrative();

  Map<String, dynamic> toCallablePayload() => {
        'daysPerWeek': daysPerWeek,
        'sessionLengthMinutes': sessionLengthMinutes,
        'goal': goal,
        'blockedDays': blockedDays,
        if (equipment != null) 'equipment': equipment,
        if (age != null) 'age': age,
        if (injuriesOrLimitations != null) 'injuriesOrLimitations': injuriesOrLimitations,
        if (additionalContext != null) 'additionalContext': additionalContext,
        if (effectiveScorecardNarrative != null)
          'scorecardNarrative': effectiveScorecardNarrative,
        if (previousProgrammeSummary != null) 'previousProgrammeSummary': previousProgrammeSummary,
        if (experienceLevel != null) 'experienceLevel': experienceLevel,
        'exerciseLibrary': exerciseLibrary
            .map((e) => {
                  'id': e.id,
                  'name': e.name,
                  if (e.movementPattern != null) 'movementPattern': movementPatternToStorage(e.movementPattern!),
                  'safetyTier': safetyTierToStorage(e.safetyTier),
                  if (e.equipment != null) 'equipment': e.equipment,
                  if (e.bodyPart != null) 'bodyPart': e.bodyPart,
                })
            .toList(),
      };
}

/// Thrown when the user has reached the monthly AI programme generation limit.
class ProgrammeGenerationLimitException implements Exception {
  const ProgrammeGenerationLimitException();
}

/// Result of programme generation (saved program or error).
class ProgrammeGenerationResult {
  final Program program;
  final bool usedFallback;
  final List<String> personalisationNotes;
  /// When [usedFallback] is true, optional reason the AI/LLM was not used (for debugging).
  final String? generationFailureReason;

  const ProgrammeGenerationResult({
    required this.program,
    required this.usedFallback,
    this.personalisationNotes = const [],
    this.generationFailureReason,
  });
}

/// Recursively converts Firebase callable result (Map<Object?, Object?>, etc.) to Map<String, dynamic>.
Map<String, dynamic>? _toMapStringDynamic(Object? value) {
  if (value == null) return null;
  if (value is! Map) return null;
  final result = <String, dynamic>{};
  for (final e in value.entries) {
    final k = e.key;
    if (k is! String) continue;
    final v = e.value;
    if (v is Map) {
      final nested = _toMapStringDynamic(v);
      if (nested != null) result[k] = nested;
    } else if (v is List) {
      result[k] = [
        for (final e in v)
          e is Map ? _toMapStringDynamic(e) ?? <String, dynamic>{} : e,
      ];
    } else {
      result[k] = v;
    }
  }
  return result;
}

/// Calls the Cloud Function (or rule builder), maps to domain models, and saves.
class ProgrammeGenerationService {
  ProgrammeGenerationService({
    required ProgramRepository programRepository,
    required WorkoutRepository workoutRepository,
  })  : _programRepository = programRepository,
        _workoutRepository = workoutRepository;

  final ProgramRepository _programRepository;
  final WorkoutRepository _workoutRepository;
  final _uuid = const Uuid();

  /// Generates a programme (LLM or fallback), saves it, and returns the saved program.
  Future<ProgrammeGenerationResult> generateAndSave(ProgrammeGenerationRequest request) async {
    GeneratedProgramme generated;
    bool usedFallback = false;
    String? failureReason;

    final payload = request.toCallablePayload();
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ProgrammeGeneration] Calling generateProgram (exerciseLibrary: ${(payload['exerciseLibrary'] as List).length} exercises)');
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateProgram');
      final result = await callable.call(payload);
      final data = result.data;
      if (data == null) {
        usedFallback = true;
        failureReason = 'Server returned no data';
        generated = _buildFallback(request);
      } else if (data['success'] == true && data['programme'] != null) {
        final programmeMap = _toMapStringDynamic(data['programme']);
        if (programmeMap != null) {
          generated = GeneratedProgramme.fromJson(programmeMap);
          usedFallback = data['source'] == 'fallback';
          if (usedFallback) {
            failureReason = 'Server used fallback (LLM unavailable)';
          } else {
            final validationResult = const ProgrammeValidator().validate(
              generated,
              knownExerciseIds: {for (final e in request.exerciseLibrary) e.id},
              requestedDaysPerWeek: request.daysPerWeek,
              exerciseById: {for (final e in request.exerciseLibrary) e.id: e},
            );
            if (!validationResult.isValid) {
              if (kDebugMode) {
                for (final v in validationResult.hardViolations) {
                  // ignore: avoid_print
                  print('[ProgrammeGeneration] Validation hard violation: $v');
                }
              }
              usedFallback = true;
              failureReason =
                  'LLM output failed validation (${validationResult.hardViolations.map((v) => v.type.name).join(", ")})';
              generated = _buildFallback(request);
            } else if (validationResult.softViolations.isNotEmpty &&
                kDebugMode) {
              for (final v in validationResult.softViolations) {
                // ignore: avoid_print
                print('[ProgrammeGeneration] Validation warning: $v');
              }
            }
          }
        } else {
          usedFallback = true;
          failureReason = 'Invalid programme data from server';
          generated = _buildFallback(request);
        }
      } else {
        usedFallback = true;
        failureReason = data['error']?.toString() ?? 'Server returned success: false or no programme';
        generated = _buildFallback(request);
      }
    } catch (e, st) {
      if (e is FirebaseFunctionsException &&
          e.code == 'resource-exhausted' &&
          e.message == 'generation_limit_reached') {
        throw const ProgrammeGenerationLimitException();
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ProgrammeGeneration] generateProgram failed: $e');
        // ignore: avoid_print
        print('[ProgrammeGeneration] $st');
      }
      usedFallback = true;
      failureReason = _formatFailureReason(e);
      generated = _buildFallback(request);
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('[ProgrammeGeneration] Result: ${usedFallback ? "fallback" : "LLM"}${failureReason != null ? " ($failureReason)" : ""}, saving program');
    }

    final startDate = request.startDate != null
        ? DateTime(request.startDate!.year, request.startDate!.month, request.startDate!.day)
        : null;
    final (program, workouts) = _mapToProgramAndWorkouts(
      generated,
      startDate,
      exerciseLibrary: request.exerciseLibrary,
    );
    for (final w in workouts) {
      await _workoutRepository.save(w);
    }
    await _programRepository.save(program);

    return ProgrammeGenerationResult(
      program: program,
      usedFallback: usedFallback,
      personalisationNotes: generated.personalisationNotes,
      generationFailureReason: failureReason,
    );
  }

  /// Format exception for display (avoid leaking stack traces; keep message short).
  static String _formatFailureReason(Object e) {
    if (e is FirebaseFunctionsException) {
      final code = e.code;
      final msg = e.message ?? '';
      if (code == 'unavailable') return 'Network or service unavailable';
      if (code == 'unauthenticated') return 'Not authenticated';
      if (code == 'permission-denied') return 'Permission denied';
      if (code == 'deadline-exceeded') return 'Request timed out';
      if (msg.isNotEmpty && msg.length < 120) return msg;
      return '$code: ${msg.length > 80 ? '${msg.substring(0, 80)}…' : msg}';
    }
    final s = e.toString();
    return s.length > 150 ? '${s.substring(0, 150)}…' : s;
  }

  GeneratedProgramme _buildFallback(ProgrammeGenerationRequest request) {
    final input = ProgrammeBuilderInput(
      daysPerWeek: request.daysPerWeek,
      sessionLengthMinutes: request.sessionLengthMinutes,
      goal: request.goal,
      blockedDays: request.blockedDays,
      equipment: request.equipment,
      exerciseLibrary: request.exerciseLibrary,
      userScorecard: request.userScorecard,
    );
    return ProgrammeBuilder.build(input);
  }

  (Program, List<Workout>) _mapToProgramAndWorkouts(
    GeneratedProgramme generated,
    DateTime? requestedStart, {
    List<Exercise> exerciseLibrary = const [],
  }) {
    final programId = _uuid.v4();
    final startDate = requestedStart ?? _nextMonday();
    final workouts = <Workout>[];
    final schedule = <ProgramWorkout>[];
    final durationWeeks = generated.durationWeeks.clamp(1, 52);
    final breakdowns = <Map<String, dynamic>>[];
    final exerciseById = {for (final e in exerciseLibrary) e.id: e};

    for (final w in generated.workouts) {
      final workoutId = _uuid.v4();
      final entries = w.exercises.expand((e) {
        final exercise = exerciseById[e.exerciseId];
        return e.sets.map((s) => WorkoutEntry(
              id: _uuid.v4(),
              exerciseId: e.exerciseId,
              reps: s.reps,
              weight: _clampLoad(s.targetLoadKg ?? 0, exercise),
              isComplete: false,
            ));
      }).toList();
      workouts.add(Workout(id: workoutId, name: w.workoutName, entries: entries));
      breakdowns.add({
        'workoutId': workoutId,
        'workoutName': w.workoutName,
        'dayOfWeek': w.dayOfWeek,
        'briefDescription': w.briefDescription ?? '',
        'exercises': [
          for (final e in w.exercises)
            {
              'exerciseId': e.exerciseId,
              'sets': e.sets.map((s) => {
                'reps': s.reps,
                if (s.targetLoadKg != null && s.targetLoadKg! > 0)
                  'targetLoadKg': s.targetLoadKg,
              }).toList(),
              if (e.restSeconds != null) 'restSeconds': e.restSeconds,
              'coachNote': e.coachingNote ?? '',
            },
        ],
      });
      for (var week = 0; week < durationWeeks; week++) {
        final weekStart = startDate.add(Duration(days: week * 7));
        final scheduledDate = _dateForDayOfWeek(weekStart, w.dayOfWeek);
        schedule.add(ProgramWorkout(workoutId: workoutId, scheduledDate: scheduledDate));
      }
    }

    final program = Program(
      id: programId,
      name: generated.programmeName,
      schedule: schedule,
      isAiGenerated: true,
      generationContext: null,
      deloadWeek: _parseDeloadWeek(generated.deloadWeek?.when),
      weeklyProgressionNotes: generated.weeklyProgression,
      coachIntro: generated.coachIntro,
      coachRationale: generated.coachRationale,
      coachRationaleSpoken: generated.coachRationaleSpoken,
      workoutBreakdowns: breakdowns.isNotEmpty ? jsonEncode(breakdowns) : null,
    );

    return (program, workouts);
  }

  /// Clamps a prescribed load to the equipment-aware minimum.
  /// Barbell ≥ 20 kg (the empty bar); kettlebell ≥ 4 kg; others unclamped.
  /// Zero means "no load prescribed" and is passed through unchanged.
  double _clampLoad(double load, Exercise? exercise) {
    if (load <= 0) return 0;
    final eq = exercise?.equipment?.toLowerCase() ?? '';
    if (eq.contains('barbell')) return load < 20.0 ? 20.0 : load;
    if (eq.contains('kettlebell')) return load < 4.0 ? 4.0 : load;
    return load;
  }

  DateTime _nextMonday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final daysUntilMonday = weekday == DateTime.monday ? 0 : (8 - weekday) % 7;
    return today.add(Duration(days: daysUntilMonday));
  }

  DateTime _dateForDayOfWeek(DateTime weekStart, String dayOfWeek) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final index = days.indexOf(dayOfWeek.toLowerCase());
    if (index < 0) return weekStart;
    return weekStart.add(Duration(days: index));
  }

  int? _parseDeloadWeek(String? when) {
    if (when == null) return null;
    final match = RegExp(r'week_(\d+)').firstMatch(when);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}
