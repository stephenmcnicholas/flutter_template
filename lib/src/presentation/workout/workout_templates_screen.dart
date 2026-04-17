import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/logger/workout_start_flow.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/presentation/shared/swipe_action_tile.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_list_entry_animation.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_filter_sort_bar.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/theme.dart';

class WorkoutTemplatesScreen extends ConsumerWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.themeExt<AppSpacing>();
    final templatesAsync = ref.watch(filteredSortedWorkoutTemplatesProvider);
    final filterText = ref.watch(workoutTemplateFilterTextProvider);
    final sortOrder = ref.watch(workoutTemplateSortOrderProvider);
    final bodyPartFilter = ref.watch(workoutTemplateBodyPartFilterProvider);
    final equipmentFilter = ref.watch(workoutTemplateEquipmentFilterProvider);
    final bodyAreaRegions = ref.watch(exerciseBodyRegionChoicesProvider);
    final equipmentOptionsAsync = ref.watch(availableEquipmentOptionsProvider);
    final hasActiveFilters = filterText.isNotEmpty ||
        bodyPartFilter.isNotEmpty ||
        equipmentFilter.isNotEmpty;

    // Helper to get sort label and direction
    final sortLabel = _getSortLabel(sortOrder);
    final isAscending = _isSortAscending(sortOrder);
    final sortOptions = _getTemplateSortOptions();

    return Column(
      children: [
        AppFilterSortBar(
          filterText: filterText,
          onFilterChanged: (value) {
            ref.read(workoutTemplateFilterTextProvider.notifier).state = value;
          },
          currentSortLabel: sortLabel,
          isAscending: isAscending,
          sortOptions: sortOptions,
          onSortOptionSelected: (option, ascending) {
            final newOrder = _getSortOrderFromLabel(option, ascending);
            ref.read(workoutTemplateSortOrderProvider.notifier).state = newOrder;
          },
          searchPlaceholder: 'Filter by template or exercise',
          currentBodyAreaFilter: bodyPartFilter,
          bodyAreaRegions: bodyAreaRegions,
          currentEquipmentFilter: equipmentFilter,
          equipmentOptions: equipmentOptionsAsync.valueOrNull ?? const [],
          onBodyAreaFilterChanged: (values) {
            ref.read(workoutTemplateBodyPartFilterProvider.notifier).state = values;
          },
          onEquipmentFilterChanged: (values) {
            ref.read(workoutTemplateEquipmentFilterProvider.notifier).state = values;
          },
        ),
        Expanded(
          child: templatesAsync.when(
            data: (List<Workout> workouts) {
              if (workouts.isEmpty) {
                return AppEmptyState(
                  title: hasActiveFilters
                      ? 'No templates found'
                      : 'No templates yet',
                  message: hasActiveFilters
                      ? 'Try adjusting your filters.'
                      : 'Create a template to reuse your favorite workouts.',
                  illustrationAsset: hasActiveFilters
                      ? 'assets/illustrations/empty_state_search.svg'
                      : 'assets/illustrations/empty_state_generic.svg',
                );
              }
              return FutureBuilder<List<Exercise>>(
                future: ref.read(exercisesFutureProvider.future),
                builder: (context, snapshot) {
                  final allExercises = snapshot.data ?? [];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                    child: ListView.separated(
                      padding: EdgeInsets.only(top: spacing.md),
                      itemCount: workouts.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: spacing.sm),
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        return AppListEntryAnimation(
                          index: index,
                          child: SwipeActionTile(
                    key: ValueKey('swipe_template_${workout.id}'),
                    onDelete: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Delete Template',
                        message: 'Are you sure you want to delete "${workout.name}"?',
                        confirmText: 'Delete',
                      );
                      if (confirmed == true) {
                        final repo = ref.read(workoutRepositoryProvider);
                        await repo.delete(workout.id);
                        ref.invalidate(workoutTemplatesFutureProvider);
                      }
                    },
                    onReplace: () {},
                    showReplace: false,
                    onStart: () async {
                      final exerciseMap = { for (final ex in allExercises) ex.id: ex };
                      final initialExercises = <Exercise>[];
                      for (final entry in workout.entries) {
                        final ex = exerciseMap[entry.exerciseId];
                        if (ex != null && !initialExercises.any((e) => e.id == ex.id)) {
                          initialExercises.add(ex);
                        }
                      }
                      final initialSetsByExercise = <String, List<Map<String, dynamic>>>{};
                      
                      // Fetch last recorded values for all unique exercises upfront
                      final lastValuesByExercise = <String, LastRecordedValues?>{};
                      final uniqueExerciseIds = workout.entries.map((e) => e.exerciseId).toSet();
                      for (final exerciseId in uniqueExerciseIds) {
                        try {
                          final lastValues = await ref.read(lastRecordedValuesProvider(exerciseId).future);
                          lastValuesByExercise[exerciseId] = lastValues;
                        } catch (e) {
                          // If provider fails, use null (will fall back to template values)
                          lastValuesByExercise[exerciseId] = null;
                        }
                      }
                      
                      // Create sets for all entries, using last recorded values for ALL sets
                      for (final entry in workout.entries) {
                        final lastValues = lastValuesByExercise[entry.exerciseId];
                        
                        // Use last recorded values if available, otherwise fall back to template values
                        initialSetsByExercise.putIfAbsent(entry.exerciseId, () => []).add({
                          'id': entry.id,
                          'reps': lastValues?.reps ?? entry.reps,
                          'weight': lastValues?.weight ?? entry.weight,
                          'distance': lastValues?.distance ?? entry.distance,
                          'duration': lastValues?.duration ?? entry.duration,
                          'isComplete': false,
                          'targetReps': entry.reps,
                          'targetWeight': entry.weight,
                          'targetDistance': entry.distance,
                          'targetDuration': entry.duration,
                          'supersetGroupId': entry.supersetGroupId,
                        });
                      }
                      if (!context.mounted) return;
                      // If this workout belongs to an AI programme, pass the
                      // programId so the logger suppresses the template-save
                      // dialog (AI programme workouts are immutable from here).
                      String? owningProgramId;
                      try {
                        final programmes = await ref.read(programsFutureProvider.future);
                        final owning = programmes.where(
                          (p) => p.isAiGenerated && p.schedule.any((pw) => pw.workoutId == workout.id),
                        ).firstOrNull;
                        owningProgramId = owning?.id;
                      } catch (_) {
                        // If lookup fails, leave owningProgramId null — standalone behaviour
                      }
                      if (!context.mounted) return;
                      final args = PreWorkoutCheckInArgs(
                        workoutName: workout.name,
                        workoutId: workout.id,
                        programId: owningProgramId,
                        initialExercises: initialExercises,
                        initialSetsByExercise: initialSetsByExercise,
                      );
                      await startWorkoutFlow(context, ref, args);
                    },
                    child: AppCard(
                      compact: true,
                      onTap: () => context.push('/workouts/edit/${workout.id}'),
                      child: AppListRow(
                        dense: true,
                        title: AppText(workout.name, style: AppTextStyle.label),
                        subtitle: AppStatsRow(
                          items: [
                            AppStatItem(
                              label: 'Sets',
                              value: workout.entries.length.toString(),
                            ),
                            AppStatItem(
                              label: 'Exercises',
                              value: workout.entries.map((e) => e.exerciseId).toSet().length.toString(),
                            ),
                          ],
                        ),
                      ),
                    ),
                          ),
                        );
                },
              ),
            );
          },
        );
            },
            loading: () => const AppLoadingState(
              useShimmer: true,
              variant: AppLoadingVariant.list,
            ),
            error: (_, __) => AppEmptyState(
              title: 'Unable to load templates',
              message: 'Something went wrong. Please try again.',
              icon: Icons.error_outline,
            ),
          ),
        ),
      ],
    );
  }

  /// Get display label for sort order
  String _getSortLabel(WorkoutTemplateSortOrder order) {
    switch (order) {
      case WorkoutTemplateSortOrder.nameAsc:
      case WorkoutTemplateSortOrder.nameDesc:
        return 'Name';
      case WorkoutTemplateSortOrder.setsAsc:
      case WorkoutTemplateSortOrder.setsDesc:
        return 'Sets';
      case WorkoutTemplateSortOrder.exercisesAsc:
      case WorkoutTemplateSortOrder.exercisesDesc:
        return 'Exercises';
    }
  }

  /// Check if sort order is ascending
  bool _isSortAscending(WorkoutTemplateSortOrder order) {
    switch (order) {
      case WorkoutTemplateSortOrder.nameAsc:
      case WorkoutTemplateSortOrder.setsAsc:
      case WorkoutTemplateSortOrder.exercisesAsc:
        return true;
      case WorkoutTemplateSortOrder.nameDesc:
      case WorkoutTemplateSortOrder.setsDesc:
      case WorkoutTemplateSortOrder.exercisesDesc:
        return false;
    }
  }

  /// Get sort order from label and direction
  WorkoutTemplateSortOrder _getSortOrderFromLabel(String label, bool ascending) {
    switch (label) {
      case 'Name':
        return ascending ? WorkoutTemplateSortOrder.nameAsc : WorkoutTemplateSortOrder.nameDesc;
      case 'Sets':
        return ascending ? WorkoutTemplateSortOrder.setsAsc : WorkoutTemplateSortOrder.setsDesc;
      case 'Exercises':
        return ascending ? WorkoutTemplateSortOrder.exercisesAsc : WorkoutTemplateSortOrder.exercisesDesc;
      default:
        return WorkoutTemplateSortOrder.nameAsc;
    }
  }

  /// Get list of sort option labels
  List<String> _getTemplateSortOptions() {
    return ['Name', 'Sets', 'Exercises'];
  }
}


final workoutTemplatesFutureProvider = FutureProvider<List<Workout>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.findAll();
}); 