import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_sentence_specs.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

void main() {
  // In-memory sentence library for all tests.
  final lib = SentenceLibrary.fromJson({
    's001': {'text': 'Brace hard.', 'variants': ['mid', 'final']},
    's002': {'text': 'Keep your chest up.', 'variants': ['mid', 'final']},
    's003': {'text': 'Full range of motion.', 'variants': ['mid', 'final']},
    's-issue': {
      'text': 'Your knees may be caving.',
      'variants': ['mid']
    },
    's-fix-a': {
      'text': 'Push your knees out.',
      'variants': ['final']
    },
    's-fix-b': {
      'text': 'Drive through your heels.',
      'variants': ['final']
    },
  });

  // -------------------------------------------------------------------------
  // audioSpecsForCueField
  // -------------------------------------------------------------------------

  group('audioSpecsForCueField', () {
    test('beginner tier with 3 sentences: mid, mid, final intonation', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001', 's002', 's003'],
        'tiers': {
          'beginner': [0, 1, 2],
          'intermediate': [0],
          'advanced': [0],
        },
      });

      final specs =
          audioSpecsForCueField(field: field, tier: CoachingAudioTier.beginner, sentences: lib);

      expect(specs, hasLength(3));
      expect(specs[0].sentenceId, 's001');
      expect(specs[0].variant, 'mid');
      expect(specs[1].sentenceId, 's002');
      expect(specs[1].variant, 'mid');
      expect(specs[2].sentenceId, 's003');
      expect(specs[2].variant, 'final');
    });

    test('intermediate tier selects only the subset specified', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001', 's002', 's003'],
        'tiers': {
          'beginner': [0, 1, 2],
          'intermediate': [0, 2], // skips s002
          'advanced': [0],
        },
      });

      final specs = audioSpecsForCueField(
          field: field, tier: CoachingAudioTier.intermediate, sentences: lib);

      expect(specs, hasLength(2));
      expect(specs[0].sentenceId, 's001');
      expect(specs[0].variant, 'mid');
      expect(specs[1].sentenceId, 's003');
      expect(specs[1].variant, 'final');
    });

    test('single sentence produces one spec with variant=final', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001'],
        'tiers': {
          'beginner': [0],
          'intermediate': [0],
          'advanced': [0],
        },
      });

      final specs =
          audioSpecsForCueField(field: field, tier: CoachingAudioTier.beginner, sentences: lib);

      expect(specs, hasLength(1));
      expect(specs[0].variant, 'final');
    });

    test('returns empty list when tier has no mapping for the requested tier', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001'],
        'tiers': {
          'beginner': [0],
          // intermediate and advanced keys absent
        },
      });

      final specs = audioSpecsForCueField(
          field: field, tier: CoachingAudioTier.intermediate, sentences: lib);

      expect(specs, isEmpty);
    });

    test('out-of-range index in tier mapping is silently skipped', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001'], // only index 0 valid
        'tiers': {
          'beginner': [0, 5], // index 5 is out-of-range
          'intermediate': [0],
          'advanced': [0],
        },
      });

      final specs =
          audioSpecsForCueField(field: field, tier: CoachingAudioTier.beginner, sentences: lib);

      // only index 0 is valid; index 5 is skipped
      expect(specs, hasLength(1));
      expect(specs[0].sentenceId, 's001');
    });

    test('all specs are sentence specs (isSentence=true)', () {
      final field = ExerciseCueField.fromJson({
        'sentences': ['s001', 's002'],
        'tiers': {
          'beginner': [0, 1],
          'intermediate': [0],
          'advanced': [0],
        },
      });

      final specs =
          audioSpecsForCueField(field: field, tier: CoachingAudioTier.beginner, sentences: lib);

      expect(specs.every((s) => s.isSentence), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // audioSpecsForCommonFix
  // -------------------------------------------------------------------------

  group('audioSpecsForCommonFix', () {
    ExerciseCommonFix makeFix({
      bool beginnerIssue = false,
      List<int> beginnerFix = const [0],
    }) =>
        ExerciseCommonFix.fromJson({
          'issue': 's-issue',
          'fix': ['s-fix-a'],
          'tiers': {
            'beginner': {'issue': beginnerIssue, 'fix': beginnerFix},
            'intermediate': {'issue': false, 'fix': beginnerFix},
            'advanced': {'issue': false, 'fix': beginnerFix},
          },
        });

    test('issue sentence is never spoken regardless of tier issue flag', () {
      // The issue label is shown in the coaching panel UI — audio skips it.
      for (final issueFlag in [true, false]) {
        final specs = audioSpecsForCommonFix(
          fix: makeFix(beginnerIssue: issueFlag),
          tier: CoachingAudioTier.beginner,
          sentences: lib,
        );
        expect(specs.every((s) => s.sentenceId != 's-issue'), isTrue,
            reason: 'issue flag=$issueFlag should not add issue sentence');
      }
    });

    test('fix sentence is included and has variant=final (single fix)', () {
      final specs = audioSpecsForCommonFix(
        fix: makeFix(),
        tier: CoachingAudioTier.beginner,
        sentences: lib,
      );
      expect(specs.last.sentenceId, 's-fix-a');
      expect(specs.last.variant, 'final');
    });

    test('multiple fix sentences: all but last have variant=mid', () {
      // Use sentences that have both mid+final so pickVariant works as expected.
      final fix = ExerciseCommonFix.fromJson({
        'issue': '',
        'fix': ['s001', 's002'], // both have mid+final in the mock lib
        'tiers': {
          'beginner': {'issue': false, 'fix': [0, 1]},
          'intermediate': {'issue': false, 'fix': [0, 1]},
          'advanced': {'issue': false, 'fix': [0, 1]},
        },
      });

      final specs = audioSpecsForCommonFix(
          fix: fix, tier: CoachingAudioTier.beginner, sentences: lib);

      expect(specs, hasLength(2));
      expect(specs[0].variant, 'mid');
      expect(specs[1].variant, 'final');
    });

    test('returns empty when tier mapping is absent', () {
      final fix = ExerciseCommonFix.fromJson({
        'issue': 's-issue',
        'fix': ['s-fix-a'],
        'tiers': {
          // only beginner defined
          'beginner': {'issue': false, 'fix': [0]},
        },
      });

      final specs = audioSpecsForCommonFix(
          fix: fix, tier: CoachingAudioTier.advanced, sentences: lib);

      expect(specs, isEmpty);
    });
  });
}
