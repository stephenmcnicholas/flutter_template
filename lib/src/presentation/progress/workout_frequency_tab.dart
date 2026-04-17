import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/progress/weekly_trend_chart_card.dart';
import 'package:fytter/src/presentation/theme.dart';

enum _CalendarMarker { completed, planned }

class WorkoutFrequencyTab extends ConsumerStatefulWidget {
  final DateTime? initialFocusedDay;

  const WorkoutFrequencyTab({super.key, this.initialFocusedDay});

  @override
  ConsumerState<WorkoutFrequencyTab> createState() => _WorkoutFrequencyTabState();
}

class _WorkoutFrequencyTabState extends ConsumerState<WorkoutFrequencyTab> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final frequencyAsync = ref.watch(workoutFrequencyProvider);
    final programsAsync = ref.watch(programsFutureProvider);

    return frequencyAsync.when(
      data: (frequency) {
        final programs = programsAsync.valueOrNull ?? [];
        final plannedDates = <DateTime>{};
        for (final program in programs) {
          for (final workout in program.schedule) {
            plannedDates.add(
              DateTime(
                workout.scheduledDate.year,
                workout.scheduledDate.month,
                workout.scheduledDate.day,
              ),
            );
          }
        }
        final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
        final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
        final monthEnd = DateTime(_focusedDay.year, _focusedDay.month, daysInMonth);
        final totalWorkoutsInMonth = frequency.workoutsPerDay.entries
            .where((entry) => !entry.key.isBefore(monthStart) && !entry.key.isAfter(monthEnd))
            .fold<int>(0, (sum, entry) => sum + entry.value);
        final now = DateTime.now();
        final isCurrentMonth = now.year == _focusedDay.year && now.month == _focusedDay.month;
        final daysElapsed = isCurrentMonth ? now.day : daysInMonth;
        final weeksElapsed = daysElapsed / 7;
        final averageWorkoutsPerWeek =
            totalWorkoutsInMonth == 0 ? 0.0 : totalWorkoutsInMonth / weeksElapsed;
        return SingleChildScrollView(
          child: Column(
            children: [
              // Summary cards
              Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Workouts',
                          totalWorkoutsInMonth.toString(),
                          Icons.fitness_center,
                        ),
                      ),
                      SizedBox(width: spacing.lg),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Avg/Week',
                          averageWorkoutsPerWeek.toStringAsFixed(1),
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const WeeklyTrendChartCard(),
              // Calendar
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                onPageChanged: (day) => setState(() => _focusedDay = day),
                onDaySelected: (selectedDay, focusedDay) {
                  final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  final count = frequency.workoutsPerDay[dayKey] ?? 0;
                  if (count > 0) {
                    ref.read(workoutSessionDateFilterProvider.notifier).state = dayKey;
                    ref.read(selectedTabIndexProvider.notifier).state = 1;
                    return;
                  }
                  if (plannedDates.contains(dayKey)) {
                    ref.read(programDateFilterProvider.notifier).state = dayKey;
                    ref.read(selectedTabIndexProvider.notifier).state = 2;
                  }
                },
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  final count = frequency.workoutsPerDay[date] ?? 0;
                  final markers = <_CalendarMarker>[];
                  if (count > 0) {
                    markers.add(_CalendarMarker.completed);
                  }
                  if (count == 0 && plannedDates.contains(date)) {
                    markers.add(_CalendarMarker.planned);
                  }
                  return markers;
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    final markers = events.cast<_CalendarMarker>();
                    if (markers.contains(_CalendarMarker.completed)) {
                      return Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.success.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: spacing.sm,
                        height: spacing.sm,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.secondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const AppLoadingState(
        useShimmer: true,
        variant: AppLoadingVariant.card,
      ),
      error: (error, stack) => AppEmptyState(
        title: 'Unable to load progress',
        message: error.toString(),
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colors.primary),
            SizedBox(height: spacing.sm),
            AppText(
              title,
              style: AppTextStyle.label,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.xs),
            AppText(
              value,
              style: AppTextStyle.headline,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 