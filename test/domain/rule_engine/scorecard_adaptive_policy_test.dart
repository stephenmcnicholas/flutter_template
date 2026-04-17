import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_adaptive_policy.dart';

void main() {
  test('checkInDensity maps levels 1–2 full, 3 moderate, 4–5 minimal', () {
    expect(ScorecardAdaptivePolicy.checkInDensity(1), CheckInPromptDensity.full);
    expect(ScorecardAdaptivePolicy.checkInDensity(2), CheckInPromptDensity.full);
    expect(ScorecardAdaptivePolicy.checkInDensity(3), CheckInPromptDensity.moderate);
    expect(ScorecardAdaptivePolicy.checkInDensity(4), CheckInPromptDensity.minimal);
    expect(ScorecardAdaptivePolicy.checkInDensity(5), CheckInPromptDensity.minimal);
  });

  test('preWorkoutSubtitle returns distinct copy per density', () {
    final a = ScorecardAdaptivePolicy.preWorkoutSubtitle(CheckInPromptDensity.full);
    final b = ScorecardAdaptivePolicy.preWorkoutSubtitle(CheckInPromptDensity.minimal);
    expect(a, isNot(contains('Optional:')));
    expect(b, contains('Optional'));
  });
}
