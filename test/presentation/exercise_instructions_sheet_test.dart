import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/presentation/logger/exercise_instructions_sheet.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ExerciseInstructionsSheet shows empty state when no instructions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseInstructionsProvider.overrideWith((ref, id) async => null),
          sentenceLibraryProvider.overrideWith((ref) async => SentenceLibrary.empty()),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(
            body: SizedBox(
              height: 600,
              child: ExerciseInstructionsSheet(exerciseId: 'x'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No instructions for this exercise.'), findsOneWidget);
  });

  testWidgets('ExerciseInstructionsSheet shows error when instructions provider fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseInstructionsProvider.overrideWith(
            (ref, id) async => throw Exception('boom'),
          ),
          sentenceLibraryProvider.overrideWith((ref) async => SentenceLibrary.empty()),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(
            body: SizedBox(
              height: 600,
              child: ExerciseInstructionsSheet(exerciseId: 'x'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Could not load instructions.'), findsOneWidget);
  });

  testWidgets('buildExerciseInstructionsSheetBody renders setup section', (tester) async {
    final instructions = ExerciseInstructions.fromJson({
      'setup': {
        'sentences': ['s1'],
        'tiers': {
          'beginner': [0],
        },
      },
      'movement': {
        'sentences': <String>[],
        'tiers': <String, dynamic>{},
      },
      'commonFixes': <dynamic>[],
      'makeItEasier': <dynamic>[],
    });
    final lib = SentenceLibrary.fromJsonString('''
      {
        "s1": { "text": "Step one", "variants": ["mid"] }
      }
    ''');

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => SingleChildScrollView(
              child: buildExerciseInstructionsSheetBody(ctx, instructions, lib),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Setup'), findsOneWidget);
    expect(find.textContaining('Step one'), findsWidgets);
  });
}

