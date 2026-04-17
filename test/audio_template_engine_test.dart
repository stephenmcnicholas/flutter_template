import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_template_engine.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// A minimal SentenceLibrary that has mid+final variants for all IDs used
/// in the inline instruction fixtures below. No rootBundle needed.
final _mockLib = SentenceLibrary.fromJson({
  's-setup-1': {
    'text': 'Stand tall and brace.',
    'variants': ['mid', 'final']
  },
  's-setup-2': {
    'text': 'Brace your core hard.',
    'variants': ['mid', 'final']
  },
  's-form-1': {
    'text': 'Good form feels like tension.',
    'variants': ['mid', 'final']
  },
  's-issue-1': {
    'text': 'Your lower back may be rounding.',
    'variants': ['mid']
  },
  's-fix-1': {'text': 'Push your knees out.', 'variants': ['final']},
  's-fix-2': {'text': 'Drive through your heels.', 'variants': ['final']},
});

ExerciseInstructions _instructionsWithForm() => ExerciseInstructions.fromJson({
      'setup': {
        'sentences': ['s-setup-1', 's-setup-2'],
        'tiers': {
          'beginner': [0, 1],
          'intermediate': [0],
          'advanced': [0],
        },
      },
      'movement': {
        'sentences': ['s-setup-1'],
        'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
      },
      'goodFormFeels': {
        'sentences': ['s-form-1'],
        'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
      },
      'commonFixes': [
        {
          'issue': 's-issue-1',
          'fix': ['s-fix-1'],
          'tiers': {
            'beginner': {'issue': true, 'fix': [0]},
            'intermediate': {'issue': false, 'fix': [0]},
            'advanced': {'issue': false, 'fix': [0]},
          },
        },
        {
          'issue': '',
          'fix': ['s-fix-2'],
          'tiers': {
            'beginner': {'issue': false, 'fix': [0]},
            'intermediate': {'issue': false, 'fix': [0]},
            'advanced': {'issue': false, 'fix': [0]},
          },
        },
      ],
      'makeItEasier': <dynamic>[],
      'breathingCue': null,
    });

ExerciseInstructions _instructionsNoForm() => ExerciseInstructions.fromJson({
      'setup': {
        'sentences': ['s-setup-1'],
        'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
      },
      'movement': {
        'sentences': ['s-setup-1'],
        'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
      },
      'goodFormFeels': null,
      'commonFixes': <dynamic>[],
      'makeItEasier': <dynamic>[],
      'breathingCue': null,
    });

// ---------------------------------------------------------------------------
// Fixtures used by the existing template 2 test (retained verbatim)
// ---------------------------------------------------------------------------

