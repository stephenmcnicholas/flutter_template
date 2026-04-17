import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/filter_sort_providers.dart';
import '../../providers/exercise_favorites_provider.dart';
import '../../providers/exercise_history_provider.dart';
import '../shared/app_text.dart';
import '../shared/app_filter_sort_bar.dart';
import '../shared/exercise_list_tile.dart';
import '../shared/app_list_entry_animation.dart';
import '../shared/app_loading_state.dart';
import '../shared/app_empty_state.dart';
import '../theme.dart';

/// A screen that lists all exercises and exposes actions via a FAB.
class ExerciseListScreen extends ConsumerWidget {
  final void Function(String workoutName) onStartWorkout;
  const ExerciseListScreen({super.key, required this.onStartWorkout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final exercisesAsync = ref.watch(filteredSortedExercisesProvider);
    final workoutCountsAsync = ref.watch(exerciseWorkoutCountProvider);
    final filterText = ref.watch(exerciseFilterTextProvider);
    final sortOrder = ref.watch(exerciseSortOrderProvider);
    final favoritesAsync = ref.watch(exerciseFavoritesProvider);
    final bodyAreaRegions = ref.watch(exerciseBodyRegionChoicesProvider);
    final equipmentOptionsAsync = ref.watch(availableEquipmentOptionsProvider);

    // Helper to get sort label and direction
    final sortLabel = _getSortLabel(sortOrder);
    final isAscending = _isSortAscending(sortOrder);
    final sortOptions = _getExerciseSortOptions();

    final bodyPartFilter = ref.watch(exerciseBodyPartFilterProvider);
    final equipmentFilter = ref.watch(exerciseEquipmentFilterProvider);
    final favoriteOnly = ref.watch(exerciseFavoriteFilterProvider);
    final hasActiveFilters = filterText.isNotEmpty ||
        favoriteOnly ||
        bodyPartFilter.isNotEmpty ||
        equipmentFilter.isNotEmpty;

    return Column(
      children: [
        AppFilterSortBar(
          filterText: filterText,
          onFilterChanged: (value) {
            ref.read(exerciseFilterTextProvider.notifier).state = value;
          },
          currentSortLabel: sortLabel,
          isAscending: isAscending,
          sortOptions: sortOptions,
          onSortOptionSelected: (option, ascending) {
            final newOrder = _getSortOrderFromLabel(option, ascending);
            ref.read(exerciseSortOrderProvider.notifier).state = newOrder;
          },
          searchPlaceholder: 'Search exercises',
          currentBodyAreaFilter: bodyPartFilter,
          bodyAreaRegions: bodyAreaRegions,
          currentEquipmentFilter: equipmentFilter,
          equipmentOptions: equipmentOptionsAsync.valueOrNull ?? const [],
          currentFavoriteFilter: favoriteOnly,
          onBodyAreaFilterChanged: (values) {
            ref.read(exerciseBodyPartFilterProvider.notifier).state = values;
          },
          onEquipmentFilterChanged: (values) {
            ref.read(exerciseEquipmentFilterProvider.notifier).state = values;
          },
          onFavoriteFilterChanged: (value) {
            ref.read(exerciseFavoriteFilterProvider.notifier).state = value;
          },
        ),
        Expanded(
          child: exercisesAsync.when(
            // 1) Data loaded: full UI with list
            data: (exercises) {
              if (exercises.isEmpty) {
                return Center(
                  child: AppEmptyState(
                    title: hasActiveFilters
                        ? 'No matching exercises'
                        : 'No exercises yet',
                    message: hasActiveFilters
                        ? 'Try adjusting your filters.'
                        : 'Create your first exercise to get started.',
                    illustrationAsset: hasActiveFilters
                        ? 'assets/illustrations/empty_state_search.svg'
                        : 'assets/illustrations/empty_state_generic.svg',
                  ),
                );
              }
              return workoutCountsAsync.when(
                data: (workoutCounts) {
                  final favoriteIds = favoritesAsync.value ?? <String>{};
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                    child: ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: spacing.sm),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final count = workoutCounts[ex.id] ?? 0;
                        final isFavorite = favoriteIds.contains(ex.id);
                        return AppListEntryAnimation(
                          index: index,
                          child: ExerciseListTile(
                            name: ex.name,
                            bodyPart: ex.bodyPart,
                            thumbnailPath: ex.thumbnailPath,
                            onTap: () => context.push('/exercise/${ex.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0)
                                  AppText(
                                    count.toString(),
                                    style: AppTextStyle.label,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  color: isFavorite
                                      ? colors.error
                                      : colors.outline,
                                  onPressed: () {
                                    ref
                                        .read(
                                            exerciseFavoritesProvider.notifier)
                                        .toggleFavorite(ex.id);
                                  },
                                  tooltip: isFavorite
                                      ? 'Remove from favourites'
                                      : 'Add to favourites',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return ExerciseListTile(
                        name: ex.name,
                        bodyPart: ex.bodyPart,
                        thumbnailPath: ex.thumbnailPath,
                        onTap: () => context.push('/exercise/${ex.id}'),
                      );
                    },
                  ),
                ),
                error: (_, __) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return ExerciseListTile(
                        name: ex.name,
                        bodyPart: ex.bodyPart,
                        thumbnailPath: ex.thumbnailPath,
                        onTap: () => context.push('/exercise/${ex.id}'),
                      );
                    },
                  ),
                ),
              );
            },

            // 2) Loading: shimmer list skeleton
            loading: () => const AppLoadingState(
              useShimmer: true,
              variant: AppLoadingVariant.list,
            ),

            // 3) Error: simple scaffold with message
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  /// Get display label for sort order
  String _getSortLabel(ExerciseSortOrder order) {
    switch (order) {
      case ExerciseSortOrder.nameAsc:
      case ExerciseSortOrder.nameDesc:
        return 'Name';
      case ExerciseSortOrder.bodyPartAsc:
      case ExerciseSortOrder.bodyPartDesc:
        return 'Body Part';
      case ExerciseSortOrder.equipmentAsc:
      case ExerciseSortOrder.equipmentDesc:
        return 'Equipment';
      case ExerciseSortOrder.frequencyAsc:
      case ExerciseSortOrder.frequencyDesc:
        return 'Frequency';
      case ExerciseSortOrder.recentAsc:
      case ExerciseSortOrder.recentDesc:
        return 'Recent';
    }
  }

  /// Check if sort order is ascending
  bool _isSortAscending(ExerciseSortOrder order) {
    switch (order) {
      case ExerciseSortOrder.nameAsc:
      case ExerciseSortOrder.bodyPartAsc:
      case ExerciseSortOrder.equipmentAsc:
      case ExerciseSortOrder.frequencyAsc:
      case ExerciseSortOrder.recentAsc:
        return true;
      case ExerciseSortOrder.nameDesc:
      case ExerciseSortOrder.bodyPartDesc:
      case ExerciseSortOrder.equipmentDesc:
      case ExerciseSortOrder.frequencyDesc:
      case ExerciseSortOrder.recentDesc:
        return false;
    }
  }

  /// Get sort order from label and direction
  ExerciseSortOrder _getSortOrderFromLabel(String label, bool ascending) {
    switch (label) {
      case 'Name':
        return ascending
            ? ExerciseSortOrder.nameAsc
            : ExerciseSortOrder.nameDesc;
      case 'Body Part':
        return ascending
            ? ExerciseSortOrder.bodyPartAsc
            : ExerciseSortOrder.bodyPartDesc;
      case 'Equipment':
        return ascending
            ? ExerciseSortOrder.equipmentAsc
            : ExerciseSortOrder.equipmentDesc;
      case 'Frequency':
        return ascending
            ? ExerciseSortOrder.frequencyAsc
            : ExerciseSortOrder.frequencyDesc;
      case 'Recent':
        return ascending
            ? ExerciseSortOrder.recentAsc
            : ExerciseSortOrder.recentDesc;
      default:
        return ExerciseSortOrder.nameAsc;
    }
  }

  /// Get list of sort option labels
  List<String> _getExerciseSortOptions() {
    return ['Name', 'Body Part', 'Equipment', 'Frequency', 'Recent'];
  }
}
