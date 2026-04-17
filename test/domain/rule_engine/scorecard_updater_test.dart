import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_updater.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';

UserScorecard _card({
  double consistency = 5,
  double progression = 5,
  double endurance = 5,
  double variety = 5,
  double fundamentals = 5,
  double selfAwareness = 5,
  double curiosity = 5,
  double reliability = 5,
  double adaptability = 5,
  double independence = 5,
  int level = 3,
}) {
  return UserScorecard(
    id: 'local',
    consistency: consistency,
    progression: progression,
    endurance: endurance,
    variety: variety,
    fundamentals: fundamentals,
    selfAwareness: selfAwareness,
    curiosity: curiosity,
    reliability: reliability,
    adaptability: adaptability,
    independence: independence,
    computedLevel: level,
  );
}

void main() {
  group('levelFromWeightedAverage', () {
    test('4.5 maps to level 2 and 4.6 to level 3', () {
      expect(ScorecardUpdater.levelFromWeightedAverage(4.5), 2);
      expect(ScorecardUpdater.levelFromWeightedAverage(4.6), 3);
    });

    test('band boundaries', () {
      expect(ScorecardUpdater.levelFromWeightedAverage(3.99), 1);
      expect(ScorecardUpdater.levelFromWeightedAverage(4.0), 2);
      expect(ScorecardUpdater.levelFromWeightedAverage(5.49), 3);
      expect(ScorecardUpdater.levelFromWeightedAverage(5.5), 4);
      expect(ScorecardUpdater.levelFromWeightedAverage(6.5), 5);
      expect(ScorecardUpdater.levelFromWeightedAverage(10.0), 5);
    });
  });

  group('recomputeLevel', () {
    test('aligns computedLevel with weightedAverage', () {
      final s = _card(
        consistency: 8,
        progression: 8,
        endurance: 8,
        variety: 8,
        fundamentals: 8,
        selfAwareness: 8,
        curiosity: 8,
        reliability: 8,
        adaptability: 8,
        independence: 8,
        level: 1,
      );
      final at = DateTime(2026, 6, 1);
      final u = ScorecardUpdater.recomputeLevel(s, at: at);
      expect(u.computedLevel, greaterThan(1));
      expect(u.lastUpdated, at);
    });
  });

  group('applyInactivityDecay', () {
    test('no-op within 7 days', () {
      final s = _card(consistency: 8);
      final out = ScorecardUpdater.applyInactivityDecay(
        s,
        daysSinceAnyWorkout: 3,
        totalLifetimeSessions: 60,
      );
      expect(out.consistency, 8.0);
    });

    test('pulls toward floor 2.0 for 50+ lifetime sessions', () {
      final s = _card(consistency: 8, progression: 8);
      final out = ScorecardUpdater.applyInactivityDecay(
        s,
        daysSinceAnyWorkout: 40,
        totalLifetimeSessions: 55,
      );
      expect(out.consistency, lessThan(8.0));
      expect(out.consistency, greaterThanOrEqualTo(2.0));
    });

    test('pulls toward floor 1.0 for newer users', () {
      final s = _card(consistency: 6);
      final out = ScorecardUpdater.applyInactivityDecay(
        s,
        daysSinceAnyWorkout: 40,
        totalLifetimeSessions: 10,
      );
      expect(out.consistency, lessThan(6.0));
      expect(out.consistency, greaterThanOrEqualTo(1.0));
    });
  });

  group('updateConsistency', () {
    test('full adherence raises score toward high band', () {
      final v = ScorecardUpdater.updateConsistency(
        current: 5,
        scheduledLast28Days: 12,
        completedLast28Days: 12,
      );
      expect(v, greaterThan(5));
      expect(v, lessThanOrEqualTo(10));
    });

    test('zero scheduled leaves current', () {
      expect(
        ScorecardUpdater.updateConsistency(
          current: 5,
          scheduledLast28Days: 0,
          completedLast28Days: 0,
        ),
        5.0,
      );
    });
  });

  group('updateProgression', () {
    test('rising volume increases progression', () {
      final sessions = [
        WorkoutSession(
          id: 'a',
          workoutId: 'w',
          date: DateTime(2026, 1, 1),
          entries: [
            WorkoutEntry(id: '1', exerciseId: 'e', reps: 10, weight: 50, isComplete: true),
          ],
        ),
        WorkoutSession(
          id: 'b',
          workoutId: 'w',
          date: DateTime(2026, 1, 2),
          entries: [
            WorkoutEntry(id: '2', exerciseId: 'e', reps: 10, weight: 60, isComplete: true),
          ],
        ),
      ];
      final v = ScorecardUpdater.updateProgression(current: 4, recentSessions: sessions);
      expect(v, greaterThan(4));
    });

    test('single session returns current', () {
      final one = [
        WorkoutSession(
          id: 'a',
          workoutId: 'w',
          date: DateTime(2026, 1, 1),
          entries: const [],
        ),
      ];
      expect(ScorecardUpdater.updateProgression(current: 5, recentSessions: one), 5.0);
    });
  });

  group('updateEndurance', () {
    test('high completion with balanced duration scores well', () {
      final v = ScorecardUpdater.updateEndurance(
        current: 4,
        completionRatio: 1.0,
        durationRatio: 1.0,
      );
      expect(v, greaterThan(4));
    });
  });

  group('updateVariety', () {
    test('empty available patterns returns current', () {
      expect(
        ScorecardUpdater.updateVariety(
          current: 5,
          recentMovementPatternIds: {'a'},
          availablePatterns: {},
        ),
        5.0,
      );
    });

    test('covering all patterns increases variety', () {
      final avail = {'push', 'pull', 'legs'};
      final v = ScorecardUpdater.updateVariety(
        current: 3,
        recentMovementPatternIds: {...avail},
        availablePatterns: avail,
      );
      expect(v, greaterThan(3));
    });
  });

  group('updateFundamentals', () {
    test('tracks training average with lag', () {
      final s = _card(
        consistency: 8,
        progression: 8,
        endurance: 8,
        variety: 8,
        fundamentals: 2,
      );
      final v = ScorecardUpdater.updateFundamentals(s);
      expect(v, greaterThan(2));
      expect(v, lessThan(8));
    });
  });

  group('updateSelfAwareness', () {
    test('great check-in but weak performance lowers score', () {
      final v = ScorecardUpdater.updateSelfAwareness(
        current: 7,
        checkInRating: CheckInRating.great,
        performanceWasWeakerThanCheckIn: true,
      );
      expect(v, lessThan(7));
    });
  });

  group('updateCuriosity', () {
    test('instruction view bumps curiosity', () {
      final v = ScorecardUpdater.updateCuriosity(
        current: 4,
        interaction: ScorecardInteractionKind.instructionViewed,
      );
      expect(v, greaterThan(4));
    });
  });

  group('updateReliability', () {
    test('on-time training bumps reliability', () {
      final v = ScorecardUpdater.updateReliability(
        current: 5,
        trainedOnOrBeforeScheduledDay: true,
      );
      expect(v, greaterThan(5));
    });

    test('missed expectation lowers reliability', () {
      final v = ScorecardUpdater.updateReliability(
        current: 5,
        trainedOnOrBeforeScheduledDay: false,
      );
      expect(v, lessThan(5));
    });
  });

  group('updateAdaptability', () {
    test('accepted adjustment raises adaptability', () {
      final v = ScorecardUpdater.updateAdaptability(
        current: 5,
        adjustmentAccepted: true,
      );
      expect(v, greaterThan(5));
    });
  });

  group('updateIndependence', () {
    test('zero modifications leaves current', () {
      expect(
        ScorecardUpdater.updateIndependence(
          current: 5,
          sensibleModificationCount: 0,
          totalModifications: 0,
        ),
        5.0,
      );
    });

    test('all sensible modifications raise independence', () {
      final v = ScorecardUpdater.updateIndependence(
        current: 3,
        sensibleModificationCount: 4,
        totalModifications: 4,
      );
      expect(v, greaterThan(3));
    });
  });
}
