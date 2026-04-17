import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/presentation/exercise/exercise_list_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('ExerciseListScreen shows seeded exercises', (tester) async {
    // Prepare fake exercise list for override
    const testData = <Exercise>[
      Exercise(id: 'e1', name: 'Squat', description: 'Compound leg exercise'),
      Exercise(id: 'e2', name: 'Bench Press', description: 'Barbell chest press'),
    ];

    final db = AppDatabase.test();

    // Pump the ExerciseListScreen directly (instead of FytterApp) so that the seeded exercises are rendered.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(db)),
          exercisesFutureProvider.overrideWith((ref) async => testData),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((ref) => ''),
          exerciseBodyPartFilterProvider.overrideWith((ref) => []),
          exerciseEquipmentFilterProvider.overrideWith((ref) => []),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exerciseSortOrderProvider.overrideWith((ref) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((ref) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((ref) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    // Let all futures and animations settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Expect that the seeded exercise names are found.
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
  });
}
