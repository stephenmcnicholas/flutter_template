import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/logger/workout_logger_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/domain/workout_entry_repository.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  late _FakeWorkoutEntryRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeWorkoutEntryRepository();
  });

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        workoutEntryRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        home: WorkoutLoggerScreen(),
      ),
    );
  }

  testWidgets('initially shows only Start Workout button', (tester) async {
    await tester.pumpWidget(buildTestable());

    expect(
      find.widgetWithText(ElevatedButton, 'Start Workout'),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.add), findsNothing);
    expect(
      find.widgetWithText(ElevatedButton, 'End Workout'),
      findsNothing,
    );
  });

  testWidgets('tapping Start Workout reveals add-icon and End Workout',
      (tester) async {
    await tester.pumpWidget(buildTestable());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Workout'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'End Workout'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('tapping add-set adds exactly one ListTile', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Workout'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // There should now be exactly one ListTile in the list
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('tapping End Workout saves entry and resets UI',
      (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Workout'));
    await tester.pump(); // keep moving without waiting on long settles

    // Add a set by invoking the FAB's onPressed directly to avoid hit-test issues
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    fab.onPressed?.call();
    await tester.pump();

    // End the workout
    await tester.tap(find.widgetWithText(ElevatedButton, 'End Workout'));
    await tester.pump(); // avoid long pumpAndSettle waits

    // UI should reset to only the Start Workout button
    expect(
      find.widgetWithText(ElevatedButton, 'Start Workout'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsNothing);

    // And exactly one entry should have been saved
    final saved = await fakeRepo.findAll();
    expect(saved, hasLength(1));
  });
}

class _FakeWorkoutEntryRepository implements WorkoutEntryRepository {
  final List<WorkoutEntry> _entries = [];

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<WorkoutEntry>> findAll() async => List.unmodifiable(_entries);

  @override
  Future<List<WorkoutEntry>> findByExercise(String exerciseId) async =>
      _entries.where((e) => e.exerciseId == exerciseId).toList();

  @override
  Future<void> save(WorkoutEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _entries.add(entry);
  }
}