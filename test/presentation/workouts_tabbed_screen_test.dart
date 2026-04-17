import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/workout/workouts_tabbed_screen.dart';
import 'package:fytter/src/presentation/history/history_list_screen.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('WorkoutsTabbedScreen shows history and templates',
      (tester) async {
    final sampleExercise = const Exercise(id: 'ex1', name: 'Bench', description: '');
    final sampleSession = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime(2024, 1, 1, 10),
      name: 'Push Day',
      notes: null,
      entries: [
        WorkoutEntry(
          id: 'we1',
          exerciseId: sampleExercise.id,
          reps: 5,
          weight: 100,
          isComplete: true,
          timestamp: DateTime(2024, 1, 1, 10, 0),
          sessionId: 's1',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exercisesFutureProvider.overrideWith((_) async => [sampleExercise]),
          workoutSessionsProvider.overrideWith((_) async => [sampleSession]),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: TabBar(
                tabs: [
                  Tab(text: 'History'),
                  Tab(text: 'Templates'),
                ],
              ),
              body: WorkoutsTabbedScreen(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HistoryListScreen), findsOneWidget);
    expect(find.byType(WorkoutTemplatesScreen), findsNothing);

    // Switch to Templates tab and ensure content builds
    await tester.tap(find.text('Templates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(WorkoutTemplatesScreen), findsOneWidget);
  });
}

