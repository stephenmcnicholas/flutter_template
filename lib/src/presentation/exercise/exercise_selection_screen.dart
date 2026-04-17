import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/filter_sort_providers.dart';
//import '../../providers/exercise_favorites_provider.dart';
import '../../providers/exercise_history_provider.dart';
import '../shared/app_text.dart';
import '../shared/app_filter_sort_bar.dart';
import '../shared/exercise_list_tile.dart';
import '../theme.dart';

/// A screen for selecting exercises with filter/sort capabilities.
/// Used when adding exercises to workout templates.
class ExerciseSelectionScreen extends ConsumerStatefulWidget {
  /// List of exercise IDs that are already selected (will be shown as disabled)
  final List<String> alreadySelectedIds;
  final bool singleSelection;
  final String title;
  final String actionLabel;
  /// Confirm button is enabled only when at least this many exercises are selected.
  final int minRequired;

  const ExerciseSelectionScreen({
    super.key,
    this.alreadySelectedIds = const [],
    this.singleSelection = false,
    this.title = 'Add Exercises',
    this.actionLabel = 'Add',
    this.minRequired = 1,
  });

  @override
  ConsumerState<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState
    extends ConsumerState<ExerciseSelectionScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Reset filters when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseFilterTextProvider.notifier).state = '';
      ref.read(exerciseBodyPartFilterProvider.notifier).state = [];
      ref.read(exerciseEquipmentFilterProvider.notifier).state = [];
      ref.read(exerciseFavoriteFilterProvider.notifier).state = false;
      ref.read(exerciseSortOrderProvider.notifier).state =
          ExerciseSortOrder.nameAsc;
    });
  }

  void _toggleSelection(String exerciseId) {
    // Don't allow toggling already-selected exercises
    if (widget.alreadySelectedIds.contains(exerciseId)) {
      return;
    }

    setState(() {
      if (widget.singleSelection) {
        if (_selectedIds.contains(exerciseId)) {
          _selectedIds.remove(exerciseId);
        } else {
          _selectedIds
            ..clear()
            ..add(exerciseId);
        }
        return;
      }
      if (_selectedIds.contains(exerciseId)) {
        _selectedIds.remove(exerciseId);
      } else {
        _selectedIds.add(exerciseId);
      }
    });
  }

  void _onDone() {
    if (_selectedIds.length >= widget.minRequired) {
      context.pop(_selectedIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(filteredSortedExercisesProvider);
    final workoutCountsAsync = ref.watch(exerciseWorkoutCountProvider);
    final filterText = ref.watch(exerciseFilterTextProvider);
    final sortOrder = ref.watch(exerciseSortOrderProvider);
    final favoriteOnly = ref.watch(exerciseFavoriteFilterProvider);
    final bodyAreaRegions = ref.watch(exerciseBodyRegionChoicesProvider);
    final equipmentOptionsAsync = ref.watch(availableEquipmentOptionsProvider);

    // Helper to get sort label and direction
    final sortLabel = _getSortLabel(sortOrder);
    final isAscending = _isSortAscending(sortOrder);
    final sortOptions = _getExerciseSortOptions();

    final bodyPartFilter = ref.watch(exerciseBodyPartFilterProvider);
    final equipmentFilter = ref.watch(exerciseEquipmentFilterProvider);
    final hasActiveFilters = filterText.isNotEmpty ||
        favoriteOnly ||
        bodyPartFilter.isNotEmpty ||
        equipmentFilter.isNotEmpty;
    final colors = context.themeExt<AppColors>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          TextButton(
            onPressed: _selectedIds.length >= widget.minRequired ? _onDone : null,
            child: Text('${widget.actionLabel} (${_selectedIds.length})'),
          ),
        ],
      ),
      body: Column(
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
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Text(
                      hasActiveFilters
                          ? 'No exercises match your filters.'
                          : 'No exercises found.',
                    ),
                  );
                }
                return workoutCountsAsync.when(
                  data: (workoutCounts) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.separated(
                        itemCount: exercises.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          final isAlreadySelected =
                              widget.alreadySelectedIds.contains(ex.id);
                          final isSelected = _selectedIds.contains(ex.id);
                          final isDisabled = isAlreadySelected;
                          final count = workoutCounts[ex.id] ?? 0;

                          // Build trailing widget: show count and/or checkmark
                          Widget? trailingWidget;
                          if (isSelected) {
                            // Selected: show checkmark and count (if count > 0)
                            trailingWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0) ...[
                                  AppText(
                                    count.toString(),
                                    style: AppTextStyle.label,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  Icons.check_circle,
                                  color: colors.primary,
                                ),
                              ],
                            );
                          } else if (isDisabled) {
                            // Disabled: show checkmark and count (if count > 0)
                            trailingWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0) ...[
                                  AppText(
                                    count.toString(),
                                    style: AppTextStyle.label,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  Icons.check_circle,
                                  color: colors.outline,
                                ),
                              ],
                            );
                          } else if (count > 0) {
                            // Not selected/disabled: show count only
                            trailingWidget = AppText(
                              count.toString(),
                              style: AppTextStyle.label,
                            );
                          }

                          return ExerciseListTile(
                            name: ex.name,
                            bodyPart: ex.bodyPart,
                            thumbnailPath: ex.thumbnailPath,
                            trailing: trailingWidget,
                            onTap: () => _toggleSelection(ex.id),
                            selected: isSelected,
                            disabled: isDisabled,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final isAlreadySelected =
                            widget.alreadySelectedIds.contains(ex.id);
                        final isSelected = _selectedIds.contains(ex.id);
                        final isDisabled = isAlreadySelected;
                        Widget? trailingWidget;
                        if (isSelected) {
                          trailingWidget = Icon(
                            Icons.check_circle,
                            color: colors.primary,
                          );
                        } else if (isDisabled) {
                          trailingWidget = Icon(
                            Icons.check_circle,
                            color: colors.outline,
                          );
                        }

                        return ExerciseListTile(
                          name: ex.name,
                          bodyPart: ex.bodyPart,
                          thumbnailPath: ex.thumbnailPath,
                          trailing: trailingWidget,
                          onTap: () => _toggleSelection(ex.id),
                          selected: isSelected,
                          disabled: isDisabled,
                        );
                      },
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final isAlreadySelected =
                            widget.alreadySelectedIds.contains(ex.id);
                        final isSelected = _selectedIds.contains(ex.id);
                        final isDisabled = isAlreadySelected;
                        Widget? trailingWidget;
                        if (isSelected) {
                          trailingWidget = Icon(
                            Icons.check_circle,
                            color: colors.primary,
                          );
                        } else if (isDisabled) {
                          trailingWidget = Icon(
                            Icons.check_circle,
                            color: colors.outline,
                          );
                        }

                        return ExerciseListTile(
                          name: ex.name,
                          bodyPart: ex.bodyPart,
                          thumbnailPath: ex.thumbnailPath,
                          trailing: trailingWidget,
                          onTap: () => _toggleSelection(ex.id),
                          selected: isSelected,
                          disabled: isDisabled,
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
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
