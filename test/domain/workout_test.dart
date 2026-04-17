import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  final entry1 = WorkoutEntry(
    id: 'e1',
    exerciseId: 'ex1',
    reps: 10,
    weight: 100.0,
    isComplete: false,
    timestamp: null,
  );
  final entry2 = WorkoutEntry(
    id: 'e2',
    exerciseId: 'ex2',
    reps: 8,
    weight: 80.0,
    isComplete: false,
    timestamp: null,
  );
  final entry3 = WorkoutEntry(
    id: 'e3',
    exerciseId: 'ex3',
    reps: 12,
    weight: 60.0,
    isComplete: false,
    timestamp: null,
  );

  final sample = Workout(
    id: 'w1',
    name: 'Upper Body Blast',
    entries: [entry1, entry2, entry3],
  );

  test('value equality and hashCode', () {
    final same = Workout(
      id: 'w1',
      name: 'Upper Body Blast',
      entries: [entry1, entry2, entry3],
    );

    expect(sample, equals(same));
    expect(sample.hashCode, equals(same.hashCode));

    final diffName = Workout(
      id: 'w1',
      name: 'Leg Day',
      entries: [entry1, entry2, entry3],
    );
    expect(sample == diffName, isFalse);

    final diffEntries = Workout(
      id: 'w1',
      name: 'Upper Body Blast',
      entries: [entry1, entry2],
    );
    expect(sample == diffEntries, isFalse);
  });

  test('toJson / fromJson round trip', () {
    final json = sample.toJson();
    final restored = Workout.fromJson(json);

    expect(restored, equals(sample));
  });

  test('empty entries list is supported', () {
    final empty = Workout(
      id: 'w2',
      name: 'No Exercises',
      entries: [],
    );

    // Serialization round trip
    final roundTripped = Workout.fromJson(empty.toJson());
    expect(roundTripped.entries, isEmpty);
    expect(roundTripped, equals(empty));
  });
}