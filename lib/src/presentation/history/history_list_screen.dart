// lib/src/presentation/history/history_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/shared/app_filter_sort_bar.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_list_entry_animation.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/format_utils.dart';

/// Displays a list of all past workouts, allowing the user to tap
/// into details for each one.
class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    // Watch the new provider for sorted and filtered sessions
    final historyAsync = ref.watch(filteredSortedWorkoutSessionsProvider);
    final filterText = ref.watch(workoutSessionFilterTextProvider);
    final sortOrder = ref.watch(workoutSessionSortOrderProvider);
    final dateFilter = ref.watch(workoutSessionDateFilterProvider);
    final bodyAreaRegions = ref.watch(exerciseBodyRegionChoicesProvider);
    final equipmentOptionsAsync = ref.watch(availableEquipmentOptionsProvider);

    // Helper to get sort label and direction
    final sortLabel = _getSortLabel(sortOrder);
    final isAscending = _isSortAscending(sortOrder);
    final sortOptions = _getWorkoutSortOptions();

    final bodyPartFilter = ref.watch(workoutSessionBodyPartFilterProvider);
    final equipmentFilter = ref.watch(workoutSessionEquipmentFilterProvider);
    final hasActiveFilters = filterText.isNotEmpty ||
        bodyPartFilter.isNotEmpty ||
        equipmentFilter.isNotEmpty ||
        dateFilter != null;

    return Column(
      children: [
        AppFilterSortBar(
          filterText: filterText,
          onFilterChanged: (value) {
            ref.read(workoutSessionFilterTextProvider.notifier).state = value;
          },
          currentSortLabel: sortLabel,
          isAscending: isAscending,
          sortOptions: sortOptions,
          onSortOptionSelected: (option, ascending) {
            final newOrder = _getSortOrderFromLabel(option, ascending);
            ref.read(workoutSessionSortOrderProvider.notifier).state = newOrder;
          },
          searchPlaceholder: 'Filter by workout or exercise',
          currentBodyAreaFilter: bodyPartFilter,
          bodyAreaRegions: bodyAreaRegions,
          currentEquipmentFilter: equipmentFilter,
          equipmentOptions: equipmentOptionsAsync.valueOrNull ?? const [],
          onBodyAreaFilterChanged: (values) {
            ref.read(workoutSessionBodyPartFilterProvider.notifier).state = values;
          },
          onEquipmentFilterChanged: (values) {
            ref.read(workoutSessionEquipmentFilterProvider.notifier).state = values;
          },
        ),
        if (dateFilter != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.sm,
            ),
            child: AppCard(
              compact: true,
              child: AppListRow(
                dense: true,
                title: AppText(
                  'Filtered: ${DateFormat('d MMM, yyyy').format(dateFilter)}',
                  style: AppTextStyle.caption,
                ),
                trailing: TextButton(
                  onPressed: () => ref.read(workoutSessionDateFilterProvider.notifier).state = null,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg),
            child: historyAsync.when(
              data: (List<WorkoutSession> sessions) {
                if (sessions.isEmpty) {
                  return AppEmptyState(
                    title: hasActiveFilters
                        ? 'No workouts found'
                        : 'No workouts yet',
                    message: hasActiveFilters
                        ? 'Try adjusting your filters.'
                        : 'Log your first workout to see it here.',
                    illustrationAsset: hasActiveFilters
                        ? 'assets/illustrations/empty_state_search.svg'
                        : 'assets/illustrations/empty_state_generic.svg',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.only(top: spacing.md),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final formattedDateTime =
                            DateFormat('d MMM, yyyy • HH:mm').format(session.date);
                    final sessionName = session.name?.isNotEmpty == true
                        ? session.name!
                            : DateFormat('d MMM, yyyy').format(session.date);
                    return AppListEntryAnimation(
                      index: index,
                      child: AppCard(
                        compact: true,
                        onTap: () => context.push('/history/${session.id}'),
                        child: AppListRow(
                          dense: true,
                          title: AppText(sessionName, style: AppTextStyle.label),
                          subtitle: _HistoryStats(
                            formattedDateTime: formattedDateTime,
                            setCount: session.entries.length,
                            totalDurationSeconds: session.entries.fold<int>(
                              0,
                              (sum, entry) => sum + (entry.duration ?? 0),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () {
                // debugPrint('HistoryListScreen: loading branch');
                return const AppLoadingState(
                  useShimmer: true,
                  variant: AppLoadingVariant.list,
                );
              },
              error: (_, __) {
                return AppEmptyState(
                  title: 'Unable to load workouts',
                  message: 'Something went wrong. Please try again.',
                  icon: Icons.error_outline,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Get display label for sort order
  String _getSortLabel(WorkoutSessionSortOrder order) {
    switch (order) {
      case WorkoutSessionSortOrder.dateNewest:
      case WorkoutSessionSortOrder.dateOldest:
        return 'Date';
      case WorkoutSessionSortOrder.nameAsc:
      case WorkoutSessionSortOrder.nameDesc:
        return 'Name';
      case WorkoutSessionSortOrder.volumeHighest:
      case WorkoutSessionSortOrder.volumeLowest:
        return 'Volume';
      case WorkoutSessionSortOrder.durationLongest:
      case WorkoutSessionSortOrder.durationShortest:
        return 'Duration';
    }
  }

  /// Check if sort order is ascending
  bool _isSortAscending(WorkoutSessionSortOrder order) {
    switch (order) {
      case WorkoutSessionSortOrder.dateNewest:
      case WorkoutSessionSortOrder.nameAsc:
      case WorkoutSessionSortOrder.volumeHighest:
      case WorkoutSessionSortOrder.durationLongest:
        return false; // These are "highest first" which is descending
      case WorkoutSessionSortOrder.dateOldest:
      case WorkoutSessionSortOrder.nameDesc:
      case WorkoutSessionSortOrder.volumeLowest:
      case WorkoutSessionSortOrder.durationShortest:
        return true;
    }
  }

  /// Get sort order from label and direction
  WorkoutSessionSortOrder _getSortOrderFromLabel(String label, bool ascending) {
    switch (label) {
      case 'Date':
        return ascending ? WorkoutSessionSortOrder.dateOldest : WorkoutSessionSortOrder.dateNewest;
      case 'Name':
        return ascending ? WorkoutSessionSortOrder.nameAsc : WorkoutSessionSortOrder.nameDesc;
      case 'Volume':
        return ascending ? WorkoutSessionSortOrder.volumeLowest : WorkoutSessionSortOrder.volumeHighest;
      case 'Duration':
        return ascending ? WorkoutSessionSortOrder.durationShortest : WorkoutSessionSortOrder.durationLongest;
      default:
        return WorkoutSessionSortOrder.dateNewest;
    }
  }

  /// Get list of sort option labels
  List<String> _getWorkoutSortOptions() {
    return ['Date', 'Name', 'Volume', 'Duration'];
  }

}

class _HistoryStats extends StatelessWidget {
  final String formattedDateTime;
  final int setCount;
  final int totalDurationSeconds;

  const _HistoryStats({
    required this.formattedDateTime,
    required this.setCount,
    required this.totalDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          formattedDateTime,
          style: AppTextStyle.caption,
          color: onSurface.withValues(alpha: 0.7),
        ),
        SizedBox(height: spacing.xs),
        AppStatsRow(
          items: [
            AppStatItem(label: 'Sets', value: setCount.toString()),
            AppStatItem(label: 'Time', value: formatDuration(totalDurationSeconds)),
          ],
        ),
      ],
    );
  }
}