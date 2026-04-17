import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  group('WorkoutSession', () {
    final entry1 = WorkoutEntry(
      id: 'e1',
      exerciseId: 'squat',
      reps: 5,
      weight: 100.0,
      isComplete: false,
      timestamp: null,
    );
    final entry2 = WorkoutEntry(
      id: 'e2',
      exerciseId: 'bench',
      reps: 8,
      weight: 60.0,
      isComplete: false,
      timestamp: null,
    );

    final session = WorkoutSession(
      id: 'session1',
      workoutId: 'workoutA',
      date: DateTime.parse('2024-05-20T08:00:00Z'),
      name: 'Push Day',
      notes: 'Felt strong',
      entries: [entry1, entry2],
    );

    test('can be constructed and fields are correct', () {
      expect(session.id, 'session1');
      expect(session.workoutId, 'workoutA');
      expect(session.date, DateTime.parse('2024-05-20T08:00:00Z'));
      expect(session.name, 'Push Day');
      expect(session.notes, 'Felt strong');
      expect(session.entries, [entry1, entry2]);
    });

    test('equality and hashCode', () {
      final session2 = WorkoutSession(
        id: 'session1',
        workoutId: 'workoutA',
        date: DateTime.parse('2024-05-20T08:00:00Z'),
        name: 'Push Day',
        notes: 'Felt strong',
        entries: [entry1, entry2],
      );
      expect(session, equals(session2));
      expect(session.hashCode, equals(session2.hashCode));
    });

    test('toJson and fromJson', () {
      final json = session.toJson();
      final fromJson = WorkoutSession.fromJson(json);
      expect(fromJson, equals(session));
    });

    test('toJson produces expected map', () {
      final json = session.toJson();
      expect(json['id'], 'session1');
      expect(json['workoutId'], 'workoutA');
      expect(json['date'], '2024-05-20T08:00:00.000Z');
      expect(json['name'], 'Push Day');
      expect(json['notes'], 'Felt strong');
      expect(json['entries'], isA<List>());
      expect(json['entries'].length, 2);
    });
  });
}