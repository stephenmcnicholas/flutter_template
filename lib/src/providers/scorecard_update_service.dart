import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_session_metrics.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_updater.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/logger/workout_duration_estimate.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/providers/user_scorecard_provider.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';

/// Applies [ScorecardUpdater] from app events and persists + invalidates [userScorecardProvider].
class ScorecardUpdateService {
  ScorecardUpdateService(this._ref);

  final Ref _ref;

  Future<void> _persist(UserScorecard scorecard) async {
    final repo = _ref.read(userScorecardRepositoryProvider);
    await repo.upsertScorecard(scorecard);
    _ref.invalidate(userScorecardProvider);
  }

  /// After a workout session is saved (non-empty completed sets).
  Future<void> onSessionCompleted({
    required WorkoutSession session,
    required Map<String, List<Map<String, dynamic>>> allSetsByExercise,
    required List<Exercise> sessionExercises,
    required Duration sessionDuration,
    String? programId,
  }) async {
    try {
      final scoreRepo = _ref.read(userScorecardRepositoryProvider);
      final sessionRepo = _ref.read(workoutSessionRepositoryProvider);
      final programRepo = _ref.read(programRepositoryProvider);
      final exercises = await _ref.read(exercisesFutureProvider.future);
      final rest = _ref.read(restTimerSettingsProvider);
      final restSeconds = rest.isLoading ? 120 : rest.defaultSeconds;

      var scorecard = await scoreRepo.loadOrCreate();
      final allSessions = await sessionRepo.findAll();
      final sortedNewest = List<WorkoutSession>.from(allSessions);
      final sortedAsc = List<WorkoutSession>.from(allSessions)
        ..sort((a, b) => a.date.compareTo(b.date));

      final now = DateTime.now();
      final lastDate = sortedAsc.isNotEmpty ? sortedAsc.last.date : now;
      final daysSince = scorecardDateOnlyLocal(now)
          .difference(scorecardDateOnlyLocal(lastDate))
          .inDays;

      scorecard = ScorecardUpdater.applyInactivityDecay(
        scorecard,
        daysSinceAnyWorkout: daysSince,
        totalLifetimeSessions: sortedAsc.length,
      );

      final programs = await programRepo.findAll();
      final scheduledLast28 =
          scorecardCountScheduledSlotsInRollingDayWindow(programs, now);
      final completedLast28 =
          scorecardCountSessionsInRollingDayWindow(sortedAsc, now);

      scorecard = scorecard.copyWith(
        consistency: ScorecardUpdater.updateConsistency(
          current: scorecard.consistency,
          scheduledLast28Days: scheduledLast28,
          completedLast28Days: completedLast28,
        ),
      );

      final recentForProgression = sortedAsc.length <= 8
          ? sortedAsc
          : sortedAsc.sublist(sortedAsc.length - 8);
      scorecard = scorecard.copyWith(
        progression: ScorecardUpdater.updateProgression(
          current: scorecard.progression,
          recentSessions: recentForProgression,
        ),
      );

      var plannedSets = 0;
      for (final sets in allSetsByExercise.values) {
        plannedSets += sets.length;
      }
      final completedSets = session.entries.length;
      final completionRatio =
          plannedSets > 0 ? completedSets / plannedSets : 1.0;
      final plannedMinutes = estimateWorkoutDurationMinutes(
        initialSetsByExercise: allSetsByExercise,
        restSeconds: restSeconds,
      );
      final actualMinutes =
          (sessionDuration.inSeconds / 60.0).clamp(1.0, 999.0);
      final durationRatio = actualMinutes / plannedMinutes;

      scorecard = scorecard.copyWith(
        endurance: ScorecardUpdater.updateEndurance(
          current: scorecard.endurance,
          completionRatio: completionRatio,
          durationRatio: durationRatio,
        ),
      );

      final recentIds = scorecardRecentExerciseIds(sortedNewest);
      for (final e in sessionExercises) {
        recentIds.add(e.id);
      }
      final recentPatterns =
          scorecardMovementPatternKeysForExerciseIds(recentIds, exercises);
      final availablePatterns = scorecardAllMovementPatternKeys(exercises);

      scorecard = scorecard.copyWith(
        variety: ScorecardUpdater.updateVariety(
          current: scorecard.variety,
          recentMovementPatternIds: recentPatterns,
          availablePatterns: availablePatterns,
        ),
      );

      scorecard = scorecard.copyWith(
        fundamentals: ScorecardUpdater.updateFundamentals(scorecard),
      );

      if (programId != null && programId.isNotEmpty) {
        try {
          final program = await programRepo.findById(programId);
          final nearest =
              scorecardNearestScheduledWorkout(program, session);
          if (nearest != null) {
            final onTime = scorecardTrainedOnOrBeforeScheduledDay(
              session,
              nearest,
            );
            scorecard = scorecard.copyWith(
              reliability: ScorecardUpdater.updateReliability(
                current: scorecard.reliability,
                trainedOnOrBeforeScheduledDay: onTime,
              ),
            );
          }
        } catch (_) {}
      }

      scorecard = ScorecardUpdater.recomputeLevel(scorecard, at: now);
      await _persist(scorecard);
    } catch (e, st) {
      debugPrint('ScorecardUpdateService.onSessionCompleted: $e\n$st');
    }
  }

