import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/presentation/ai_programme/about_programme_screen.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const programId = 'prog-1';

  Widget buildTestWidget({
    required Program? program,
    List<Exercise> exercises = const [],
    List<Workout> workouts = const [],
  }) {
    return ProviderScope(
      overrides: [
        programByIdProvider.overrideWith((ref, id) async => program),
        exercisesFutureProvider.overrideWith((ref) async => exercises),
        workoutTemplatesFutureProvider.overrideWith((ref) async => workouts),
        premiumStatusProvider.overrideWith((ref) async => false),
        programmeAudioStatusProvider.overrideWith((ref, id) async => const ProgrammeAudioStatus()),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: AboutProgrammeScreen(programId: programId),
      ),
    );
  }

  group('AboutProgrammeScreen', () {
    testWidgets('shows app bar with about title', (tester) async {
      final program = Program(
        id: programId,
        name: 'My Programme',
        schedule: [],
      );
      await tester.pumpWidget(buildTestWidget(program: program));
      await tester.pumpAndSettle();

      expect(find.text(AiProgrammeStrings.aboutTitle), findsOneWidget);
    });

    testWidgets('shows programme not found when program is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(program: null));
      await tester.pumpAndSettle();

      expect(find.text('Programme not found.'), findsOneWidget);
    });

    testWidgets('shows coach rationale when present', (tester) async {
      const rationale = 'This programme is built for strength and consistency.';
      final program = Program(
        id: programId,
        name: 'My Programme',
        schedule: [],
        coachRationale: rationale,
      );
      await tester.pumpWidget(buildTestWidget(program: program));
      await tester.pumpAndSettle();

      expect(find.text(AiProgrammeStrings.aboutWhyThisProgrammeTitle), findsOneWidget);
      expect(find.text(rationale), findsOneWidget);
    });

    testWidgets('shows workout breakdowns when present', (tester) async {
      const workoutBreakdownsJson = '''
        [
          {
            "workoutId": "w1",
            "briefDescription": "Lower body focus",
            "exercises": [
              {
                "exerciseId": "e1",
                "sets": 3,
                "reps": 10,
                "coachNote": "Control the descent"
              }
            ]
          }
        ]
      ''';
      final program = Program(
        id: programId,
        name: 'My Programme',
        schedule: [],
        workoutBreakdowns: workoutBreakdownsJson,
      );
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
      ];
      final workouts = [
        const Workout(id: 'w1', name: 'Leg Day', entries: []),
      ];
      await tester.pumpWidget(buildTestWidget(
        program: program,
        exercises: exercises,
        workouts: workouts,
      ));
      await tester.pumpAndSettle();

      expect(find.text(AiProgrammeStrings.aboutWorkoutBreakdownsTitle), findsOneWidget);
      expect(find.text('Leg Day'), findsOneWidget);
    });
  });
}
