import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';

void main() {
  // -------------------------------------------------------------------------
  // coachingTierFromComputedLevel
  // -------------------------------------------------------------------------

  group('coachingTierFromComputedLevel', () {
    test('levels 1 and 2 → beginner', () {
      expect(coachingTierFromComputedLevel(1), CoachingAudioTier.beginner);
      expect(coachingTierFromComputedLevel(2), CoachingAudioTier.beginner);
    });

    test('level 3 → intermediate', () {
      expect(coachingTierFromComputedLevel(3), CoachingAudioTier.intermediate);
    });

    test('levels 4 and 5 → advanced', () {
      expect(coachingTierFromComputedLevel(4), CoachingAudioTier.advanced);
      expect(coachingTierFromComputedLevel(5), CoachingAudioTier.advanced);
    });

    test('level 0 or below → beginner (edge case)', () {
      expect(coachingTierFromComputedLevel(0), CoachingAudioTier.beginner);
      expect(coachingTierFromComputedLevel(-1), CoachingAudioTier.beginner);
    });

    test('level 6 or above → advanced (edge case)', () {
      expect(coachingTierFromComputedLevel(6), CoachingAudioTier.advanced);
      expect(coachingTierFromComputedLevel(100), CoachingAudioTier.advanced);
    });
  });

  // -------------------------------------------------------------------------
  // coachingTierStorageName
  // -------------------------------------------------------------------------

  group('coachingTierStorageName', () {
    test('beginner → "beginner"', () {
      expect(coachingTierStorageName(CoachingAudioTier.beginner), 'beginner');
    });

    test('intermediate → "intermediate"', () {
      expect(
          coachingTierStorageName(CoachingAudioTier.intermediate), 'intermediate');
    });

    test('advanced → "advanced"', () {
      expect(coachingTierStorageName(CoachingAudioTier.advanced), 'advanced');
    });

    test('storage name matches the tier index used in exercise JSON', () {
      // These strings must exactly match the keys in exercises.json cue field tiers.
      for (final tier in CoachingAudioTier.values) {
        final name = coachingTierStorageName(tier);
        expect(
          ['beginner', 'intermediate', 'advanced'].contains(name),
          isTrue,
          reason: 'Storage name "$name" must be a valid tier key',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip: level → tier → storage name
  // -------------------------------------------------------------------------

  test('full round-trip: level 1 → beginner → "beginner"', () {
    final tier = coachingTierFromComputedLevel(1);
    expect(coachingTierStorageName(tier), 'beginner');
  });

  test('full round-trip: level 3 → intermediate → "intermediate"', () {
    final tier = coachingTierFromComputedLevel(3);
    expect(coachingTierStorageName(tier), 'intermediate');
  });

  test('full round-trip: level 5 → advanced → "advanced"', () {
    final tier = coachingTierFromComputedLevel(5);
    expect(coachingTierStorageName(tier), 'advanced');
  });
}
