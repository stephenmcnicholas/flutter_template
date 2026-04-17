import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/presentation/logger/coaching_panel.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

final _lib = SentenceLibrary.fromJson({
  's-issue': {'text': 'Knees caving in.', 'variants': ['mid']},
  's-fix': {'text': 'Push knees out.', 'variants': ['final']},
  's-gf': {'text': 'Chest up.', 'variants': ['mid', 'final']},
});

final _instrFull = ExerciseInstructions.fromJson({
  'setup': {'sentences': [], 'tiers': {}},
  'movement': {'sentences': [], 'tiers': {}},
  'goodFormFeels': {
    'sentences': ['s-gf'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'commonFixes': [
    {
      'issue': 's-issue',
      'fix': ['s-fix'],
      'tiers': {
        'beginner': {'issue': false, 'fix': [0]},
        'intermediate': {'issue': false, 'fix': [0]},
        'advanced': {'issue': false, 'fix': [0]},
      },
    },
  ],
});

final _instrEmpty = ExerciseInstructions.fromJson({
  'setup': {'sentences': [], 'tiers': {}},
  'movement': {'sentences': [], 'tiers': {}},
});

// Sentence library extended for new cue types
final _libExtended = SentenceLibrary.fromJson({
  's-issue':  {'text': 'Knees caving in.', 'variants': ['mid']},
  's-fix':    {'text': 'Push knees out.', 'variants': ['final']},
  's-gf':     {'text': 'Chest up.', 'variants': ['mid', 'final']},
  's-setup':  {'text': 'Stand tall.', 'variants': ['mid', 'final']},
  's-move':   {'text': 'Drive through your heels.', 'variants': ['mid', 'final']},
  's-breath': {'text': 'Inhale on the way down.', 'variants': ['mid', 'final']},
});

// All six fields populated
final _instrAllCues = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s-setup'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'movement': {
    'sentences': ['s-move'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'breathingCue': {
    'sentences': ['s-breath'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'goodFormFeels': {
    'sentences': ['s-gf'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'commonFixes': [
    {
      'issue': 's-issue',
      'fix': ['s-fix'],
      'tiers': {
        'beginner': {'issue': false, 'fix': [0]},
        'intermediate': {'issue': false, 'fix': [0]},
        'advanced': {'issue': false, 'fix': [0]},
      },
    },
  ],
});

// Only setup + movement + breathing; no goodFormFeels or commonFixes
final _instrNewCuesOnly = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s-setup'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'movement': {
    'sentences': ['s-move'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
  'breathingCue': {
    'sentences': ['s-breath'],
    'tiers': {'beginner': [0], 'intermediate': [0], 'advanced': [0]},
  },
});

Widget _wrap(Widget child) => MaterialApp(
      theme: FytterTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('shows good form row when goodFormFeels is set', (tester) async {
    await tester.pumpWidget(_wrap(CoachingPanel(
      instructions: _instrFull,
      sentences: _lib,
      onGoodFormTap: () {},
    )));
    expect(find.text('Good form feels like'), findsOneWidget);
  });

  testWidgets('shows common fix issue text', (tester) async {
    await tester.pumpWidget(_wrap(CoachingPanel(
      instructions: _instrFull,
      sentences: _lib,
    )));
    expect(find.text('Knees caving in.'), findsOneWidget);
  });

  testWidgets('shows fallback text when no content', (tester) async {
    await tester.pumpWidget(_wrap(CoachingPanel(
      instructions: _instrEmpty,
      sentences: _lib,
    )));
    expect(find.text('No coaching cues available for this exercise.'), findsOneWidget);
  });

  testWidgets('tapping good form row calls callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(CoachingPanel(
      instructions: _instrFull,
      sentences: _lib,
      onGoodFormTap: () => tapped = true,
    )));
    await tester.tap(find.text('Good form feels like'));
    expect(tapped, isTrue);
  });

  testWidgets('tapping fix row calls onFix1Tap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(CoachingPanel(
      instructions: _instrFull,
      sentences: _lib,
      onFix1Tap: () => tapped = true,
    )));
    await tester.tap(find.text('Knees caving in.'));
    expect(tapped, isTrue);
  });

  group('setup / movement / breathing rows', () {
    testWidgets('shows "How to set up" row when setup sentences non-empty', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
      )));
      expect(find.text('How to set up'), findsOneWidget);
    });

    testWidgets('shows "Movement cue" row when movement sentences non-empty', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
      )));
      expect(find.text('Movement cue'), findsOneWidget);
    });

    testWidgets('shows "Breathing" row when breathingCue non-null', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
      )));
      expect(find.text('Breathing'), findsOneWidget);
    });

    testWidgets('hides "How to set up" row when setup sentences empty', (tester) async {
      // _instrFull has setup with empty sentences
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrFull,
        sentences: _lib,
      )));
      expect(find.text('How to set up'), findsNothing);
    });

    testWidgets('hides "Movement cue" row when movement sentences empty', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrFull,
        sentences: _lib,
      )));
      expect(find.text('Movement cue'), findsNothing);
    });

    testWidgets('hides "Breathing" row when breathingCue null', (tester) async {
      // _instrFull has no breathingCue
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrFull,
        sentences: _lib,
      )));
      expect(find.text('Breathing'), findsNothing);
    });

    testWidgets('shows fallback text when all fields absent (including setup/movement/breathing)', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrEmpty,
        sentences: _lib,
      )));
      expect(find.text('No coaching cues available for this exercise.'), findsOneWidget);
    });

    testWidgets('does NOT show fallback when only setup/movement/breathing present', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrNewCuesOnly,
        sentences: _libExtended,
      )));
      expect(find.text('No coaching cues available for this exercise.'), findsNothing);
    });

    testWidgets('tapping "How to set up" fires onSetupTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
        onSetupTap: () => tapped = true,
      )));
      await tester.tap(find.text('How to set up'));
      expect(tapped, isTrue);
    });

    testWidgets('tapping "Movement cue" fires onMovementTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
        onMovementTap: () => tapped = true,
      )));
      await tester.tap(find.text('Movement cue'));
      expect(tapped, isTrue);
    });

    testWidgets('tapping "Breathing" fires onBreathingTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
        onBreathingTap: () => tapped = true,
      )));
      await tester.tap(find.text('Breathing'));
      expect(tapped, isTrue);
    });

    testWidgets('new rows appear above good-form row in correct order', (tester) async {
      await tester.pumpWidget(_wrap(CoachingPanel(
        instructions: _instrAllCues,
        sentences: _libExtended,
      )));
      final setupY    = tester.getTopLeft(find.text('How to set up')).dy;
      final movementY = tester.getTopLeft(find.text('Movement cue')).dy;
      final breathY   = tester.getTopLeft(find.text('Breathing')).dy;
      final goodFormY = tester.getTopLeft(find.text('Good form feels like')).dy;
      expect(setupY < movementY, isTrue, reason: 'Setup must appear before Movement');
      expect(movementY < breathY, isTrue, reason: 'Movement must appear before Breathing');
      expect(breathY < goodFormY, isTrue, reason: 'Breathing must appear before Good form');
    });
  });
}
