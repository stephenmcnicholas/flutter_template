import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_body_region.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';

// A simple in-memory mock for testing
class MockWorkoutSessionRepository implements WorkoutSessionRepository {
  final Map<String, WorkoutSession> _store = {};

  @override
  Future<List<WorkoutSession>> findAll() async {
    final sessions = _store.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  @override
  Future<WorkoutSession?> findById(String id) async {
    return _store[id];
  }

  @override
  Future<void> save(WorkoutSession session) async {
    _store[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final favoriteOverrides = <Override>[
    appDatabaseProvider.overrideWith((_) => AppDatabase.test()),
    exerciseFavoritesProvider.overrideWith(
      (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
    ),
    exerciseFavoriteFilterProvider.overrideWith((_) => false),
  ];

  group('Exercise filter and sort', () {
    test('exerciseBodyRegionChoicesProvider returns fixed coarse regions', () {
      final container = ProviderContainer(overrides: favoriteOverrides);
      final regions = container.read(exerciseBodyRegionChoicesProvider);
      expect(regions, kExerciseBodyRegionFilterOrder);
      expect(regions, contains(ExerciseBodyRegion.cardio));
    });

    test('availableEquipmentOptionsProvider uses exercise equipment', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Push-up', description: '', equipment: 'Bodyweight'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
        ],
      );

      final options = await container.read(availableEquipmentOptionsProvider.future);
      expect(options, containsAll(['Barbell', 'Bodyweight']));
    });

    test('exerciseFilterTextProvider defaults to empty string', () {
      final container = ProviderContainer();
      expect(container.read(exerciseFilterTextProvider), '');
    });

    test('exerciseSortOrderProvider defaults to frequencyDesc', () {
      final container = ProviderContainer();
      expect(container.read(exerciseSortOrderProvider), ExerciseSortOrder.frequencyDesc);
    });

    test('filteredSortedExercisesProvider filters by name', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => 'Bench'),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider filters by bodyPart', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest'),
        const Exercise(id: 'e3', name: 'Deadlift', description: '', bodyPart: 'Back'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => 'Chest'),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider filters by equipment', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Dumbbell Curl', description: '', equipment: 'Dumbbell'),
        const Exercise(id: 'e3', name: 'Leg Press', description: '', equipment: 'Machine'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => 'Dumbbell'),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Dumbbell Curl');
    });

    test('filteredSortedExercisesProvider filters by body part filter', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest'),
        const Exercise(id: 'e3', name: 'Deadlift', description: '', bodyPart: 'Back'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['chest']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider maps quads to legs region', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['legs']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Squat');
    });

    test('filteredSortedExercisesProvider includes arms when secondary muscle matches', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Push-up', description: '', bodyPart: 'Chest'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => {
                'e1': ['Chest', 'Triceps'],
                'e2': ['Chest'],
              }),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['arms']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push-up');
    });

    test('filteredSortedExercisesProvider filters by equipment filter', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Dumbbell Curl', description: '', equipment: 'Dumbbell'),
        const Exercise(id: 'e3', name: 'Leg Press', description: '', equipment: 'Machine'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseEquipmentFilterProvider.overrideWith((_) => ['Dumbbell']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Dumbbell Curl');
    });

    test('filteredSortedExercisesProvider combines text and filter filters', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest', equipment: 'Barbell'),
        const Exercise(id: 'e3', name: 'Dumbbell Fly', description: '', bodyPart: 'Chest', equipment: 'Dumbbell'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => 'Bench'),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['chest']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider combines body part and equipment filters', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest', equipment: 'Barbell'),
        const Exercise(id: 'e3', name: 'Dumbbell Fly', description: '', bodyPart: 'Chest', equipment: 'Dumbbell'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['chest']),
          exerciseEquipmentFilterProvider.overrideWith((_) => ['Barbell']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider filters by multiple body parts (OR logic)', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads'),
        const Exercise(id: 'e2', name: 'Bench Press', description: '', bodyPart: 'Chest'),
        const Exercise(id: 'e3', name: 'Deadlift', description: '', bodyPart: 'Back'),
        const Exercise(id: 'e4', name: 'Leg Press', description: '', bodyPart: 'Quads'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['legs', 'chest']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(3)); // Squat, Bench Press, Leg Press
      expect(result.value!.map((e) => e.name).toList(), containsAll(['Squat', 'Bench Press', 'Leg Press']));
      expect(result.value!.map((e) => e.name).toList(), isNot(contains('Deadlift')));
    });

    test('filteredSortedExercisesProvider filters by multiple equipment types (OR logic)', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Dumbbell Curl', description: '', equipment: 'Dumbbell'),
        const Exercise(id: 'e3', name: 'Leg Press', description: '', equipment: 'Machine'),
        const Exercise(id: 'e4', name: 'Bench Press', description: '', equipment: 'Barbell'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseEquipmentFilterProvider.overrideWith((_) => ['Barbell', 'Dumbbell']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(3)); // Squat, Dumbbell Curl, Bench Press
      expect(result.value!.map((e) => e.name).toList(), containsAll(['Squat', 'Dumbbell Curl', 'Bench Press']));
      expect(result.value!.map((e) => e.name).toList(), isNot(contains('Leg Press')));
    });

    test('filteredSortedExercisesProvider handles exercises without body part', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', bodyPart: 'Quads'),
        const Exercise(id: 'e2', name: 'Unknown Exercise', description: ''), // No body part
        const Exercise(id: 'e3', name: 'Bench Press', description: '', bodyPart: 'Chest'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => ['chest']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Bench Press');
    });

    test('filteredSortedExercisesProvider handles exercises without equipment', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: '', equipment: 'Barbell'),
        const Exercise(id: 'e2', name: 'Bodyweight Exercise', description: ''), // No equipment
        const Exercise(id: 'e3', name: 'Dumbbell Curl', description: '', equipment: 'Dumbbell'),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseEquipmentFilterProvider.overrideWith((_) => ['Dumbbell']),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Dumbbell Curl');
    });

    test('filteredSortedExercisesProvider sorts by name ascending', () async {
      final exercises = [
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value!.map((e) => e.name).toList(), ['Bench Press', 'Deadlift', 'Squat']);
    });

    test('filteredSortedExercisesProvider sorts by name descending', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameDesc),
          workoutSessionRepositoryProvider.overrideWith((_) => MockWorkoutSessionRepository()),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      expect(result.value!.map((e) => e.name).toList(), ['Squat', 'Deadlift', 'Bench Press']);
    });

    test('filteredSortedExercisesProvider sorts by frequency ascending', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      // Create sessions: e1 appears in 3 sessions, e2 in 1, e3 in 2
      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Workout 1',
        entries: [
          WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 5, weight: 100, isComplete: true),
          WorkoutEntry(id: 'entry2', exerciseId: 'e2', reps: 5, weight: 80, isComplete: true),
        ],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Workout 2',
        entries: [
          WorkoutEntry(id: 'entry3', exerciseId: 'e1', reps: 5, weight: 105, isComplete: true),
          WorkoutEntry(id: 'entry4', exerciseId: 'e3', reps: 5, weight: 150, isComplete: true),
        ],
      );
      final session3 = WorkoutSession(
        id: 's3',
        workoutId: 'w3',
        date: DateTime(2024, 1, 3),
        name: 'Workout 3',
        entries: [
          WorkoutEntry(id: 'entry5', exerciseId: 'e1', reps: 5, weight: 110, isComplete: true),
          WorkoutEntry(id: 'entry6', exerciseId: 'e3', reps: 5, weight: 155, isComplete: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((_) async => [session1, session2, session3]),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.frequencyAsc),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      // e2 (1 session), e3 (2 sessions), e1 (3 sessions) - ascending by frequency
      expect(result.value!.map((e) => e.id).toList(), ['e2', 'e3', 'e1']);
    });

    test('filteredSortedExercisesProvider sorts by frequency descending', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      // Create sessions: e1 appears in 3 sessions, e2 in 1, e3 in 2
      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Workout 1',
        entries: [
          WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 5, weight: 100, isComplete: true),
          WorkoutEntry(id: 'entry2', exerciseId: 'e2', reps: 5, weight: 80, isComplete: true),
        ],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Workout 2',
        entries: [
          WorkoutEntry(id: 'entry3', exerciseId: 'e1', reps: 5, weight: 105, isComplete: true),
          WorkoutEntry(id: 'entry4', exerciseId: 'e3', reps: 5, weight: 150, isComplete: true),
        ],
      );
      final session3 = WorkoutSession(
        id: 's3',
        workoutId: 'w3',
        date: DateTime(2024, 1, 3),
        name: 'Workout 3',
        entries: [
          WorkoutEntry(id: 'entry5', exerciseId: 'e1', reps: 5, weight: 110, isComplete: true),
          WorkoutEntry(id: 'entry6', exerciseId: 'e3', reps: 5, weight: 155, isComplete: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((_) async => [session1, session2, session3]),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.frequencyDesc),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      // e1 (3 sessions), e3 (2 sessions), e2 (1 session) - descending by frequency
      expect(result.value!.map((e) => e.id).toList(), ['e1', 'e3', 'e2']);
    });

    test('filteredSortedExercisesProvider sorts by recent ascending (oldest first)', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      // Create sessions: e1 performed on 2024-01-01, e2 on 2024-01-02, e3 on 2024-01-03
      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Workout 1',
        entries: [
          WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 5, weight: 100, isComplete: true),
        ],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Workout 2',
        entries: [
          WorkoutEntry(id: 'entry2', exerciseId: 'e2', reps: 5, weight: 80, isComplete: true),
        ],
      );
      final session3 = WorkoutSession(
        id: 's3',
        workoutId: 'w3',
        date: DateTime(2024, 1, 3),
        name: 'Workout 3',
        entries: [
          WorkoutEntry(id: 'entry3', exerciseId: 'e3', reps: 5, weight: 150, isComplete: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((_) async => [session1, session2, session3]),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.recentAsc),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      // e1 (2024-01-01), e2 (2024-01-02), e3 (2024-01-03) - oldest first
      expect(result.value!.map((e) => e.id).toList(), ['e1', 'e2', 'e3']);
    });

    test('filteredSortedExercisesProvider sorts by recent descending (newest first)', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      // Create sessions: e1 performed on 2024-01-01, e2 on 2024-01-02, e3 on 2024-01-03
      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Workout 1',
        entries: [
          WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 5, weight: 100, isComplete: true),
        ],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Workout 2',
        entries: [
          WorkoutEntry(id: 'entry2', exerciseId: 'e2', reps: 5, weight: 80, isComplete: true),
        ],
      );
      final session3 = WorkoutSession(
        id: 's3',
        workoutId: 'w3',
        date: DateTime(2024, 1, 3),
        name: 'Workout 3',
        entries: [
          WorkoutEntry(id: 'entry3', exerciseId: 'e3', reps: 5, weight: 150, isComplete: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((_) async => [session1, session2, session3]),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.recentDesc),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      // e3 (2024-01-03), e2 (2024-01-02), e1 (2024-01-01) - newest first
      expect(result.value!.map((e) => e.id).toList(), ['e3', 'e2', 'e1']);
    });

    test('filteredSortedExercisesProvider handles exercises never performed in recent sort', () async {
      final exercises = [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Bench Press', description: ''),
        const Exercise(id: 'e3', name: 'Deadlift', description: ''),
      ];

      // Only e1 and e2 have been performed
      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Workout 1',
        entries: [
          WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 5, weight: 100, isComplete: true),
        ],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Workout 2',
        entries: [
          WorkoutEntry(id: 'entry2', exerciseId: 'e2', reps: 5, weight: 80, isComplete: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((_) async => [session1, session2]),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.recentDesc),
        ],
      );

      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutSessionsProvider.future);
      await container.read(exerciseWorkoutCountProvider.future);
      await container.read(exerciseMostRecentDateProvider.future);
      final result = container.read(filteredSortedExercisesProvider);

      expect(result.hasValue, true);
      // e2 (2024-01-02), e1 (2024-01-01), e3 (never performed) - newest first, never performed at end
      expect(result.value!.map((e) => e.id).toList(), ['e2', 'e1', 'e3']);
    });
  });

  group('Workout session filter and sort', () {
    final exercise1 = const Exercise(id: 'ex1', name: 'Bench Press', description: '');
    final exercise2 = const Exercise(id: 'ex2', name: 'Squat', description: '');
    final exercises = [exercise1, exercise2];

    final entry1 = WorkoutEntry(
      id: 'entry1',
      exerciseId: exercise1.id,
      reps: 5,
      weight: 100,
      isComplete: false,
      timestamp: DateTime(2024, 1, 1, 10),
    );
    final entry2 = WorkoutEntry(
      id: 'entry2',
      exerciseId: exercise2.id,
      reps: 8,
      weight: 120,
      isComplete: false,
      timestamp: DateTime(2024, 1, 2, 11),
    );

    final session1 = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime(2024, 1, 1),
      name: 'Push Day',
      entries: [entry1],
    );
    final session2 = WorkoutSession(
      id: 's2',
      workoutId: 'w2',
      date: DateTime(2024, 1, 2),
      name: 'Leg Day',
      entries: [entry2],
    );
    final sessions = [session1, session2];

    test('workoutSessionFilterTextProvider defaults to empty string', () {
      final container = ProviderContainer();
      expect(container.read(workoutSessionFilterTextProvider), '');
    });

    test('workoutSessionSortOrderProvider defaults to dateNewest', () {
      final container = ProviderContainer();
      expect(container.read(workoutSessionSortOrderProvider), WorkoutSessionSortOrder.dateNewest);
    });

    test('filteredSortedWorkoutSessionsProvider filters by exercise name', () async {
      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => 'Bench'),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push Day');
    });

    test('filteredSortedWorkoutSessionsProvider filters by workout name', () async {
      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => 'Leg'),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Leg Day');
    });

    test('filteredSortedWorkoutSessionsProvider sorts by date newest first', () async {
      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value!.map((s) => s.id).toList(), ['s2', 's1']); // s2 is newer
    });

    test('filteredSortedWorkoutSessionsProvider sorts by date oldest first', () async {
      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateOldest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value!.map((s) => s.id).toList(), ['s1', 's2']); // s1 is older
    });

    test('filteredSortedWorkoutSessionsProvider filters by body part', () async {
      final exercise1WithBodyPart = const Exercise(id: 'ex1', name: 'Bench Press', description: '', bodyPart: 'Chest');
      final exercise2WithBodyPart = const Exercise(id: 'ex2', name: 'Squat', description: '', bodyPart: 'Quads');
      final exercisesWithBodyPart = [exercise1WithBodyPart, exercise2WithBodyPart];

      final entry1 = WorkoutEntry(
        id: 'entry1',
        exerciseId: exercise1WithBodyPart.id,
        reps: 5,
        weight: 100,
        isComplete: false,
        timestamp: DateTime(2024, 1, 1, 10),
      );
      final entry2 = WorkoutEntry(
        id: 'entry2',
        exerciseId: exercise2WithBodyPart.id,
        reps: 8,
        weight: 120,
        isComplete: false,
        timestamp: DateTime(2024, 1, 2, 11),
      );

      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Push Day',
        entries: [entry1],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Leg Day',
        entries: [entry2],
      );
      final sessionsWithBodyPart = [session1, session2];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessionsWithBodyPart),
          exercisesFutureProvider.overrideWith((_) async => exercisesWithBodyPart),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionBodyPartFilterProvider.overrideWith((_) => ['chest']),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push Day');
    });

    test('filteredSortedWorkoutSessionsProvider filters by equipment', () async {
      final exercise1WithEquipment = const Exercise(id: 'ex1', name: 'Bench Press', description: '', equipment: 'Barbell');
      final exercise2WithEquipment = const Exercise(id: 'ex2', name: 'Dumbbell Curl', description: '', equipment: 'Dumbbell');
      final exercisesWithEquipment = [exercise1WithEquipment, exercise2WithEquipment];

      final entry1 = WorkoutEntry(
        id: 'entry1',
        exerciseId: exercise1WithEquipment.id,
        reps: 5,
        weight: 100,
        isComplete: false,
        timestamp: DateTime(2024, 1, 1, 10),
      );
      final entry2 = WorkoutEntry(
        id: 'entry2',
        exerciseId: exercise2WithEquipment.id,
        reps: 8,
        weight: 120,
        isComplete: false,
        timestamp: DateTime(2024, 1, 2, 11),
      );

      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Push Day',
        entries: [entry1],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Arm Day',
        entries: [entry2],
      );
      final sessionsWithEquipment = [session1, session2];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessionsWithEquipment),
          exercisesFutureProvider.overrideWith((_) async => exercisesWithEquipment),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionEquipmentFilterProvider.overrideWith((_) => ['Barbell']),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push Day');
    });

    test('filteredSortedWorkoutSessionsProvider combines text and body part filters', () async {
      final exercise1 = const Exercise(id: 'ex1', name: 'Bench Press', description: '', bodyPart: 'Chest');
      final exercise2 = const Exercise(id: 'ex2', name: 'Squat', description: '', bodyPart: 'Quads');
      final exercises = [exercise1, exercise2];

      final entry1 = WorkoutEntry(
        id: 'entry1',
        exerciseId: exercise1.id,
        reps: 5,
        weight: 100,
        isComplete: false,
        timestamp: DateTime(2024, 1, 1, 10),
      );
      final entry2 = WorkoutEntry(
        id: 'entry2',
        exerciseId: exercise2.id,
        reps: 8,
        weight: 120,
        isComplete: false,
        timestamp: DateTime(2024, 1, 2, 11),
      );

      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Push Day',
        entries: [entry1],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Leg Day',
        entries: [entry2],
      );
      final sessions = [session1, session2];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => 'Push'),
          workoutSessionBodyPartFilterProvider.overrideWith((_) => ['chest']),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push Day');
    });

    test('filteredSortedWorkoutSessionsProvider handles sessions with exercises without body part', () async {
      final exercise1 = const Exercise(id: 'ex1', name: 'Bench Press', description: '', bodyPart: 'Chest');
      final exercise2 = const Exercise(id: 'ex2', name: 'Unknown Exercise', description: ''); // No body part
      final exercises = [exercise1, exercise2];

      final entry1 = WorkoutEntry(
        id: 'entry1',
        exerciseId: exercise1.id,
        reps: 5,
        weight: 100,
        isComplete: false,
        timestamp: DateTime(2024, 1, 1, 10),
      );
      final entry2 = WorkoutEntry(
        id: 'entry2',
        exerciseId: exercise2.id,
        reps: 8,
        weight: 120,
        isComplete: false,
        timestamp: DateTime(2024, 1, 2, 11),
      );

      final session1 = WorkoutSession(
        id: 's1',
        workoutId: 'w1',
        date: DateTime(2024, 1, 1),
        name: 'Push Day',
        entries: [entry1],
      );
      final session2 = WorkoutSession(
        id: 's2',
        workoutId: 'w2',
        date: DateTime(2024, 1, 2),
        name: 'Other Day',
        entries: [entry2],
      );
      final sessions = [session1, session2];

      final container = ProviderContainer(
        overrides: [
          ...favoriteOverrides,
          workoutSessionsProvider.overrideWith((_) async => sessions),
          exercisesFutureProvider.overrideWith((_) async => exercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionBodyPartFilterProvider.overrideWith((_) => ['chest']),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      await container.read(exercisesFutureProvider.future);
      await container.read(exerciseMusclesMapProvider.future);
      await container.read(workoutTemplatesFutureProvider.future);
      final result = container.read(filteredSortedWorkoutSessionsProvider);

      expect(result.hasValue, true);
      expect(result.value, hasLength(1));
      expect(result.value!.first.name, 'Push Day');
    });
  });
}

class _TestExerciseFavoritesNotifier extends ExerciseFavoritesNotifier {
  _TestExerciseFavoritesNotifier(super.db) {
    state = const AsyncValue.data(<String>{});
  }
}
