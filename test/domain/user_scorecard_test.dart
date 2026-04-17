import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

void main() {
  test('default scorecard has expected initial values', () {
    const scorecard = UserScorecard(id: 'local');
    expect(scorecard.consistency, 5.0);
    expect(scorecard.progression, 3.0);
    expect(scorecard.endurance, 3.0);
    expect(scorecard.variety, 5.0);
    expect(scorecard.fundamentals, 1.0);
    expect(scorecard.selfAwareness, 5.0);
    expect(scorecard.curiosity, 5.0);
    expect(scorecard.reliability, 5.0);
    expect(scorecard.adaptability, 5.0);
    expect(scorecard.independence, 3.0);
    expect(scorecard.computedLevel, 1);
    expect(scorecard.lastUpdated, isNull);
  });

  test('allScores returns 10 values', () {
    const scorecard = UserScorecard(id: 'local');
    expect(scorecard.allScores, hasLength(10));
  });

  test('weightedAverage produces reasonable value', () {
    const scorecard = UserScorecard(id: 'local');
    final avg = scorecard.weightedAverage;
    expect(avg, greaterThan(0));
    expect(avg, lessThanOrEqualTo(10));
  });

  test('copyWith preserves unchanged fields', () {
    const original = UserScorecard(id: 'local', consistency: 7.0);
    final updated = original.copyWith(progression: 5.0);
    expect(updated.consistency, 7.0);
    expect(updated.progression, 5.0);
    expect(updated.id, 'local');
  });

  test('equality and hashCode', () {
    const a = UserScorecard(id: 'local', consistency: 7.0);
    const b = UserScorecard(id: 'local', consistency: 7.0);
    const c = UserScorecard(id: 'local', consistency: 8.0);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });

  test('toNarrative returns meaningful text', () {
    const scorecard = UserScorecard(
      id: 'local',
      consistency: 8.0,
      selfAwareness: 2.0,
      variety: 2.0,
      computedLevel: 2,
    );
    final narrative = scorecard.toNarrative();
    expect(narrative, contains('show up'));
    expect(narrative, contains('conservative'));
    expect(narrative, contains('variety'));
    expect(narrative, contains('Novice'));
  });

  test('toNarrative for mid profile uses fallback summary', () {
    const scorecard = UserScorecard(
      id: 'local',
      computedLevel: 3,
      fundamentals: 5.0,
      endurance: 5.0,
    );
    final narrative = scorecard.toNarrative();
    expect(narrative, contains('middle'));
    expect(narrative, contains('Intermediate'));
  });
}
