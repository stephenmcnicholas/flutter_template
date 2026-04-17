import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/progress/progress_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('ProgressScreen shows all tabs and switches content', (tester) async {
    Widget buildScreen({required int initialIndex}) {
      return ProviderScope(
        overrides: [
          workoutFrequencyProvider.overrideWith((ref) => Future.value(WorkoutFrequency(workoutsPerDay: {}, totalWorkouts: 0, averageWorkoutsPerWeek: 0))),
          programStatsProvider.overrideWith((ref) => Future.value(ProgramStats(totalPrograms: 0, completionRate: 0, programCompletionStats: [], completedPrograms: 0))),
          exercisesFutureProvider.overrideWith((ref) async => []),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: DefaultTabController(
            key: ValueKey('progressTabs-$initialIndex'),
            length: 2,
            initialIndex: initialIndex,
            child: Scaffold(
              body: Column(
                children: const [
                  TabBar(
                    tabs: [
                      Tab(text: 'Workout Frequency'),
                      Tab(text: 'Program Stats'),
                    ],
                  ),
                  Expanded(child: ProgressScreen()),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildScreen(initialIndex: 0));
    await tester.pump();
    expect(find.text('Workout Frequency'), findsOneWidget);
    expect(find.text('Program Stats'), findsOneWidget);

    // Default tab is Workout Frequency
    expect(find.text('Total Workouts'), findsOneWidget);

    // Switch to Program Stats tab via rebuild
    await tester.pumpWidget(buildScreen(initialIndex: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Program Completion'), findsOneWidget);
  });
} 