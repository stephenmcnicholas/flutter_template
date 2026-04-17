import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/services/notification_sync_service.dart';

void main() {
  group('buildDailyScheduleMap', () {
    final today = DateTime(2026, 2, 11); // Wednesday

    test('returns empty slots for all dates when no programs', () {
      final result = buildDailyScheduleMap(
        today: today,
        programs: [],
        workoutIdToName: {},
        reminderTimeMinutes: 480,
        days: 3,
      );
      expect(result.length, 3);
      expect(result['2026-02-11'], isEmpty);
      expect(result['2026-02-12'], isEmpty);
      expect(result['2026-02-13'], isEmpty);
    });

    test('skips programs with notification disabled', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: false,
          notificationTimeMinutes: 480,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11'], isEmpty);
    });

    test('uses global reminder time even when per-program time is null', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: null,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], ['Leg Day']);
    });

    test('includes workout name at correct date and minute slot', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480, // 8:00
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], ['Leg Day']);
    });

    test('uses workout id when name not in map', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], ['w1']);
    });

    test('skips dates outside window', () {
      // With today 2026-02-11 and days=14, window is 2026-02-11..2026-02-24.
      // Workout on 2026-02-25 is outside and should not appear.
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 25)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day'},
        reminderTimeMinutes: 480,
        days: 14,
      );
      expect(result.containsKey('2026-02-25'), false);
      expect(result['2026-02-24'], isEmpty); // last day in window has no workout
    });

    test('multiple workouts same day same minute are combined', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
            ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day', 'w2': 'Upper'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], containsAll(['Leg Day', 'Upper']));
      expect(result['2026-02-11']!['480']!.length, 2);
    });

    test('two programs same day use single global slot', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480,
        ),
        Program(
          id: 'p2',
          name: 'Program 2',
          schedule: [
            ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 2, 11)),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 540,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day', 'w2': 'Upper'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], ['Leg Day', 'Upper']);
      expect(result['2026-02-11']!.containsKey('540'), isFalse);
    });

    test('normalizes scheduled date to date-only', () {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(
              workoutId: 'w1',
              scheduledDate: DateTime(2026, 2, 11, 14, 30),
            ),
          ],
          notificationEnabled: true,
          notificationTimeMinutes: 480,
        ),
      ];
      final result = buildDailyScheduleMap(
        today: today,
        programs: programs,
        workoutIdToName: {'w1': 'Leg Day'},
        reminderTimeMinutes: 480,
        days: 1,
      );
      expect(result['2026-02-11']!['480'], ['Leg Day']);
    });
  });
}
