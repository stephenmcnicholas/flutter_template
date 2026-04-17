import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/presentation/ai_programme/programme_preview_screen.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ProgrammePreviewScreen shows programme name and Start button', (tester) async {
    // Use current week so heading is "Workouts this week" (deterministic).
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final program = Program(
      id: 'prog-1',
      name: 'My AI Programme',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: monday),
        ProgramWorkout(workoutId: 'w2', scheduledDate: monday.add(const Duration(days: 2))),
      ],
      weeklyProgressionNotes: 'Add weight when you hit the top of the rep range.',
    );
    final result = ProgrammeGenerationResult(program: program, usedFallback: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programmeGenerationProvider.overrideWith((ref) =>
              _TestNotifier(ref, ProgrammeGenerationSuccess(result))),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgrammePreviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My AI Programme'), findsOneWidget);
    expect(find.text(AiProgrammeStrings.acceptProgramme), findsOneWidget);
    expect(find.text(AiProgrammeStrings.makeAdjustment), findsOneWidget);
    // Heading is "Workouts this week" when first week is current week, else "Your workouts".
    expect(
      find.text(AiProgrammeStrings.workoutsThisWeek).evaluate().isNotEmpty ||
          find.text(AiProgrammeStrings.yourWorkouts).evaluate().isNotEmpty,
      true,
    );
    expect(find.text(program.weeklyProgressionNotes!), findsOneWidget);
  });

  testWidgets('ProgrammePreviewScreen shows loading when state is idle', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programmeGenerationProvider.overrideWith((ref) =>
              _TestNotifier(ref, ProgrammeGenerationIdle())),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgrammePreviewScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ProgrammePreviewScreen shows error message when state is error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programmeGenerationProvider.overrideWith((ref) =>
              _TestNotifier(ref, ProgrammeGenerationError('Something went wrong'))),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgrammePreviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}

class _TestNotifier extends ProgrammeGenerationNotifier {
  _TestNotifier(super.ref, ProgrammeGenerationState initialState) : super() {
    state = initialState;
  }
}
