import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';

void main() {
  test('ExerciseInstructionLink.fromJson handles optional exerciseId', () {
    final link = ExerciseInstructionLink.fromJson({
      'name': 'Alt',
      'description': 'Alt desc',
    });
    expect(link.name, 'Alt');
    expect(link.description, 'Alt desc');
    expect(link.exerciseId, isNull);
  });

  test('ExerciseInstructionLevelUp.fromJson handles defaults', () {
    final levelUp = ExerciseInstructionLevelUp.fromJson({});
    expect(levelUp.description, isEmpty);
    expect(levelUp.exerciseId, isNull);
  });

  test('ExerciseInstructions.fromJson parses sentence-based fields', () {
    final instructions = ExerciseInstructions.fromJson({
      'setup': {
        'sentences': ['s0001'],
        'tiers': {
          'beginner': [0],
          'intermediate': [0],
          'advanced': [0],
        },
      },
      'movement': {
        'sentences': ['s0002'],
        'tiers': {
          'beginner': [0],
          'intermediate': [0],
          'advanced': [0],
        },
      },
      'goodFormFeels': {
        'sentences': ['s0003'],
        'tiers': {
          'beginner': [0],
          'intermediate': [0],
          'advanced': null,
        },
      },
      'commonFixes': [
        {
          'issue': 's0010',
          'fix': ['s0011'],
          'tiers': {
            'beginner': {'issue': true, 'fix': [0]},
            'intermediate': {'issue': true, 'fix': [0]},
            'advanced': {'issue': false, 'fix': [0]},
          },
        },
      ],
      'makeItEasier': [
        {'name': 'Alt', 'description': 'Alt desc'}
      ],
      'levelUp': {'description': 'Level', 'exerciseId': 'lvl'},
      'breathingCue': {
        'sentences': ['s0004'],
        'tiers': {
          'beginner': [0],
          'intermediate': [0],
          'advanced': [0],
        },
      },
      'safetyNote': 'Safe',
    });

    expect(instructions.setup.sentences, ['s0001']);
    expect(instructions.movement.sentences, ['s0002']);
    expect(instructions.goodFormFeels?.tiers['advanced'], isNull);
    expect(instructions.commonFixes.first.issue, 's0010');
    expect(instructions.commonFixes.first.fix, ['s0011']);
    expect(instructions.makeItEasier.first.name, 'Alt');
    expect(instructions.levelUp?.exerciseId, 'lvl');
    expect(instructions.breathingCue?.sentences, ['s0004']);
    expect(instructions.safetyNote, 'Safe');
  });

  test('ExerciseInstructions.fromJson handles missing cue fields', () {
    final instructions = ExerciseInstructions.fromJson({});
    expect(instructions.setup.sentences, isEmpty);
    expect(instructions.movement.sentences, isEmpty);
    expect(instructions.commonFixes, isEmpty);
    expect(instructions.makeItEasier, isEmpty);
    expect(instructions.levelUp, isNull);
  });

  test('ExerciseInstructions.fromJson tolerates string where list expected', () {
    final instructions = ExerciseInstructions.fromJson({
      'setup': {
        'sentences': 's0001',
        'tiers': {},
      },
      'movement': {
        'sentences': ['s0002'],
        'tiers': {},
      },
      'commonFixes': [
        {
          'issue': 's0010',
          'fix': 's0011',
          'tiers': {},
        },
      ],
      'makeItEasier': [],
    });
    expect(instructions.setup.sentences, ['s0001']);
    expect(instructions.commonFixes.first.fix, ['s0011']);
  });

  test('ExerciseInstructions.fromJson tolerates non-list makeItEasier/commonFixes', () {
    final instructions = ExerciseInstructions.fromJson({
      'setup': {'sentences': [], 'tiers': {}},
      'movement': {'sentences': [], 'tiers': {}},
      'commonFixes': 'not-a-list',
      'makeItEasier': 'not-a-list',
    });
    expect(instructions.commonFixes, isEmpty);
    expect(instructions.makeItEasier, isEmpty);
  });
}
