import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/session_check_in.dart';

void main() {
  test('SessionCheckIn equality and hashCode', () {
    final now = DateTime(2026, 3, 1);
    final a = SessionCheckIn(
      id: '1',
      sessionId: 's1',
      programmeId: 'p1',
      checkInType: CheckInType.preWorkout,
      rating: CheckInRating.green,
      freeText: 'Good',
      createdAt: now,
    );
    final b = SessionCheckIn(
      id: '1',
      sessionId: 's1',
      programmeId: 'p1',
      checkInType: CheckInType.preWorkout,
      rating: CheckInRating.green,
      freeText: 'Good',
      createdAt: now,
    );
    final c = a.copyWith(rating: CheckInRating.red);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });

  test('copyWith preserves unchanged fields', () {
    final original = SessionCheckIn(
      id: '1',
      checkInType: CheckInType.postSession,
      rating: CheckInRating.great,
      createdAt: DateTime(2026, 3, 1),
    );
    final updated = original.copyWith(freeText: 'Updated');
    expect(updated.id, '1');
    expect(updated.checkInType, CheckInType.postSession);
    expect(updated.rating, CheckInRating.great);
    expect(updated.freeText, 'Updated');
  });

  test('CheckInType storage roundtrip', () {
    for (final type in CheckInType.values) {
      final stored = checkInTypeToStorage(type);
      final restored = checkInTypeFromStorage(stored);
      expect(restored, type);
    }
  });

  test('CheckInRating storage roundtrip', () {
    for (final rating in CheckInRating.values) {
      final stored = checkInRatingToStorage(rating);
      final restored = checkInRatingFromStorage(stored);
      expect(restored, rating);
    }
  });

  test('checkInTypeFromStorage falls back for unknown value', () {
    expect(checkInTypeFromStorage('not_a_type'), CheckInType.postSession);
  });

  test('checkInRatingFromStorage falls back for unknown value', () {
    expect(checkInRatingFromStorage('not_a_rating'), CheckInRating.okay);
  });
}
