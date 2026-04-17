import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/user_scorecard_repository.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

void main() {
  late AppDatabase db;
  late UserScorecardRepository repo;

  setUp(() {
    db = AppDatabase.test();
    repo = UserScorecardRepository(db);
  });

  tearDown(() => db.close());

  test('getScorecard returns null when no scorecard exists', () async {
    final result = await repo.getScorecard();
    expect(result, isNull);
  });

  test('loadOrCreate inserts defaults then returns same row', () async {
    final first = await repo.loadOrCreate();
    expect(first.id, kLocalScorecardId);
    expect(first.consistency, 5.0);

    final second = await repo.loadOrCreate();
    expect(second.id, first.id);
    expect(second.consistency, first.consistency);
  });

  test('upsertScorecard then getScorecard returns saved data', () async {
    final now = DateTime.fromMillisecondsSinceEpoch(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000,
    );
    final scorecard = UserScorecard(
      id: kLocalScorecardId,
      consistency: 7.5,
      progression: 4.0,
      endurance: 5.5,
      variety: 6.0,
      fundamentals: 2.0,
      selfAwareness: 8.0,
      curiosity: 3.5,
      reliability: 9.0,
      adaptability: 4.5,
      independence: 6.5,
      computedLevel: 3,
      lastUpdated: now,
    );

    await repo.upsertScorecard(scorecard);
    final result = await repo.getScorecard();

    expect(result, isNotNull);
    expect(result!.id, kLocalScorecardId);
    expect(result.consistency, 7.5);
    expect(result.progression, 4.0);
    expect(result.endurance, 5.5);
    expect(result.variety, 6.0);
    expect(result.fundamentals, 2.0);
    expect(result.selfAwareness, 8.0);
    expect(result.curiosity, 3.5);
    expect(result.reliability, 9.0);
    expect(result.adaptability, 4.5);
    expect(result.independence, 6.5);
    expect(result.computedLevel, 3);
    expect(result.lastUpdated, now);
  });

  test('upsertScorecard updates individual attributes', () async {
    final initial = UserScorecard(id: kLocalScorecardId);
    await repo.upsertScorecard(initial);

    final updated = initial.copyWith(consistency: 8.0, computedLevel: 2);
    await repo.upsertScorecard(updated);

    final result = await repo.getScorecard();
    expect(result!.consistency, 8.0);
    expect(result.computedLevel, 2);
    expect(result.progression, 3.0); // unchanged default
  });
}
