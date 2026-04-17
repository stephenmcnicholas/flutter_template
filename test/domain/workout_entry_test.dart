import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  group('WorkoutEntry model', () {
    final now = DateTime.now();
    final recordEntry = WorkoutEntry(
      id: 'w1',
      exerciseId: 'e1',
      reps: 10,
      weight: 80.5,
      isComplete: false,
      timestamp: now,
      sessionId: 'session1',
    );
    final templateEntry = WorkoutEntry(
      id: 't1',
      exerciseId: 'e2',
      reps: 8,
      weight: 60.0,
      isComplete: false,
      timestamp: null,
      sessionId: null,
    );

    test('value equality and hashCode (record)', () {
      final same = WorkoutEntry(
        id: 'w1',
        exerciseId: 'e1',
        reps: 10,
        weight: 80.5,
        isComplete: false,
        timestamp: now,
        sessionId: 'session1',
      );
      expect(recordEntry, equals(same));
      expect(recordEntry.hashCode, same.hashCode);
    });

    test('value equality and hashCode (template)', () {
      final same = WorkoutEntry(
        id: 't1',
        exerciseId: 'e2',
        reps: 8,
        weight: 60.0,
        isComplete: false,
        timestamp: null,
        sessionId: null,
      );
      expect(templateEntry, equals(same));
      expect(templateEntry.hashCode, same.hashCode);
    });

    test('toJson/fromJson round-trip (record)', () {
      final json = recordEntry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(recordEntry));
    });

    test('toJson/fromJson round-trip (template)', () {
      final json = templateEntry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(templateEntry));
    });

    test('toJson/fromJson round-trip with sessionId', () {
      final entry = WorkoutEntry(
        id: 'w3',
        exerciseId: 'e3',
        reps: 5,
        weight: 70.0,
        isComplete: false,
        timestamp: now,
        sessionId: 'sessionX',
      );
      final json = entry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(entry));
      expect(restored.sessionId, 'sessionX');
    });

    test('toJson/fromJson round-trip without sessionId', () {
      final entry = WorkoutEntry(
        id: 'w4',
        exerciseId: 'e4',
        reps: 7,
        weight: 65.0,
        isComplete: false,
        timestamp: now,
        sessionId: null,
      );
      final json = entry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(entry));
      expect(restored.sessionId, isNull);
    });

    test('value equality includes distance and duration', () {
      final entry1 = WorkoutEntry(
        id: 'w5',
        exerciseId: 'e5',
        reps: 0,
        weight: 0.0,
        distance: 5.0,
        duration: 1800,
        isComplete: false,
        timestamp: null,
      );
      final entry2 = WorkoutEntry(
        id: 'w5',
        exerciseId: 'e5',
        reps: 0,
        weight: 0.0,
        distance: 5.0,
        duration: 1800,
        isComplete: false,
        timestamp: null,
      );
      expect(entry1, equals(entry2));
      expect(entry1.hashCode, entry2.hashCode);
    });

    test('value equality distinguishes entries with different distance/duration', () {
      final entry1 = WorkoutEntry(
        id: 'w6',
        exerciseId: 'e6',
        reps: 0,
        weight: 0.0,
        distance: 5.0,
        duration: 1800,
        isComplete: false,
        timestamp: null,
      );
      final entry2 = WorkoutEntry(
        id: 'w6',
        exerciseId: 'e6',
        reps: 0,
        weight: 0.0,
        distance: 10.0,
        duration: 3600,
        isComplete: false,
        timestamp: null,
      );
      expect(entry1, isNot(equals(entry2)));
    });

    test('toJson/fromJson round-trip with distance and duration', () {
      final entry = WorkoutEntry(
        id: 'w7',
        exerciseId: 'e7',
        reps: 0,
        weight: 0.0,
        distance: 5.5,
        duration: 1800,
        isComplete: false,
        timestamp: now,
        sessionId: 'session1',
      );
      final json = entry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(entry));
      expect(restored.distance, 5.5);
      expect(restored.duration, 1800);
    });

    test('toJson/fromJson round-trip without distance and duration', () {
      final entry = WorkoutEntry(
        id: 'w8',
        exerciseId: 'e8',
        reps: 10,
        weight: 100.0,
        distance: null,
        duration: null,
        isComplete: false,
        timestamp: now,
        sessionId: 'session1',
      );
      final json = entry.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored, equals(entry));
      expect(restored.distance, isNull);
      expect(restored.duration, isNull);
    });
  });
}