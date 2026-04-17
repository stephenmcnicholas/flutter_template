import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';

void main() {
  final workout1 = ProgramWorkout(
    workoutId: 'w1',
    scheduledDate: DateTime(2025, 6, 1),
  );
  final workout2 = ProgramWorkout(
    workoutId: 'w2',
    scheduledDate: DateTime(2025, 6, 3),
  );
  final workout3 = ProgramWorkout(
    workoutId: 'w3',
    scheduledDate: DateTime(2025, 6, 5),
  );

  final sample = Program(
    id: 'p1',
    name: 'Full Body',
    schedule: [workout1, workout2, workout3],
  );

  group('Program model', () {
    test('value equality and hashCode', () {
      final other = Program(
        id: 'p1',
        name: 'Full Body',
        schedule: [workout1, workout2, workout3],
      );
      final differentId = Program(
        id: 'p2',
        name: 'Full Body',
        schedule: [workout1, workout2, workout3],
      );
      final differentName = Program(
        id: 'p1',
        name: 'Leg Day',
        schedule: [workout1, workout2, workout3],
      );
      final differentList = Program(
        id: 'p1',
        name: 'Full Body',
        schedule: [workout1, workout3, workout2], // same items, different order
      );

      // equality
      expect(sample, equals(other));
      expect(sample.hashCode, equals(other.hashCode));

      // inequality
      expect(sample == differentId, isFalse);
      expect(sample == differentName, isFalse);
      expect(sample == differentList, isFalse); // order matters
    });

    test('toJson/fromJson round-trip', () {
      final json = sample.toJson();
      final restored = Program.fromJson(json);

      expect(restored, equals(sample));
      expect(restored.hashCode, equals(sample.hashCode));
    });

    test('toJson/fromJson round-trip includes coachRationaleSpoken', () {
      final p = Program(
        id: 'p1',
        name: 'X',
        schedule: const [],
        coachRationale: 'Written for screen.',
        coachRationaleSpoken: 'Spoken for TTS.',
      );
      final restored = Program.fromJson(p.toJson());
      expect(restored.coachRationaleSpoken, 'Spoken for TTS.');
      expect(restored, equals(p));
    });

    test('default empty schedule', () {
      final noWorkouts = Program(id: 'p2', name: 'Solo');
      expect(noWorkouts.schedule, isEmpty);
    });
  });
}