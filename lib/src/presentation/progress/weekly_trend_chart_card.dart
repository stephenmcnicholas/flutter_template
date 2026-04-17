import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/format_utils.dart';

/// Weekly bar chart (sessions or volume) for the Progress → Workout Frequency tab.
class WeeklyTrendChartCard extends ConsumerWidget {
  const WeeklyTrendChartCard({super.key});

  static double _volumeDisplayKg(double volumeKg, WeightUnit unit) {
    return convertWeightToDisplay(volumeKg, unit);
  }

  static String _formatYAxis(double value, ProgressWeeklyMetric metric) {
    if (metric == ProgressWeeklyMetric.sessions) {
      return value.round().toString();
    }
    if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final typography = context.themeExt<AppTypography>();
    final radii = context.themeExt<AppRadii>();
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final seriesAsync = ref.watch(weeklyTrendProvider);
    final metric = ref.watch(progressWeeklyMetricProvider);
    final metricNotifier = ref.read(progressWeeklyMetricProvider.notifier);
    final units = ref.watch(unitSettingsProvider);
    final weightUnit = units.weightUnit;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            'Training trend',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.sm),
          SegmentedButton<ProgressWeeklyMetric>(
              segments: const [
                ButtonSegment<ProgressWeeklyMetric>(
                  value: ProgressWeeklyMetric.sessions,
                  label: Text('Sessions'),
                  icon: Icon(Icons.fitness_center, size: 18),
                ),
                ButtonSegment<ProgressWeeklyMetric>(
                  value: ProgressWeeklyMetric.volume,
                  label: Text('Volume'),
                  icon: Icon(Icons.bar_chart, size: 18),
                ),
              ],
              selected: {metric},
              onSelectionChanged: (selected) {
                metricNotifier.setMetric(selected.single);
              },
            ),
          SizedBox(height: spacing.md),
          seriesAsync.when(
            data: (series) {
              if (series.isEmpty) {
                return AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: AppEmptyState(
                      title: 'No data yet',
                      message:
                          'Log a workout to see your last $kProgressWeeklyTrendWeekCount weeks.',
                      icon: Icons.show_chart,
                    ),
                  ),
                );
              }

              final n = series.weeks.length;
              final values = metric == ProgressWeeklyMetric.sessions
                  ? series.weeks.map((w) => w.sessionCount.toDouble()).toList()
                  : series.weeks
                      .map((w) => _volumeDisplayKg(w.volumeKg, weightUnit))
                      .toList();

              final dataMax = values.reduce((a, b) => a > b ? a : b);
              final maxY = dataMax <= 0
                  ? 1.0
                  : (dataMax * 1.15).ceilToDouble();
              final interval = _niceYInterval(maxY, metric);

              return AppCard(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.lg,
                    spacing.lg,
                    spacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: colors.outline.withValues(alpha: 0.4),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.4),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipRoundedRadius: radii.sm,
                                tooltipBgColor: colorScheme.surfaceContainerLow,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final i = group.x.toInt();
                                  if (i < 0 || i >= n) {
                                    return null;
                                  }
                                  final w = series.weeks[i];
                                  final start = w.weekStartMonday;
                                  final end =
                                      start.add(const Duration(days: 6));
                                  final range =
                                      '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(end)}';
                                  String valueLabel;
                                  if (metric == ProgressWeeklyMetric.sessions) {
                                    final c = w.sessionCount;
                                    valueLabel =
                                        '$c workout${c == 1 ? '' : 's'}';
                                  } else {
                                    final v = _volumeDisplayKg(
                                      w.volumeKg,
                                      weightUnit,
                                    );
                                    valueLabel =
                                        '${_formatYAxis(v, metric)} ${weightUnitLabel(weightUnit)} load (approx.)';
                                  }
                                  return BarTooltipItem(
                                    '$range\n$valueLabel',
                                    typography.caption.copyWith(color: onSurface),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    if (value > maxY) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      _formatYAxis(value, metric),
                                      style: typography.caption.copyWith(
                                        color: onSurface.withValues(alpha: 0.7),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= n) {
                                      return const SizedBox.shrink();
                                    }
                                    if (!_showXLabel(i, n)) {
                                      return const SizedBox.shrink();
                                    }
                                    final d = series.weeks[i].weekStartMonday;
                                    return Padding(
                                      padding: EdgeInsets.only(top: spacing.xs),
                                      child: Text(
                                        DateFormat('d MMM').format(d),
                                        style: typography.caption.copyWith(
                                          color: onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(
                              n,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: values[i] > 0 ? values[i] : 0,
                                    color: colors.primary,
                                    width: 10,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(radii.xs),
                                      topRight: Radius.circular(radii.xs),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      AppText(
                        metric == ProgressWeeklyMetric.sessions
                            ? 'Each bar is how many workouts you logged that week (Mon–Sun).'
                            : 'Total weight × reps for the week, shown in ${weightUnitLabel(weightUnit)} (strength sets; time/distance work may show as 0).',
                        style: AppTextStyle.caption,
                        color: colors.outline,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const AppCard(
              child: AppLoadingState(
                useShimmer: true,
                variant: AppLoadingVariant.card,
              ),
            ),
            error: (e, _) => AppCard(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: AppEmptyState(
                  title: 'Could not load trend',
                  message: e.toString(),
                  icon: Icons.error_outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _showXLabel(int index, int total) {
    if (total <= 4) return true;
    final step = (total / 4).ceil();
    return index % step == 0 || index == total - 1;
  }

  static double _niceYInterval(double maxY, ProgressWeeklyMetric metric) {
    if (maxY <= 0) return 1;
    if (metric == ProgressWeeklyMetric.sessions) {
      final raw = maxY / 4;
      if (raw <= 1) return 1;
      return raw.ceilToDouble();
    }
    final raw = maxY / 4;
    final pow10 = _magnitude(raw);
    final n = raw / pow10;
    double nice;
    if (n <= 1) {
      nice = 1 * pow10;
    } else if (n <= 2) {
      nice = 2 * pow10;
    } else if (n <= 5) {
      nice = 5 * pow10;
    } else {
      nice = 10 * pow10;
    }
    return nice;
  }

  static double _magnitude(double x) {
    if (x <= 0) return 1;
    var m = 1.0;
    while (m * 10 <= x) {
      m *= 10;
    }
    while (m > x) {
      m /= 10;
    }
    return m;
  }
}