final _barbellBackSquatInstructions = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s0001', 's0002', 's0003'],
    'tiers': {
      'beginner': [0, 1, 2],
      'intermediate': [0, 1],
      'advanced': [0],
    },
  },
  'movement': {
    'sentences': ['s0004'],
    'tiers': {
      'beginner': [0],
      'intermediate': [0],
      'advanced': [0],
    },
  },
  'goodFormFeels': null,
  'commonFixes': <dynamic>[],
  'makeItEasier': <dynamic>[],
  'breathingCue': {
    'sentences': ['s0008'],
    'tiers': {
      'beginner': [0],
      'intermediate': [0],
      'advanced': [0],
    },
  },
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = AudioTemplateEngine();

  // -------------------------------------------------------------------------
  // Template 2 (existing test — preserved)
  // -------------------------------------------------------------------------

  test(
    'template2FirstExerciseSetup barbell-back-squat + beginner: '
    'setup s0001–s0003 mid/mid/final in order',
    () async {
      final sentences = await SentenceLibrary.loadFromAssets(rootBundle);
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'barbell-back-squat',
        instructions: _barbellBackSquatInstructions,
        tier: CoachingAudioTier.beginner,
        sentences: sentences,
      );

      final sentenceSpecs = specs.where((s) => s.isSentence).toList();
      expect(sentenceSpecs.length, greaterThanOrEqualTo(3));
      expect(sentenceSpecs[0].sentenceId, 's0001');
      expect(sentenceSpecs[0].variant, 'mid');
      expect(sentenceSpecs[1].sentenceId, 's0002');
      expect(sentenceSpecs[1].variant, 'mid');
      expect(sentenceSpecs[2].sentenceId, 's0003');
      expect(sentenceSpecs[2].variant, 'final');
    },
  );

  // -------------------------------------------------------------------------
  // Template 1 — workout intro
  // -------------------------------------------------------------------------

  group('template1WorkoutIntro', () {
    test('without workoutId produces exactly 3 modular clips', () {
      final specs = engine.template1WorkoutIntro(
        exerciseCount: 3,
        durationMinutes: 45,
      );
      expect(specs, hasLength(3));
      expect(specs.every((s) => s.isModular), isTrue);
    });

    test('with workoutId adds a workoutIntro clip as the first element', () {
      final specs = engine.template1WorkoutIntro(
        workoutId: 'workout-abc',
        exerciseCount: 3,
        durationMinutes: 45,
      );
      expect(specs, hasLength(4));
      expect(specs.first.isWorkoutIntro, isTrue);
      expect(specs.first.workoutId, 'workout-abc');
      expect(specs.skip(1).every((s) => s.isModular), isTrue);
    });

    group('exercise count clip ids', () {
      for (final tc in [
        (count: 1, expected: 'count_one_exercise'),
        (count: 2, expected: 'count_two_exercises'),
        (count: 4, expected: 'count_four_exercises'),
        (count: 6, expected: 'count_six_exercises'),
        (count: 7, expected: 'count_seven_exercises'),
        (count: 10, expected: 'count_ten_exercises'),
      ]) {
        test('count ${tc.count} → ${tc.expected}', () {
          final specs = engine.template1WorkoutIntro(
            exerciseCount: tc.count,
            durationMinutes: 30,
          );
          // exercise count clip is always the first modular clip (index 0 without workoutId)
          expect(specs[0].modularId, tc.expected);
        });
      }
    });

    group('duration clip ids', () {
      for (final tc in [
        (minutes: 15, expected: 'duration_15min'),
        (minutes: 20, expected: 'duration_15min'),
        (minutes: 21, expected: 'duration_30min'),
        (minutes: 37, expected: 'duration_30min'),
        (minutes: 38, expected: 'duration_45min'),
        (minutes: 52, expected: 'duration_45min'),
        (minutes: 53, expected: 'duration_60min'),
        (minutes: 67, expected: 'duration_60min'),
        (minutes: 68, expected: 'duration_75min'),
        (minutes: 82, expected: 'duration_75min'),
        (minutes: 83, expected: 'duration_90min'),
        (minutes: 120, expected: 'duration_90min'),
      ]) {
        test('${tc.minutes} min → ${tc.expected}', () {
          final specs = engine.template1WorkoutIntro(
            exerciseCount: 3,
            durationMinutes: tc.minutes,
          );
          // duration clip is always second modular clip (index 1 without workoutId)
          expect(specs[1].modularId, tc.expected);
        });
      }
    });

    test('last clip is from workout_bookends category', () {
      final specs = engine.template1WorkoutIntro(
        exerciseCount: 3,
        durationMinutes: 45,
      );
      expect(specs.last.category, 'workout_bookends');
    });
  });

  // -------------------------------------------------------------------------
  // Template 4 — same exercise next set
  // -------------------------------------------------------------------------

  group('template4SameExerciseNextSet', () {
    test('final set produces 1 clip (encouragement only)', () {
      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: true,
        currentSetWeight: 100,
        nextSetProgrammedWeight: null,
      );
      expect(specs, hasLength(1));
      expect(specs[0].category, 'encouragement');
    });

    test('non-final set produces 2 clips', () {
      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: false,
        currentSetWeight: 80,
        nextSetProgrammedWeight: 80,
      );
      expect(specs, hasLength(2));
    });

    group('weight direction clip', () {
      test('next > current → weight_increase', () {
        final specs = engine.template4SameExerciseNextSet(
          isFinalSetOfExercise: false,
          currentSetWeight: 80,
          nextSetProgrammedWeight: 90,
        );
        expect(specs[1].modularId, 'weight_increase');
      });

      test('next < current → weight_decrease', () {
        final specs = engine.template4SameExerciseNextSet(
          isFinalSetOfExercise: false,
          currentSetWeight: 100,
          nextSetProgrammedWeight: 80,
        );
        expect(specs[1].modularId, 'weight_decrease');
      });

      test('next == current → weight_same', () {
        final specs = engine.template4SameExerciseNextSet(
          isFinalSetOfExercise: false,
          currentSetWeight: 80,
          nextSetProgrammedWeight: 80,
        );
        expect(specs[1].modularId, 'weight_same');
      });

      test('null weights → weight_same', () {
        final specs = engine.template4SameExerciseNextSet(
          isFinalSetOfExercise: false,
          currentSetWeight: null,
          nextSetProgrammedWeight: null,
        );
        expect(specs[1].modularId, 'weight_same');
      });
    });

  });

  // -------------------------------------------------------------------------
  // Template 6 — on-demand good form
  // -------------------------------------------------------------------------

  group('template6OnDemandGoodForm', () {
    test('returns empty list when goodFormFeels is null', () {
      final specs = engine.template6OnDemandGoodForm(
        instructions: _instructionsNoForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
      );
      expect(specs, isEmpty);
    });

    test('returns sentence specs when goodFormFeels is present', () {
      final specs = engine.template6OnDemandGoodForm(
        instructions: _instructionsWithForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
      );
      expect(specs, isNotEmpty);
      expect(specs.every((s) => s.isSentence), isTrue);
    });

    test('last spec has variant=final', () {
      final specs = engine.template6OnDemandGoodForm(
        instructions: _instructionsWithForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
      );
      expect(specs.last.variant, 'final');
    });
  });

  // -------------------------------------------------------------------------
  // Template 7 — on-demand common fix 1
  // -------------------------------------------------------------------------

  group('template7OnDemandCommonFix1', () {
    test('returns empty list when there are no common fixes', () {
      final specs = engine.template7OnDemandCommonFix1(
        instructions: _instructionsNoForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
      );
      expect(specs, isEmpty);
    });

    test('returns specs for the first fix when fixes exist', () {
      final specs = engine.template7OnDemandCommonFix1(
        instructions: _instructionsWithForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
      );
      expect(specs, isNotEmpty);
    });

    test('issue sentence is never spoken (issue label shown in UI, not audio)', () {
      // beginner has issue=true in data, but audio should still skip it
      for (final tier in [CoachingAudioTier.beginner, CoachingAudioTier.intermediate]) {
        final specs = engine.template7OnDemandCommonFix1(
          instructions: _instructionsWithForm(),
          tier: tier,
          sentences: _mockLib,
        );
        expect(specs.every((s) => s.sentenceId != 's-issue-1'), isTrue,
            reason: 'tier=$tier should not include issue sentence');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Template 8 — on-demand common fix 2 (or replay fix 1)
  // -------------------------------------------------------------------------

  group('template8OnDemandCommonFix2', () {
    test('returns empty list when there are no common fixes', () {
      final specs = engine.template8OnDemandCommonFix2(
        instructions: _instructionsNoForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
        hasFix2: true,
      );
      expect(specs, isEmpty);
    });

    test('hasFix2=true + 2 fixes available → uses second fix sentences', () {
      final specs = engine.template8OnDemandCommonFix2(
        instructions: _instructionsWithForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
        hasFix2: true,
      );
      expect(specs, isNotEmpty);
      // second fix has only s-fix-2
      expect(specs.any((s) => s.sentenceId == 's-fix-2'), isTrue);
    });

    test('hasFix2=false → replays first fix sentences', () {
      final specs = engine.template8OnDemandCommonFix2(
        instructions: _instructionsWithForm(),
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
        hasFix2: false,
      );
      expect(specs, isNotEmpty);
      // first fix sentences include s-fix-1
      expect(specs.any((s) => s.sentenceId == 's-fix-1'), isTrue);
    });

    test('hasFix2=true but only 1 fix → falls back to first fix', () {
      // Build instructions with only one common fix
      final oneFixInstructions = ExerciseInstructions.fromJson({
        'setup': {
          'sentences': ['s-setup-1'],
          'tiers': {
            'beginner': [0],
            'intermediate': [0],
            'advanced': [0]
          },
        },
        'movement': {
          'sentences': ['s-setup-1'],
          'tiers': {
            'beginner': [0],
            'intermediate': [0],
            'advanced': [0]
          },
        },
        'goodFormFeels': null,
        'commonFixes': [
          {
            'issue': '',
            'fix': ['s-fix-1'],
            'tiers': {
              'beginner': {'issue': false, 'fix': [0]},
              'intermediate': {'issue': false, 'fix': [0]},
              'advanced': {'issue': false, 'fix': [0]},
            },
          }
        ],
        'makeItEasier': <dynamic>[],
        'breathingCue': null,
      });
      final specs = engine.template8OnDemandCommonFix2(
        instructions: oneFixInstructions,
        tier: CoachingAudioTier.beginner,
        sentences: _mockLib,
        hasFix2: true,
      );
      expect(specs.any((s) => s.sentenceId == 's-fix-1'), isTrue);
    });
  });
}
