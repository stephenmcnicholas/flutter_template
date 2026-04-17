import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/exercise.dart';
import '../domain/exercise_body_region.dart';
import '../domain/workout_session.dart';
import '../domain/workout.dart';
import 'data_providers.dart';
import 'workout_session_provider.dart';
import 'exercise_history_provider.dart';
import 'exercise_favorites_provider.dart';
import '../presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'exercise_muscles_provider.dart';

/// Fixed coarse body-area choices for filter sheets (not derived from data).
final exerciseBodyRegionChoicesProvider =
    Provider<List<ExerciseBodyRegion>>(
  (ref) => kExerciseBodyRegionFilterOrder,
);

/// Available equipment for filtering (derived from exercises).
final availableEquipmentOptionsProvider =
    FutureProvider<List<String>>((ref) async {
  final exercises = await ref.watch(exercisesFutureProvider.future);
  final options = <String>{};
  for (final ex in exercises) {
    final equipment = ex.equipment;
    if (equipment != null && equipment.trim().isNotEmpty) {
      options.add(equipment.trim());
    }
  }
  final sorted = options.toList()..sort((a, b) => a.compareTo(b));
  return sorted;
});

/// Generic sort order for exercises
enum ExerciseSortOrder {
  nameAsc,
  nameDesc,
  bodyPartAsc,
  bodyPartDesc,
  equipmentAsc,
  equipmentDesc,
  frequencyAsc,
  frequencyDesc,
  recentAsc,
  recentDesc,
}

/// Generic sort order for workout sessions
enum WorkoutSessionSortOrder {
  dateNewest,
  dateOldest,
  nameAsc,
  nameDesc,
  volumeHighest,
  volumeLowest,
  durationLongest,
  durationShortest,
}

/// Generic sort order for workout templates
enum WorkoutTemplateSortOrder {
  nameAsc,
  nameDesc,
  setsAsc,
  setsDesc,
  exercisesAsc,
  exercisesDesc,
}

/// Provider for exercise filter text
final exerciseFilterTextProvider = StateProvider<String>((ref) => '');

/// Provider for coarse body-area filters. Values are [ExerciseBodyRegion.name]
/// (e.g. `chest`, `legs`). Empty means no filter.
final exerciseBodyPartFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for exercise equipment filters (empty list means no filter)
final exerciseEquipmentFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for exercise favorite filter (true means favorites only)
final exerciseFavoriteFilterProvider = StateProvider<bool>((ref) => false);

/// Provider for exercise sort order
final exerciseSortOrderProvider = StateProvider<ExerciseSortOrder>(
  (ref) => ExerciseSortOrder.frequencyDesc,
);

