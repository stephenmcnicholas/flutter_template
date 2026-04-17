import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/progress_weekly_trend.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';

void main() {
  group('weekStartMonday', () {
    test('Wednesday maps to that week Monday', () {
      final wed = DateTime(2026, 3, 25);
      expect(weekStartMonday(wed), DateTime(2026, 3, 23));
    });

    test('Monday maps to same day', () {
      final mon = DateTime(2026, 3, 23);
      expect(weekStartMonday(mon), DateTime(2026, 3, 23));
    });
  });

  group('buildWeeklyTrend', () {
    /// Wednesday 2026-03-25 15:00 — ISO week starts 2026-03-23 (Monday).
    final ref = DateTime(2026, 3, 25, 15);

    test('empty sessions yields zero buckets', () {
      final s = buildWeeklyTrend([], weekCount: 4, referenceNow: ref);
      expect(s.weeks, hasLength(4));
      expect(s.isEmpty, isTrue);
      for (final w in s.weeks) {
        expect(w.sessionCount, 0);
        expect(w.volumeKg, 0.0);
      }
    });

    test('counts session and volume in correct week', () {
      final sessions = [
        WorkoutSession(
          id: 'a',
          workoutId: 'w1',
          date: DateTime(2026, 3, 25, 10),
          entries: [
            WorkoutEntry(
              id: 'e1',
              exerciseId: 'ex',
              reps: 10,
              weight: 50,
              isComplete: true,
            ),
          ],
        ),
      ];
      final s = buildWeeklyTrend(sessions, weekCount: 4, referenceNow: ref);
      expect(s.isEmpty, isFalse);
      final last = s.weeks.last;
      expect(last.weekStartMonday, DateTime(2026, 3, 23));
      expect(last.sessionCount, 1);
      expect(last.volumeKg, 500.0);
    });

    test('drops sessions outside window', () {
      final sessions = [
        WorkoutSession(
          id: 'old',
          workoutId: 'w1',
          date: DateTime(2026, 2, 1),
          entries: [
            WorkoutEntry(
              id: 'e1',
              exerciseId: 'ex',
              reps: 5,
              weight: 100,
              isComplete: true,
            ),
          ],
        ),
      ];
      final s = buildWeeklyTrend(sessions, weekCount: 4, referenceNow: ref);
      expect(s.isEmpty, isTrue);
    });

    test('multiple sessions same week aggregate volume', () {
      final sessions = [
        WorkoutSession(
          id: 'a',
          workoutId: 'w1',
          date: DateTime(2026, 3, 25),
          entries: [
            WorkoutEntry(
              id: 'e1',
              exerciseId: 'ex',
              reps: 2,
              weight: 10,
              isComplete: true,
            ),
          ],
        ),
        WorkoutSession(
          id: 'b',
          workoutId: 'w2',
          date: DateTime(2026, 3, 26),
          entries: [
            WorkoutEntry(
              id: 'e2',
              exerciseId: 'ex',
              reps: 1,
              weight: 20,
              isComplete: true,
            ),
          ],
        ),
      ];
      final s = buildWeeklyTrend(sessions, weekCount: 4, referenceNow: ref);
      final last = s.weeks.last;
      expect(last.sessionCount, 2);
      expect(last.volumeKg, 40.0);
    });
  });
}
