import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/session_check_in_repository.dart';
import 'package:fytter/src/domain/session_check_in.dart';

void main() {
  late AppDatabase db;
  late SessionCheckInRepository repo;

  setUp(() {
    db = AppDatabase.test();
    repo = SessionCheckInRepository(db);
  });

  tearDown(() => db.close());

  DateTime truncatedNow() => DateTime.fromMillisecondsSinceEpoch(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000,
      );

  test('save and getBySession returns saved check-in', () async {
    final now = truncatedNow();
    final checkIn = SessionCheckIn(
      id: 'ci-1',
      sessionId: 'session-1',
      programmeId: 'prog-1',
      checkInType: CheckInType.preWorkout,
      rating: CheckInRating.green,
      freeText: 'Feeling great',
      createdAt: now,
    );

    await repo.save(checkIn);
    final results = await repo.getBySession('session-1');

    expect(results, hasLength(1));
    expect(results.first.id, 'ci-1');
    expect(results.first.checkInType, CheckInType.preWorkout);
    expect(results.first.rating, CheckInRating.green);
    expect(results.first.freeText, 'Feeling great');
  });

  test('getByProgramme returns check-ins for that programme', () async {
    final now = truncatedNow();
    await repo.save(SessionCheckIn(
      id: 'ci-1',
      programmeId: 'prog-1',
      checkInType: CheckInType.midProgramme,
      rating: CheckInRating.aboutRight,
      createdAt: now,
    ));
    await repo.save(SessionCheckIn(
      id: 'ci-2',
      programmeId: 'prog-2',
      checkInType: CheckInType.midProgramme,
      rating: CheckInRating.tooHard,
      createdAt: now,
    ));

    final results = await repo.getByProgramme('prog-1');
    expect(results, hasLength(1));
    expect(results.first.id, 'ci-1');
  });

  test('getRecent returns check-ins in descending order', () async {
    final base = truncatedNow();
    await repo.save(SessionCheckIn(
      id: 'ci-1',
      checkInType: CheckInType.postSession,
      rating: CheckInRating.great,
      createdAt: base.subtract(const Duration(hours: 2)),
    ));
    await repo.save(SessionCheckIn(
      id: 'ci-2',
      checkInType: CheckInType.postSession,
      rating: CheckInRating.tough,
      createdAt: base,
    ));
    await repo.save(SessionCheckIn(
      id: 'ci-3',
      checkInType: CheckInType.postSession,
      rating: CheckInRating.okay,
      createdAt: base.subtract(const Duration(hours: 1)),
    ));

    final results = await repo.getRecent(2);
    expect(results, hasLength(2));
    expect(results[0].id, 'ci-2');
    expect(results[1].id, 'ci-3');
  });
}
