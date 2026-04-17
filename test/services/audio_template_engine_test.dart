import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/audio/audio_template_engine.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

// Minimal sentence library.
final _lib = SentenceLibrary.fromJson({
  's001': {'text': 'Stand tall.', 'variants': ['mid', 'final']},
  's002': {'text': 'Brace your core.', 'variants': ['mid', 'final']},
  's003': {'text': 'Breathe in.', 'variants': ['mid', 'final']},
});

// Instructions with setup (2 sentences), movement (1 sentence), breathing (1 sentence).
final _instr = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s001', 's002'],
    'tiers': {'beginner': [0, 1], 'intermediate': [0], 'advanced': [0]},
  },
  'movement': {
    'sentences': ['s001'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'breathingCue': {
    'sentences': ['s003'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
});

// Instructions without breathing cue.
final _instrNoBreathing = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s001'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'movement': {
    'sentences': ['s001'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
});

void main() {
  final engine = AudioTemplateEngine();

  // -----------------------------------------------------------------------
  // T4 — set complete
  // -----------------------------------------------------------------------

  group('template4SameExerciseNextSet', () {
    test('non-final set: returns exactly 2 clips (encouragement + weight direction)', () {
      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: false,
        currentSetWeight: 100.0,
        nextSetProgrammedWeight: 110.0,
      );
      expect(specs, hasLength(2));
      expect(specs[0].isModular, isTrue); // encouragement
      expect(specs[1].isModular, isTrue); // weight direction
    });

    test('final set: returns exactly 1 clip (encouragement only)', () {
      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: true,
        currentSetWeight: 100.0,
        nextSetProgrammedWeight: null,
      );
      expect(specs, hasLength(1));
      expect(specs[0].isModular, isTrue);
    });

    test('no after_your_rest clip in any T4 output', () {
      final nonFinal = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: false,
        currentSetWeight: 100.0,
        nextSetProgrammedWeight: 100.0,
      );
      final final_ = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: true,
        currentSetWeight: null,
        nextSetProgrammedWeight: null,
      );
      expect(nonFinal.any((s) => s.modularId == 'after_your_rest'), isFalse);
      expect(final_.any((s) => s.modularId == 'after_your_rest'), isFalse);
    });

    test('no set-sequencing clips in any T4 output', () {
      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: false,
        currentSetWeight: 50.0,
        nextSetProgrammedWeight: 60.0,
      );
      const setSeqIds = [
        'its_your_second_set', 'its_your_third_set', 'its_your_fourth_set',
        'its_your_fifth_set', 'its_your_sixth_set', 'its_the_last_set',
      ];
      expect(specs.any((s) => setSeqIds.contains(s.modularId)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // T2 — first exercise setup
  // -----------------------------------------------------------------------

  group('template2FirstExerciseSetup', () {
    test('includes movement sentences', () {
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'e1',
        instructions: _instr,
        tier: CoachingAudioTier.beginner,
        sentences: _lib,
      );
      expect(specs.any((s) => s.isSentence), isTrue,
          reason: 'T2 must include sentence specs (setup + movement)');
    });

    test('does NOT include breathing sentences', () {
      // _instr has a breathingCue — T2 must not play it
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'e1',
        instructions: _instr,
        tier: CoachingAudioTier.beginner,
        sentences: _lib,
      );
      // s003 is the breathing sentence — confirm it's absent
      expect(specs.any((s) => s.sentenceId == 's003'), isFalse,
          reason: 'T2 must not include breathing cue (it plays on 2nd+ sets via T5)');
    });

    test('ends with connective_when_ready modular clip', () {
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'e1',
        instructions: _instr,
        tier: CoachingAudioTier.beginner,
        sentences: _lib,
      );
      expect(specs.last.isModular, isTrue);
      expect(specs.last.modularId, 'connective_when_ready');
    });

    test('contains exercise_names clip for the exercise', () {
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'e1',
        instructions: _instr,
        tier: CoachingAudioTier.beginner,
        sentences: _lib,
      );
      expect(
        specs.any((s) => s.isModular && s.category == 'exercise_names' && s.modularId == 'e1'),
        isTrue,
      );
    });

    test('works when instructions have no breathingCue', () {
      final specs = engine.template2FirstExerciseSetup(
        exerciseId: 'e1',
        instructions: _instrNoBreathing,
        tier: CoachingAudioTier.beginner,
        sentences: _lib,
      );
      // Should still return a sequence ending with connective_when_ready
      expect(specs.last.isModular, isTrue);
      expect(specs.last.modularId, 'connective_when_ready');
      // Should contain sentence specs from setup + movement
      expect(specs.any((s) => s.isSentence), isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // T3a — exercise transition teaser (fires at rest start)
  // -----------------------------------------------------------------------

  group('template3aExerciseTeaser', () {
    test('returns exactly 3 modular clips', () {
      final specs = engine.template3aExerciseTeaser(exerciseId: 'e2');
      expect(specs, hasLength(3));
      expect(specs.every((s) => s.isModular), isTrue);
    });

    test('first clip is connective_take_rest', () {
      final specs = engine.template3aExerciseTeaser(exerciseId: 'e2');
      expect(specs[0].modularId, 'connective_take_rest');
    });

    test('second clip is transition_next_up', () {
      final specs = engine.template3aExerciseTeaser(exerciseId: 'e2');
      expect(specs[1].modularId, 'transition_next_up');
    });

    test('third clip is the exercise name in exercise_names category', () {
      final specs = engine.template3aExerciseTeaser(exerciseId: 'e2');
      expect(specs[2].category, 'exercise_names');
      expect(specs[2].modularId, 'e2');
    });
  });

  // -----------------------------------------------------------------------
  // T5 — rest-end notification
  // -----------------------------------------------------------------------

  group('template5RestEnd', () {
    test('isFirstSetOfExercise=true returns T3b: name + setup + movement + connective_when_ready', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 1,
        isFirstSetOfExercise: true,
        isLastSetOfExercise: false,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.first.isModular && specs.first.modularId == 'e1', isTrue);
      expect(specs.any((s) => s.isSentence), isTrue);
      expect(specs.last.isModular && specs.last.modularId == 'connective_when_ready', isTrue);
      expect(specs.any((s) => s.modularId == 'connective_lets_go'), isFalse);
    });

    test('isFirstSetOfExercise=true AND isLastSetOfExercise=true still returns T3b (single-set exercise)', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 1,
        isFirstSetOfExercise: true,
        isLastSetOfExercise: true,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.last.modularId, 'connective_when_ready');
      expect(specs.any((s) => s.modularId == 'its_the_last_set'), isFalse);
    });

    test('isLastSetOfExercise=true returns its_the_last_set clip', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 3,
        isFirstSetOfExercise: false,
        isLastSetOfExercise: true,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.any((s) => s.modularId == 'its_the_last_set'), isTrue);
      expect(specs.last.modularId, 'connective_lets_go');
    });

    test('2nd set returns its_your_second_set', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 2,
        isFirstSetOfExercise: false,
        isLastSetOfExercise: false,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.any((s) => s.modularId == 'its_your_second_set'), isTrue);
      expect(specs.last.modularId, 'connective_lets_go');
    });

    test('7th+ set returns next_set', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 7,
        isFirstSetOfExercise: false,
        isLastSetOfExercise: false,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.any((s) => s.modularId == 'next_set'), isTrue);
    });

    test('same-exercise sets include breathing sentence when breathingCue is set', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 2,
        isFirstSetOfExercise: false,
        isLastSetOfExercise: false,
        instructions: _instr,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.any((s) => s.sentenceId == 's003'), isTrue,
          reason: 'T5 same-exercise sets should include breathing sentence');
    });

    test('same-exercise sets skip breathing when breathingCue is null', () {
      final specs = engine.template5RestEnd(
        exerciseId: 'e1',
        setIndex1Based: 2,
        isFirstSetOfExercise: false,
        isLastSetOfExercise: false,
        instructions: _instrNoBreathing,
        sentences: _lib,
        tier: CoachingAudioTier.beginner,
      );
      expect(specs.every((s) => s.isModular), isTrue);
    });

    test('no short_* clips appear in any T5 output', () {
      const shortIds = [
        'short_second_set', 'short_third_set', 'short_fourth_set',
        'short_fifth_set', 'short_sixth_set',
      ];
      for (final set in [2, 3, 4, 5, 6]) {
        final specs = engine.template5RestEnd(
          exerciseId: 'e1',
          setIndex1Based: set,
          isFirstSetOfExercise: false,
          isLastSetOfExercise: false,
          instructions: _instr,
          sentences: _lib,
          tier: CoachingAudioTier.beginner,
        );
        expect(specs.any((s) => shortIds.contains(s.modularId)), isFalse,
            reason: 'short_* clips are orphaned and must not appear in T5');
      }
    });
  });
}
