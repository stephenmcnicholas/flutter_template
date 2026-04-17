import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/utils/program_utils.dart';

void main() {
  test('normalizeProgramDate strips time', () {
    final input = DateTime(2026, 1, 2, 15, 30, 45);
    final normalized = normalizeProgramDate(input);
    expect(normalized, DateTime(2026, 1, 2));
  });

  test('programWorkoutKey is stable for same day', () {
    final key = programWorkoutKey('w1', DateTime(2026, 1, 2, 15, 30));
    expect(key, 'w1|${DateTime(2026, 1, 2).toIso8601String()}');
  });

  test('programCompletionKeysFromSessions builds keys', () {
    final sessions = [
      WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2026, 1, 2, 9),
        entries: const [],
      ),
      WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2026, 1, 3, 10),
        entries: const [],
      ),
    ];
    final keys = programCompletionKeysFromSessions(sessions);
    expect(keys, contains(programWorkoutKey('w1', DateTime(2026, 1, 2))));
    expect(keys, contains(programWorkoutKey('w2', DateTime(2026, 1, 3))));
  });

  test('programWorkoutStatus returns completed when key exists', () {
    final workout = ProgramWorkout(
      workoutId: 'w1',
      scheduledDate: DateTime(2026, 1, 2),
    );
    final keys = {programWorkoutKey('w1', DateTime(2026, 1, 2))};
    final status = programWorkoutStatus(workout, keys, DateTime(2026, 1, 3));
    expect(status, ProgramWorkoutStatus.completed);
  });

  test('programWorkoutStatus returns missed for past date', () {
    final workout = ProgramWorkout(
      workoutId: 'w1',
      scheduledDate: DateTime(2026, 1, 1),
    );
    final status =
        programWorkoutStatus(workout, const {}, DateTime(2026, 1, 3));
    expect(status, ProgramWorkoutStatus.missed);
  });

  test('programWorkoutStatus returns planned for future date', () {
    final workout = ProgramWorkout(
      workoutId: 'w1',
      scheduledDate: DateTime(2026, 1, 5),
    );
    final status =
        programWorkoutStatus(workout, const {}, DateTime(2026, 1, 3));
    expect(status, ProgramWorkoutStatus.planned);
  });

  test('programStatusByKey maps each workout', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 2)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 3)),
    ];
    final keys = {programWorkoutKey('w1', DateTime(2026, 1, 2))};
    final map = programStatusByKey(schedule, keys, DateTime(2026, 1, 3));
    expect(map[programWorkoutKey('w1', DateTime(2026, 1, 2))],
        ProgramWorkoutStatus.completed);
    expect(map[programWorkoutKey('w2', DateTime(2026, 1, 3))],
        ProgramWorkoutStatus.planned);
  });

  test('updateProgramWorkoutDateAtIndex returns original on bad index', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
    ];
    expect(updateProgramWorkoutDateAtIndex(schedule, -1, DateTime(2026, 1, 3)),
        schedule);
    expect(updateProgramWorkoutDateAtIndex(schedule, 2, DateTime(2026, 1, 3)),
        schedule);
  });

  test('updateProgramWorkoutDateAtIndex updates date and normalizes', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 2)),
    ];
    final updated = updateProgramWorkoutDateAtIndex(
      schedule,
      1,
      DateTime(2026, 1, 5, 12),
    );
    expect(updated[1].scheduledDate, DateTime(2026, 1, 5));
  });

  test('shiftProgramScheduleByOffset keeps schedule when zero', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
    ];
    expect(shiftProgramScheduleByOffset(schedule, 0), schedule);
  });

  test('shiftProgramScheduleByOffset shifts all items', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 2)),
    ];
    final updated = shiftProgramScheduleByOffset(schedule, 2);
    expect(updated[0].scheduledDate, DateTime(2026, 1, 3));
    expect(updated[1].scheduledDate, DateTime(2026, 1, 4));
  });

  test('shiftProgramScheduleToNewStart keeps empty schedule', () {
    expect(shiftProgramScheduleToNewStart(const [], DateTime(2026, 1, 1)),
        isEmpty);
  });

  test('shiftProgramScheduleToNewStart offsets to new start', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 2)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 4)),
    ];
    final updated =
        shiftProgramScheduleToNewStart(schedule, DateTime(2026, 1, 5));
    expect(updated[0].scheduledDate, DateTime(2026, 1, 5));
    expect(updated[1].scheduledDate, DateTime(2026, 1, 7));
  });

  test('indexOfEarliestProgramWorkout returns -1 for empty', () {
    expect(indexOfEarliestProgramWorkout(const []), -1);
  });

  test('indexOfEarliestProgramWorkout finds earliest date', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 3)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 1)),
      ProgramWorkout(workoutId: 'w3', scheduledDate: DateTime(2026, 1, 2)),
    ];
    expect(indexOfEarliestProgramWorkout(schedule), 1);
  });

  test('indexOfEarliestProgramWorkout returns 0 for single item', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 2)),
    ];
    expect(indexOfEarliestProgramWorkout(schedule), 0);
  });

  test('shiftProgramScheduleByEditingIndex returns schedule for bad index', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
    ];
    expect(
      shiftProgramScheduleByEditingIndex(schedule, -1, DateTime(2026, 1, 2)),
      schedule,
    );
    expect(
      shiftProgramScheduleByEditingIndex(schedule, 1, DateTime(2026, 1, 2)),
      schedule,
    );
  });

  test('shiftProgramScheduleByEditingIndex only shifts edited and later dates', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 3)),
      ProgramWorkout(workoutId: 'w3', scheduledDate: DateTime(2026, 1, 5)),
    ];

    final updated = shiftProgramScheduleByEditingIndex(
      schedule,
      1,
      DateTime(2026, 1, 6),
    );

    expect(updated[0].scheduledDate, DateTime(2026, 1, 1));
    expect(updated[1].scheduledDate, DateTime(2026, 1, 6));
    expect(updated[2].scheduledDate, DateTime(2026, 1, 8));
  });

  test('shiftProgramScheduleByEditingIndex returns schedule when no shift', () {
    final schedule = [
      ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2026, 1, 1)),
      ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2026, 1, 3)),
    ];

    final updated = shiftProgramScheduleByEditingIndex(
      schedule,
      1,
      DateTime(2026, 1, 3),
    );

    expect(updated, schedule);
  });

  test('isProgramScheduleFullyCompleted is true only when every slot is completed', () {
    final program = Program(
      id: 'p1',
      name: 'P',
      schedule: [
        ProgramWorkout(workoutId: 'a', scheduledDate: DateTime(2026, 1, 1)),
        ProgramWorkout(workoutId: 'b', scheduledDate: DateTime(2026, 1, 2)),
      ],
    );
    final k1 = programWorkoutKey('a', DateTime(2026, 1, 1));
    final k2 = programWorkoutKey('b', DateTime(2026, 1, 2));
    expect(
      isProgramScheduleFullyCompleted(program, {
        k1: ProgramWorkoutStatus.completed,
        k2: ProgramWorkoutStatus.planned,
      }),
      isFalse,
    );
    expect(
      isProgramScheduleFullyCompleted(program, {
        k1: ProgramWorkoutStatus.completed,
        k2: ProgramWorkoutStatus.completed,
      }),
      isTrue,
    );
    expect(isProgramScheduleFullyCompleted(Program(id: 'e', name: 'E'), {}), isFalse);
  });

  test('programmeLoggedStats sums sessions and volume for schedule workout ids', () {
    final program = Program(
      id: 'p1',
      name: 'P',
      schedule: [
        ProgramWorkout(workoutId: 'a', scheduledDate: DateTime(2026, 1, 1)),
      ],
    );
    final sessions = [
      WorkoutSession(
        id: 's1',
        workoutId: 'a',
        date: DateTime(2026, 1, 5),
        entries: [
          WorkoutEntry(id: 'e1', exerciseId: 'ex', reps: 10, weight: 50, isComplete: true),
        ],
      ),
      WorkoutSession(
        id: 's2',
        workoutId: 'other',
        date: DateTime(2026, 1, 6),
        entries: const [],
      ),
    ];
    final stats = programmeLoggedStats(program, sessions);
    expect(stats.sessionCount, 1);
    expect(stats.totalSets, 1);
    expect(stats.totalVolumeKg, 500.0);
  });

  test('countSessionsForProgramSchedule counts sessions whose workoutId is on schedule', () {
    final program = Program(
      id: 'p1',
      name: 'P',
      schedule: [
        ProgramWorkout(workoutId: 'a', scheduledDate: DateTime(2026, 1, 1)),
        ProgramWorkout(workoutId: 'b', scheduledDate: DateTime(2026, 1, 2)),
      ],
    );
    final sessions = [
      WorkoutSession(id: '1', workoutId: 'a', date: DateTime(2026, 1, 5), entries: const []),
      WorkoutSession(id: '2', workoutId: 'a', date: DateTime(2026, 1, 6), entries: const []),
      WorkoutSession(id: '3', workoutId: 'c', date: DateTime(2026, 1, 7), entries: const []),
    ];
    expect(countSessionsForProgramSchedule(program, sessions), 2);
  });

  test('midProgrammeMilestoneForSessionCount is null unless positive multiple of 6', () {
    expect(midProgrammeMilestoneForSessionCount(0), isNull);
    expect(midProgrammeMilestoneForSessionCount(5), isNull);
    expect(midProgrammeMilestoneForSessionCount(7), isNull);
    expect(midProgrammeMilestoneForSessionCount(6), 1);
    expect(midProgrammeMilestoneForSessionCount(12), 2);
    expect(midProgrammeMilestoneForSessionCount(18), 3);
  });
}
