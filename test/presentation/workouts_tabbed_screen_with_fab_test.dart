import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/workout/workouts_tabbed_screen_with_fab.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('WorkoutsTabbedScreenWithFab renders and shows tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredSortedWorkoutSessionsProvider.overrideWith((ref) => const AsyncValue.data([])),
          exercisesFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: DefaultTabController(
            length: 2,
            child: WorkoutsTabbedScreenWithFab(
              onQuickstart: (name, {initialExercises = const [], initialSetsByExercise}) {},
              builder: (body, fab) => Scaffold(
                appBar: AppBar(
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'History'),
                      Tab(text: 'Templates'),
                    ],
                  ),
                ),
                body: body,
                floatingActionButton: fab,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('WorkoutsTabbedScreenWithFab updates tab index on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredSortedWorkoutSessionsProvider.overrideWith((ref) => const AsyncValue.data([])),
          exercisesFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: DefaultTabController(
            length: 2,
            child: WorkoutsTabbedScreenWithFab(
              onQuickstart: (name, {initialExercises = const [], initialSetsByExercise}) {},
              builder: (body, fab) => Scaffold(
                appBar: AppBar(
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'History'),
                      Tab(text: 'Templates'),
                    ],
                  ),
                ),
                body: body,
                floatingActionButton: fab,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    final tabController = DefaultTabController.of(tester.element(find.byType(TabBar)));
    expect(tabController.index, 0);

    await tester.tap(find.text('Templates'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tabController.index, 1);
  });
} 