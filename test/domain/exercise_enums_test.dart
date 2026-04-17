import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_enums.dart';

void main() {
  test('MovementPattern storage roundtrip', () {
    for (final mp in MovementPattern.values) {
      final stored = movementPatternToStorage(mp);
      final restored = movementPatternFromStorage(stored);
      expect(restored, mp);
    }
  });

  test('movementPatternFromStorage returns null for unknown', () {
    expect(movementPatternFromStorage(null), isNull);
    expect(movementPatternFromStorage('unknown'), isNull);
  });

  test('SafetyTier storage roundtrip', () {
    for (final tier in SafetyTier.values) {
      final stored = safetyTierToStorage(tier);
      final restored = safetyTierFromStorage(stored);
      expect(restored, tier);
    }
  });

  test('safetyTierFromStorage defaults to tier1', () {
    expect(safetyTierFromStorage(null), SafetyTier.tier1);
    expect(safetyTierFromStorage(99), SafetyTier.tier1);
  });

  test('Laterality storage roundtrip', () {
    for (final lat in Laterality.values) {
      final stored = lateralityToStorage(lat);
      final restored = lateralityFromStorage(stored);
      expect(restored, lat);
    }
  });

  test('lateralityFromStorage returns null for unknown', () {
    expect(lateralityFromStorage(null), isNull);
    expect(lateralityFromStorage('something'), isNull);
  });

  test('SystemicFatigue storage roundtrip', () {
    for (final sf in SystemicFatigue.values) {
      final stored = systemicFatigueToStorage(sf);
      final restored = systemicFatigueFromStorage(stored);
      expect(restored, sf);
    }
  });

  test('systemicFatigueFromStorage defaults to medium', () {
    expect(systemicFatigueFromStorage(null), SystemicFatigue.medium);
    expect(systemicFatigueFromStorage('unknown'), SystemicFatigue.medium);
  });

  test('suitability storage roundtrip', () {
    final tags = ['beginner_friendly', 'home_friendly'];
    final stored = suitabilityToStorage(tags);
    expect(stored, 'beginner_friendly,home_friendly');
    final restored = suitabilityFromStorage(stored);
    expect(restored, tags);
  });

  test('suitabilityFromStorage handles null and empty', () {
    expect(suitabilityFromStorage(null), isEmpty);
    expect(suitabilityFromStorage(''), isEmpty);
  });

  test('suitabilityToStorage handles null and empty', () {
    expect(suitabilityToStorage(null), isNull);
    expect(suitabilityToStorage([]), isNull);
  });
}