  /// After post-workout mood is saved.
  Future<void> onPostWorkoutCheckIn({
    required CheckInRating rating,
    required bool performanceWasWeakerThanCheckIn,
  }) async {
    try {
      final scoreRepo = _ref.read(userScorecardRepositoryProvider);
      var scorecard = await scoreRepo.loadOrCreate();
      final now = DateTime.now();
      scorecard = scorecard.copyWith(
        selfAwareness: ScorecardUpdater.updateSelfAwareness(
          current: scorecard.selfAwareness,
          checkInRating: rating,
          performanceWasWeakerThanCheckIn: performanceWasWeakerThanCheckIn,
        ),
      );
      scorecard = ScorecardUpdater.recomputeLevel(scorecard, at: now);
      await _persist(scorecard);
    } catch (e, st) {
      debugPrint('ScorecardUpdateService.onPostWorkoutCheckIn: $e\n$st');
    }
  }

  /// After pre-workout red path adjustment (LLM vs rule fallback).
  Future<void> onPreWorkoutAdaptability({
    required bool adjustmentAccepted,
  }) async {
    try {
      final scoreRepo = _ref.read(userScorecardRepositoryProvider);
      var scorecard = await scoreRepo.loadOrCreate();
      final now = DateTime.now();
      scorecard = scorecard.copyWith(
        adaptability: ScorecardUpdater.updateAdaptability(
          current: scorecard.adaptability,
          adjustmentAccepted: adjustmentAccepted,
        ),
      );
      scorecard = ScorecardUpdater.recomputeLevel(scorecard, at: now);
      await _persist(scorecard);
    } catch (e, st) {
      debugPrint('ScorecardUpdateService.onPreWorkoutAdaptability: $e\n$st');
    }
  }

  Future<void> onCuriosityInteraction(ScorecardInteractionKind kind) async {
    try {
      final scoreRepo = _ref.read(userScorecardRepositoryProvider);
      var scorecard = await scoreRepo.loadOrCreate();
      final now = DateTime.now();
      scorecard = scorecard.copyWith(
        curiosity: ScorecardUpdater.updateCuriosity(
          current: scorecard.curiosity,
          interaction: kind,
        ),
      );
      scorecard = ScorecardUpdater.recomputeLevel(scorecard, at: now);
      await _persist(scorecard);
    } catch (e, st) {
      debugPrint('ScorecardUpdateService.onCuriosityInteraction: $e\n$st');
    }
  }
}

final scorecardUpdateServiceProvider = Provider<ScorecardUpdateService>((ref) {
  return ScorecardUpdateService(ref);
});
