import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/progress_weekly_trend.dart';
import 'package:fytter/src/presentation/progress/workout_frequency_tab.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Override> _progressTabOverrides({
  required WorkoutFrequency frequency,
  required List<Program> programs,
  DateTime? trendReference,
}) {
  final refDay = trendReference ?? DateTime(2024, 1, 15);
  return [
    workoutFrequencyProvider.overrideWith((ref) => Future.value(frequency)),
    programsFutureProvider.overrideWith((ref) => Future.value(programs)),
    weeklyTrendProvider.overrideWith(
      (ref) async => buildWeeklyTrend(
        [],
        weekCount: kProgressWeeklyTrendWeekCount,
        referenceNow: refDay,
      ),
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  testWidgets('WorkoutFrequencyTab shows summary cards and calendar', (tester) async {
    final frequency = WorkoutFrequency(
      workoutsPerDay: {DateTime(2024, 1, 1): 2},
      totalWorkouts: 10,
      averageWorkoutsPerWeek: 2.5,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _progressTabOverrides(
          frequency: frequency,
          programs: [],
          trendReference: DateTime(2024, 1, 1),
        ),
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: WorkoutFrequencyTab(initialFocusedDay: DateTime(2024, 1, 1))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total Workouts'), findsOneWidget);
    expect(find.text('Avg/Week'), findsOneWidget);
    expect(find.byType(AppCard), findsAtLeastNWidgets(3));
    expect(find.byType(Column), findsWidgets);
    expect(find.text('null'), findsNothing);
    expect(find.text('0.5'), findsOneWidget);
  });

  testWidgets('WorkoutFrequencyTab navigates to programs for planned day', (tester) async {
    final frequency = WorkoutFrequency(
      workoutsPerDay: {},
      totalWorkouts: 0,
      averageWorkoutsPerWeek: 0.0,
    );
    final program = Program(
      id: 'p1',
      name: 'Program',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2024, 1, 10)),
      ],
    );
    final container = ProviderContainer(
      overrides: _progressTabOverrides(
        frequency: frequency,
        programs: [program],
        trendReference: DateTime(2024, 1, 10),
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: WorkoutFrequencyTab(initialFocusedDay: DateTime(2024, 1, 10))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final day = find.text('10').first;
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(container.read(selectedTabIndexProvider), 2);
    expect(container.read(programDateFilterProvider), DateTime(2024, 1, 10));
  });

  testWidgets('WorkoutFrequencyTab shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutFrequencyProvider.overrideWith((ref) => Future.error('error')),
          programsFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(body: WorkoutFrequencyTab()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Unable to load progress'), findsOneWidget);
  });

  testWidgets('WorkoutFrequencyTab shows loading state', (tester) async {
    final frequency = WorkoutFrequency(
      workoutsPerDay: {},
      totalWorkouts: 0,
      averageWorkoutsPerWeek: 0.0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _progressTabOverrides(frequency: frequency, programs: []),
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(body: WorkoutFrequencyTab()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(WorkoutFrequencyTab), findsOneWidget);
  });
} 