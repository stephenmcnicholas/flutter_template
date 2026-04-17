import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/scheduled_program.dart';

void main() {
  group('ScheduledProgram', () {
    final scheduled = ScheduledProgram(
      id: 'sched1',
      programId: 'prog1',
      date: DateTime(2025, 5, 27),
      notes: 'Test note',
    );

    test('can be constructed', () {
      expect(scheduled.id, 'sched1');
      expect(scheduled.programId, 'prog1');
      expect(scheduled.date, DateTime(2025, 5, 27));
      expect(scheduled.notes, 'Test note');
    });

    test('equality and hashCode', () {
      final a = ScheduledProgram(
        id: 'sched1',
        programId: 'prog1',
        date: DateTime(2025, 5, 27),
        notes: 'Test note',
      );
      final b = ScheduledProgram(
        id: 'sched1',
        programId: 'prog1',
        date: DateTime(2025, 5, 27),
        notes: 'Test note',
      );
      final c = ScheduledProgram(
        id: 'sched2',
        programId: 'prog2',
        date: DateTime(2025, 5, 28),
        notes: null,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('toJson and fromJson', () {
      final json = scheduled.toJson();
      expect(json['id'], 'sched1');
      expect(json['programId'], 'prog1');
      expect(json['date'], '2025-05-27T00:00:00.000');
      expect(json['notes'], 'Test note');

      final fromJson = ScheduledProgram.fromJson(json);
      expect(fromJson, scheduled);
    });
  });
} 