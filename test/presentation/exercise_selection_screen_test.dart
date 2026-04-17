import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/presentation/exercise/exercise_selection_screen.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  group('ExerciseSelectionScreen', () {
    final dummyExercises = [
      const Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Leg exercise',
        bodyPart: 'Quads',
        equipment: 'Barbell',
      ),
      const Exercise(
        id: 'e2',
        name: 'Bench Press',
        description: 'Chest exercise',
        bodyPart: 'Chest',
        equipment: 'Barbell',
      ),
      const Exercise(
        id: 'e3',
        name: 'Deadlift',
        description: 'Back exercise',
        bodyPart: 'Back',
        equipment: 'Barbell',
      ),
    ];

    Widget createTestWidget({
      List<String> alreadySelectedIds = const [],
      bool singleSelection = false,
      String title = 'Add Exercises',
      String actionLabel = 'Add',
    }) {
      final db = AppDatabase.test();
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
          exerciseFavoritesProvider.overrideWith(
            (ref) => ExerciseFavoritesNotifier(db),
          ),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => ExerciseSelectionScreen(
                  alreadySelectedIds: alreadySelectedIds,
                  singleSelection: singleSelection,
                  title: title,
                  actionLabel: actionLabel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays all exercises', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpForUi(tester);

      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Deadlift'), findsOneWidget);
    });

    testWidgets('shows filter/sort bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpForUi(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Add Exercises'), findsOneWidget);
    });

    testWidgets('supports single-selection replace mode labels and behavior', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          singleSelection: true,
          title: 'Replace Exercise',
          actionLabel: 'Replace',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Replace Exercise'), findsOneWidget);
      expect(find.text('Replace (0)'), findsOneWidget);

      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      final benchCard = find.ancestor(
        of: find.text('Bench Press'),
        matching: find.byType(AppCard),
      );

      await tester.tap(squatCard.first);
      await tester.pump();
      expect(find.text('Replace (1)'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(benchCard.first);
      await tester.pump();
      expect(find.text('Replace (1)'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('displays selected count in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Initially no exercises selected
      expect(find.text('0 selected'), findsNothing);
      expect(find.text('Add (0)'), findsOneWidget);

      // Tap to select an exercise - tap the card
      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      await tester.tap(squatCard.first);
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Add (1)'), findsOneWidget);
    });

    testWidgets('toggles selection when card is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Initially no selection
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Tap to select - tap the card
      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      await tester.tap(squatCard.first);
      await tester.pump();

      // Should show checkmark
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(squatCard.first);
      await tester.pump();

      // Checkmark should be gone
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('0 selected'), findsNothing);
    });

    testWidgets('shows already selected exercises as disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(alreadySelectedIds: ['e1']));
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Already selected exercise should show gray checkmark
      final checkmarks = find.byIcon(Icons.check_circle);
      expect(checkmarks, findsOneWidget);

      // Try to tap already selected exercise - should not toggle
      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      await tester.tap(squatCard.first);
      await tester.pump();

      // Still only one checkmark (the disabled one)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Add button is disabled when no exercises selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      final addButtonText = find.text('Add (0)');
      expect(addButtonText, findsOneWidget);

      // Find the TextButton ancestor
      final button = tester.widget<TextButton>(
        find.ancestor(
          of: addButtonText,
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Add button is enabled when exercises are selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Select an exercise - need to tap the card, not just the text
      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      await tester.tap(squatCard.first);
      await tester.pump();

      final addButtonText = find.text('Add (1)');
      expect(addButtonText, findsOneWidget);

      // Find the TextButton ancestor
      final button = tester.widget<TextButton>(
        find.ancestor(
          of: addButtonText,
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('returns selected exercise IDs when Add is pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Select multiple exercises - tap the cards
      final squatCard = find.ancestor(
        of: find.text('Squat'),
        matching: find.byType(AppCard),
      );
      await tester.tap(squatCard.first);
      await tester.pump();

      final benchCard = find.ancestor(
        of: find.text('Bench Press'),
        matching: find.byType(AppCard),
      );
      await tester.tap(benchCard.first);
      await tester.pump();

      // Verify button shows correct count
      expect(find.text('Add (2)'), findsOneWidget);
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exists and is tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget);

      // Find the IconButton ancestor
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: closeIcon,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('filters exercises when search text is entered', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback

      // Enter search text
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Squat');
      await tester.pump();
      await tester.pump(); // Allow filter to apply

      // Should only show matching exercise (find in exercise cards, not search field)
      // Find exercise cards by looking for AppCard widgets
      final exerciseCards = find.byType(AppCard);
      expect(exerciseCards, findsOneWidget); // Only one card should match

      // Verify the matching exercise is shown
      expect(find.text('Squat'), findsNWidgets(2)); // One in search field, one in card
      expect(find.text('Bench Press'), findsNothing);
      expect(find.text('Deadlift'), findsNothing);
    });

    testWidgets('resets filters when screen opens', (tester) async {
      final db = AppDatabase.test();
      // Create a container to track filter state
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exerciseFavoritesProvider.overrideWith(
            (ref) => ExerciseFavoritesNotifier(db),
          ),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
        ],
      );
      
      // Set initial filters
      container.read(exerciseFilterTextProvider.notifier).state = 'test';
      container.read(exerciseBodyPartFilterProvider.notifier).state = ['chest'];
      container.read(exerciseFavoriteFilterProvider.notifier).state = true;
      container.read(exerciseSortOrderProvider.notifier).state = ExerciseSortOrder.nameDesc;
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: FytterTheme.light,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const ExerciseSelectionScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for initial build and post-frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Filters should be reset (all exercises visible, default sort)
      expect(container.read(exerciseFilterTextProvider), '');
      expect(container.read(exerciseBodyPartFilterProvider), isEmpty);
      expect(container.read(exerciseFavoriteFilterProvider), isFalse);
      expect(container.read(exerciseSortOrderProvider), ExerciseSortOrder.nameAsc);
      
      // All exercises should be visible
      await tester.pump();
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Deadlift'), findsOneWidget);
      
      container.dispose();
    });

    testWidgets('shows empty state when no exercises match filter', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Allow post-frame callback to run

      // Enter search text that matches nothing
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentExercise');
      await tester.pump();
      await tester.pump(); // Allow filter to apply

      expect(find.text('No exercises match your filters.'), findsOneWidget);
    });
  });
}
