import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
//import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  
  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  testWidgets('WorkoutTemplatesScreen renders and shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) => Future.value(<Workout>[])),
          exercisesFutureProvider.overrideWith((ref) => Future.value(<Exercise>[])),
          exerciseMusclesMapProvider.overrideWith((ref) => Future.value(<String, List<String>>{})),
          workoutTemplateFilterTextProvider.overrideWith((ref) => ''),
          workoutTemplateBodyPartFilterProvider.overrideWith((ref) => []),
          workoutTemplateEquipmentFilterProvider.overrideWith((ref) => []),
          workoutTemplateSortOrderProvider.overrideWith((ref) => WorkoutTemplateSortOrder.nameAsc),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const WorkoutTemplatesScreen(),
          ),
        ),
      ),
    );
    await pumpForUi(tester);
    expect(find.text('No templates yet'), findsOneWidget);
  });

  testWidgets('WorkoutTemplatesScreen displays workout templates', (WidgetTester tester) async {
    final workouts = [
      Workout(
        id: 'w1',
        name: 'Push Day',
        entries: [
          WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false),
        ],
      ),
      Workout(
        id: 'w2',
        name: 'Pull Day',
        entries: [
          WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false),
          WorkoutEntry(id: 'e3', exerciseId: 'ex3', reps: 12, weight: 60, isComplete: false),
        ],
      ),
    ];

    final exercises = [
      const Exercise(id: 'ex1', name: 'Bench Press', description: ''),
      const Exercise(id: 'ex2', name: 'Pull Up', description: ''),
      const Exercise(id: 'ex3', name: 'Row', description: ''),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) async => workouts),
          exercisesFutureProvider.overrideWith((ref) async => exercises),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutTemplateFilterTextProvider.overrideWith((ref) => ''),
          workoutTemplateBodyPartFilterProvider.overrideWith((ref) => []),
          workoutTemplateEquipmentFilterProvider.overrideWith((ref) => []),
          workoutTemplateSortOrderProvider.overrideWith((ref) => WorkoutTemplateSortOrder.nameAsc),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const WorkoutTemplatesScreen(),
          ),
        ),
      ),
    );
    
    // Let futures resolve without waiting on long animations.
    await pumpForUi(tester);

    // Verify ListView is rendered
    expect(find.byType(ListView), findsOneWidget);
    
    // Should find both workout names (AppText renders as Text)
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Pull Day'), findsOneWidget);
    
    // Should find stats labels and rows
    expect(find.text('Sets'), findsWidgets);
    expect(find.text('Exercises'), findsWidgets);
    expect(find.byType(AppStatsRow), findsNWidgets(2));
  });

  testWidgets('WorkoutTemplatesScreen shows loading indicator', (WidgetTester tester) async {
    final completer = Completer<List<Workout>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) => completer.future),
          exercisesFutureProvider.overrideWith((ref) => Future.value(<Exercise>[])),
          exerciseMusclesMapProvider.overrideWith((ref) => Future.value(<String, List<String>>{})),
          workoutTemplateFilterTextProvider.overrideWith((ref) => ''),
          workoutTemplateBodyPartFilterProvider.overrideWith((ref) => []),
          workoutTemplateEquipmentFilterProvider.overrideWith((ref) => []),
          workoutTemplateSortOrderProvider.overrideWith((ref) => WorkoutTemplateSortOrder.nameAsc),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const WorkoutTemplatesScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(AppLoadingState), findsOneWidget);
  });

  testWidgets('WorkoutTemplatesScreen shows error message', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) => Future.error('Test error')),
          exercisesFutureProvider.overrideWith((ref) => Future.value(<Exercise>[])),
          exerciseMusclesMapProvider.overrideWith((ref) => Future.value(<String, List<String>>{})),
          workoutTemplateFilterTextProvider.overrideWith((ref) => ''),
          workoutTemplateBodyPartFilterProvider.overrideWith((ref) => []),
          workoutTemplateEquipmentFilterProvider.overrideWith((ref) => []),
          workoutTemplateSortOrderProvider.overrideWith((ref) => WorkoutTemplateSortOrder.nameAsc),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const WorkoutTemplatesScreen(),
          ),
        ),
      ),
    );

    await pumpForUi(tester);
    expect(find.text('Unable to load templates'), findsOneWidget);
  });
} 