/// Provider for filtered and sorted exercises
final filteredSortedExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final exercisesAsync = ref.watch(exercisesFutureProvider);
  final filterText = ref.watch(exerciseFilterTextProvider);
  final bodyPartFilter = ref.watch(exerciseBodyPartFilterProvider);
  final equipmentFilter = ref.watch(exerciseEquipmentFilterProvider);
  final favoriteOnly = ref.watch(exerciseFavoriteFilterProvider);
  final favoritesAsync = ref.watch(exerciseFavoritesProvider);
  final sortOrder = ref.watch(exerciseSortOrderProvider);
  final workoutCountsAsync = ref.watch(exerciseWorkoutCountProvider);
  final mostRecentDatesAsync = ref.watch(exerciseMostRecentDateProvider);
  final musclesAsync = ref.watch(exerciseMusclesMapProvider);

  return exercisesAsync.when(
    data: (exercises) {
      return musclesAsync.when(
        data: (muscleMap) {
          return favoritesAsync.when(
            data: (favoriteIds) {
              return workoutCountsAsync.when(
                data: (workoutCounts) {
                  final hasWorkoutHistory =
                      workoutCounts.values.any((count) => count > 0);
                  if (!hasWorkoutHistory &&
                      sortOrder == ExerciseSortOrder.frequencyDesc) {
                    // Default to name sorting until the user has workout history.
                    Future.microtask(() {
                      ref.read(exerciseSortOrderProvider.notifier).state =
                          ExerciseSortOrder.nameAsc;
                    });
                  }
                  final effectiveSortOrder = !hasWorkoutHistory &&
                          sortOrder == ExerciseSortOrder.frequencyDesc
                      ? ExerciseSortOrder.nameAsc
                      : sortOrder;
                  return mostRecentDatesAsync.when(
                    data: (mostRecentDates) {
                      // Filter exercises
                      List<Exercise> filtered = exercises;
                      final selectedBodyRegions =
                          exerciseBodyRegionsFromFilterKeys(bodyPartFilter);

                      // Apply text filter
                      if (filterText.isNotEmpty) {
                        final lowerFilter = filterText.toLowerCase();
                        filtered = filtered.where((exercise) {
                          // Match on name, description, bodyPart, or equipment
                          return exercise.name.toLowerCase().contains(lowerFilter) ||
                              exercise.description.toLowerCase().contains(lowerFilter) ||
                              (exercise.bodyPart?.toLowerCase().contains(lowerFilter) ?? false) ||
                              (exercise.equipment?.toLowerCase().contains(lowerFilter) ?? false);
                        }).toList();
                      }

                      // Apply favorites filter
                      if (favoriteOnly) {
                        filtered = filtered.where((exercise) {
                          return favoriteIds.contains(exercise.id);
                        }).toList();
                      }

                      // Apply body-area filter (OR across selected regions)
                      if (selectedBodyRegions.isNotEmpty) {
                        filtered = filtered.where((exercise) {
                          final muscles =
                              muscleMap[exercise.id] ?? const <String>[];
                          final regions = exerciseBodyRegionsForExercise(
                            exercise,
                            muscles,
                          );
                          return exerciseMatchesBodyRegionSelection(
                            exerciseRegions: regions,
                            selectedRegions: selectedBodyRegions,
                          );
                        }).toList();
                      }

                      // Apply equipment filter (OR logic - match any selected)
                      if (equipmentFilter.isNotEmpty) {
                        filtered = filtered.where((exercise) {
                          return exercise.equipment != null &&
                              equipmentFilter.contains(exercise.equipment!);
                        }).toList();
                      }

                      // Sort exercises
                      final sorted = List<Exercise>.from(filtered);
                      sorted.sort((a, b) {
                        switch (effectiveSortOrder) {
                      case ExerciseSortOrder.nameAsc:
                        return a.name.compareTo(b.name);
                      case ExerciseSortOrder.nameDesc:
                        return b.name.compareTo(a.name);
                      case ExerciseSortOrder.bodyPartAsc:
                        return (a.bodyPart ?? '').compareTo(b.bodyPart ?? '');
                      case ExerciseSortOrder.bodyPartDesc:
                        return (b.bodyPart ?? '').compareTo(a.bodyPart ?? '');
                      case ExerciseSortOrder.equipmentAsc:
                        return (a.equipment ?? '').compareTo(b.equipment ?? '');
                      case ExerciseSortOrder.equipmentDesc:
                        return (b.equipment ?? '').compareTo(a.equipment ?? '');
                      case ExerciseSortOrder.frequencyAsc:
                        final countA = workoutCounts[a.id] ?? 0;
                        final countB = workoutCounts[b.id] ?? 0;
                        if (countA != countB) {
                          return countA.compareTo(countB);
                        }
                        // Secondary sort by name for ties
                        return a.name.compareTo(b.name);
                      case ExerciseSortOrder.frequencyDesc:
                        final countA = workoutCounts[a.id] ?? 0;
                        final countB = workoutCounts[b.id] ?? 0;
                        if (countA != countB) {
                          return countB.compareTo(countA);
                        }
                        // Secondary sort by name for ties
                        return a.name.compareTo(b.name);
                      case ExerciseSortOrder.recentAsc:
                        final dateA = mostRecentDates[a.id];
                        final dateB = mostRecentDates[b.id];
                        // Exercises with no date (never performed) go to the end
                        if (dateA == null && dateB == null) {
                          return a.name.compareTo(b.name);
                        }
                        if (dateA == null) return 1; // A goes after B
                        if (dateB == null) return -1; // B goes after A
                        // Both have dates: older first
                        if (dateA != dateB) {
                          return dateA.compareTo(dateB);
                        }
                        // Secondary sort by name for ties
                        return a.name.compareTo(b.name);
                      case ExerciseSortOrder.recentDesc:
                        final dateA = mostRecentDates[a.id];
                        final dateB = mostRecentDates[b.id];
                        // Exercises with no date (never performed) go to the end
                        if (dateA == null && dateB == null) {
                          return a.name.compareTo(b.name);
                        }
                        if (dateA == null) return 1; // A goes after B
                        if (dateB == null) return -1; // B goes after A
                        // Both have dates: newer first
                        if (dateA != dateB) {
                          return dateB.compareTo(dateA);
                        }
                        // Secondary sort by name for ties
                        return a.name.compareTo(b.name);
                    }
                  });

                      return AsyncValue.data(sorted);
                    },
                    loading: () => const AsyncValue.loading(),
                    error: (err, stack) => AsyncValue.error(err, stack),
                  );
                },
                loading: () => const AsyncValue.loading(),
                error: (err, stack) => AsyncValue.error(err, stack),
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Provider for workout session filter text
final workoutSessionFilterTextProvider = StateProvider<String>((ref) => '');

/// Provider for workout session date filter (single day)
final workoutSessionDateFilterProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for program date filter (single day)
final programDateFilterProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for workout session body-area filters ([ExerciseBodyRegion.name]).
final workoutSessionBodyPartFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for workout session equipment filters (empty list means no filter)
final workoutSessionEquipmentFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for workout session sort order
final workoutSessionSortOrderProvider = StateProvider<WorkoutSessionSortOrder>(
  (ref) => WorkoutSessionSortOrder.dateNewest,
);

/// Provider for filtered and sorted workout sessions
final filteredSortedWorkoutSessionsProvider = Provider<AsyncValue<List<WorkoutSession>>>((ref) {
  final sessionsAsync = ref.watch(workoutSessionsProvider);
  final filterText = ref.watch(workoutSessionFilterTextProvider);
  final bodyPartFilter = ref.watch(workoutSessionBodyPartFilterProvider);
  final equipmentFilter = ref.watch(workoutSessionEquipmentFilterProvider);
  final sortOrder = ref.watch(workoutSessionSortOrderProvider);
  final exercisesAsync = ref.watch(exercisesFutureProvider);
  final workoutsAsync = ref.watch(workoutTemplatesFutureProvider);
  final musclesAsync = ref.watch(exerciseMusclesMapProvider);

  return sessionsAsync.when(
    data: (sessions) {
      return exercisesAsync.when(
        data: (exercises) {
          return musclesAsync.when(
            data: (muscleMap) {
              return workoutsAsync.when(
                data: (workouts) {
              // Build exercise name and metadata maps
              final exerciseNameMap = <String, String>{
                for (var ex in exercises) ex.id: ex.name,
              };
              final exerciseById = {for (final ex in exercises) ex.id: ex};
              final exerciseEquipmentMap = <String, String?>{
                for (var ex in exercises) ex.id: ex.equipment,
              };

              // Build workout name map
              final workoutNameMap = <String, String>{
                for (var w in workouts) w.id: w.name,
              };

              // Filter sessions
              List<WorkoutSession> filtered = sessions;
              
              // Apply text filter
              if (filterText.isNotEmpty) {
                final lowerFilter = filterText.toLowerCase();
                filtered = filtered.where((session) {
                  // Match on session name
                  if (session.name?.toLowerCase().contains(lowerFilter) ?? false) {
                    return true;
                  }

                  // Match on workout template name
                  final templateName = workoutNameMap[session.workoutId];
                  if (templateName?.toLowerCase().contains(lowerFilter) ?? false) {
                    return true;
                  }

                  // Match on exercises within the session
                  for (final entry in session.entries) {
                    final exerciseName = exerciseNameMap[entry.exerciseId];
                    if (exerciseName?.toLowerCase().contains(lowerFilter) ?? false) {
                      return true;
                    }
                  }

                  return false;
                }).toList();
              }

              // Apply date filter (single day)
              final dateFilter = ref.watch(workoutSessionDateFilterProvider);
              if (dateFilter != null) {
                filtered = filtered.where((session) {
                  final date = session.date;
                  return date.year == dateFilter.year &&
                      date.month == dateFilter.month &&
                      date.day == dateFilter.day;
                }).toList();
              }
              
              // Apply body-area filter (OR across selected regions)
              if (bodyPartFilter.isNotEmpty) {
                final selectedBodyRegions =
                    exerciseBodyRegionsFromFilterKeys(bodyPartFilter);
                if (selectedBodyRegions.isNotEmpty) {
                  filtered = filtered.where((session) {
                    for (final entry in session.entries) {
                      final ex = exerciseById[entry.exerciseId];
                      if (ex == null) continue;
                      final muscles =
                          muscleMap[entry.exerciseId] ?? const <String>[];
                      final regions = exerciseBodyRegionsForExercise(ex, muscles);
                      if (exerciseMatchesBodyRegionSelection(
                        exerciseRegions: regions,
                        selectedRegions: selectedBodyRegions,
                      )) {
                        return true;
                      }
                    }
                    return false;
                  }).toList();
                }
              }
              
              // Apply equipment filter (OR logic - match any selected)
              if (equipmentFilter.isNotEmpty) {
                filtered = filtered.where((session) {
                  // Check if any exercise in the session matches any selected equipment
                  for (final entry in session.entries) {
                    final equipment = exerciseEquipmentMap[entry.exerciseId];
                    if (equipment != null && equipmentFilter.contains(equipment)) {
                      return true;
                    }
                  }
                  return false;
                }).toList();
              }

              // Calculate stats and sort
              final sessionsWithStats = filtered.map((session) {
                final totalVolume = session.entries.fold<double>(
                  0,
                  (sum, entry) => sum + (entry.weight * entry.reps),
                );

                final timestamps = session.entries
                    .where((e) => e.timestamp != null)
                    .map((e) => e.timestamp!)
                    .toList();
                final duration = timestamps.isEmpty
                    ? Duration.zero
                    : timestamps.last.difference(timestamps.first);

                return _SessionWithStats(
                  session: session,
                  totalVolume: totalVolume,
                  duration: duration,
                );
              }).toList();

              sessionsWithStats.sort((a, b) {
                switch (sortOrder) {
                  case WorkoutSessionSortOrder.dateNewest:
                    return b.session.date.compareTo(a.session.date);
                  case WorkoutSessionSortOrder.dateOldest:
                    return a.session.date.compareTo(b.session.date);
                  case WorkoutSessionSortOrder.nameAsc:
                    return (a.session.name ?? '').compareTo(b.session.name ?? '');
                  case WorkoutSessionSortOrder.nameDesc:
                    return (b.session.name ?? '').compareTo(a.session.name ?? '');
                  case WorkoutSessionSortOrder.volumeHighest:
                    return b.totalVolume.compareTo(a.totalVolume);
                  case WorkoutSessionSortOrder.volumeLowest:
                    return a.totalVolume.compareTo(b.totalVolume);
                  case WorkoutSessionSortOrder.durationLongest:
                    return b.duration.compareTo(a.duration);
                  case WorkoutSessionSortOrder.durationShortest:
                    return a.duration.compareTo(b.duration);
                }
              });

              final sorted = sessionsWithStats.map((s) => s.session).toList();
              return AsyncValue.data(sorted);
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Helper class to hold session statistics
class _SessionWithStats {
  final WorkoutSession session;
  final double totalVolume;
  final Duration duration;

  _SessionWithStats({
    required this.session,
    required this.totalVolume,
    required this.duration,
  });
}

/// Provider for workout template filter text
final workoutTemplateFilterTextProvider = StateProvider<String>((ref) => '');

/// Provider for workout template body-area filters ([ExerciseBodyRegion.name]).
final workoutTemplateBodyPartFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for workout template equipment filters (empty list means no filter)
final workoutTemplateEquipmentFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provider for workout template sort order
final workoutTemplateSortOrderProvider = StateProvider<WorkoutTemplateSortOrder>(
  (ref) => WorkoutTemplateSortOrder.nameAsc,
);

/// Provider for filtered and sorted workout templates
final filteredSortedWorkoutTemplatesProvider = Provider<AsyncValue<List<Workout>>>((ref) {
  final templatesAsync = ref.watch(workoutTemplatesFutureProvider);
  final filterText = ref.watch(workoutTemplateFilterTextProvider);
  final bodyPartFilter = ref.watch(workoutTemplateBodyPartFilterProvider);
  final equipmentFilter = ref.watch(workoutTemplateEquipmentFilterProvider);
  final sortOrder = ref.watch(workoutTemplateSortOrderProvider);
  final exercisesAsync = ref.watch(exercisesFutureProvider);
  final musclesAsync = ref.watch(exerciseMusclesMapProvider);

  return templatesAsync.when(
    data: (templates) {
      return exercisesAsync.when(
        data: (exercises) {
          return musclesAsync.when(
            data: (muscleMap) {
              final exerciseById = {for (final ex in exercises) ex.id: ex};
              final exerciseEquipmentMap = <String, String?>{
                for (var ex in exercises) ex.id: ex.equipment,
              };

              // Filter templates
              List<Workout> filtered = templates;
              final selectedBodyRegions =
                  exerciseBodyRegionsFromFilterKeys(bodyPartFilter);

              // Apply text filter
              if (filterText.isNotEmpty) {
                final lowerFilter = filterText.toLowerCase();
                filtered = filtered.where((template) {
                  // Match on template name
                  if (template.name.toLowerCase().contains(lowerFilter)) {
                    return true;
                  }

                  // Match on exercises within the template
                  for (final entry in template.entries) {
                    final exercise = exercises.firstWhere(
                      (ex) => ex.id == entry.exerciseId,
                      orElse: () =>
                          const Exercise(id: '', name: '', description: ''),
                    );
                    if (exercise.name.toLowerCase().contains(lowerFilter)) {
                      return true;
                    }
                  }

                  return false;
                }).toList();
              }

              // Apply body-area filter (OR across selected regions)
              if (selectedBodyRegions.isNotEmpty) {
                filtered = filtered.where((template) {
                  for (final entry in template.entries) {
                    final ex = exerciseById[entry.exerciseId];
                    if (ex == null) continue;
                    final muscles =
                        muscleMap[entry.exerciseId] ?? const <String>[];
                    final regions = exerciseBodyRegionsForExercise(ex, muscles);
                    if (exerciseMatchesBodyRegionSelection(
                      exerciseRegions: regions,
                      selectedRegions: selectedBodyRegions,
                    )) {
                      return true;
                    }
                  }
                  return false;
                }).toList();
              }

              // Apply equipment filter (OR logic - match any selected)
              if (equipmentFilter.isNotEmpty) {
                filtered = filtered.where((template) {
                  // Check if any exercise in the template matches any selected equipment
                  for (final entry in template.entries) {
                    final equipment = exerciseEquipmentMap[entry.exerciseId];
                    if (equipment != null && equipmentFilter.contains(equipment)) {
                      return true;
                    }
                  }
                  return false;
                }).toList();
              }

              // Sort templates
              final sorted = List<Workout>.from(filtered);
              sorted.sort((a, b) {
                switch (sortOrder) {
              case WorkoutTemplateSortOrder.nameAsc:
                return a.name.compareTo(b.name);
              case WorkoutTemplateSortOrder.nameDesc:
                return b.name.compareTo(a.name);
              case WorkoutTemplateSortOrder.setsAsc:
                if (a.entries.length != b.entries.length) {
                  return a.entries.length.compareTo(b.entries.length);
                }
                // Secondary sort by name for ties
                return a.name.compareTo(b.name);
              case WorkoutTemplateSortOrder.setsDesc:
                if (a.entries.length != b.entries.length) {
                  return b.entries.length.compareTo(a.entries.length);
                }
                // Secondary sort by name for ties
                return a.name.compareTo(b.name);
              case WorkoutTemplateSortOrder.exercisesAsc:
                final uniqueExercisesA = a.entries.map((e) => e.exerciseId).toSet().length;
                final uniqueExercisesB = b.entries.map((e) => e.exerciseId).toSet().length;
                if (uniqueExercisesA != uniqueExercisesB) {
                  return uniqueExercisesA.compareTo(uniqueExercisesB);
                }
                // Secondary sort by name for ties
                return a.name.compareTo(b.name);
              case WorkoutTemplateSortOrder.exercisesDesc:
                final uniqueExercisesA = a.entries.map((e) => e.exerciseId).toSet().length;
                final uniqueExercisesB = b.entries.map((e) => e.exerciseId).toSet().length;
                if (uniqueExercisesA != uniqueExercisesB) {
                  return uniqueExercisesB.compareTo(uniqueExercisesA);
                }
                // Secondary sort by name for ties
                return a.name.compareTo(b.name);
            }
          });

              return AsyncValue.data(sorted);
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
