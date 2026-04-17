import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_tap_feedback.dart';
import 'package:fytter/src/presentation/theme.dart';

enum _ProgressMetric {
  weight,
  reps,
  distance,
  time,
}

class ExerciseProgressChart extends StatefulWidget {
  final Exercise exercise;
  final List<ExerciseWorkoutHistory> history;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;

  const ExerciseProgressChart({
    super.key,
    required this.exercise,
    required this.history,
    required this.weightUnit,
    required this.distanceUnit,
  });

  @override
  State<ExerciseProgressChart> createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends State<ExerciseProgressChart> {
  _ProgressMetric? _selectedMetric;

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return const Center(child: AppText('No exercise data available', style: AppTextStyle.body));
    }

    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final typography = context.themeExt<AppTypography>();
    final radii = context.themeExt<AppRadii>();
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final inputType = getExerciseInputType(widget.exercise);
    final points = _buildProgressPoints(widget.history);
    if (points.isEmpty) {
      return const Center(child: AppText('No workout data available', style: AppTextStyle.body));
    }

    final startDate = points.first.date;
    final endDate = points.last.date;
    final totalDays = math.max(0, endDate.difference(startDate).inDays);

    final selectedMetric = _selectedMetric ?? _defaultMetricFor(inputType);
    final seriesValues = _collectSeriesValues(
      points,
      inputType,
      selectedMetric,
      widget.weightUnit,
      widget.distanceUnit,
    );
    final minValue = seriesValues.isEmpty ? 0.0 : seriesValues.reduce(math.min);
    final maxValue = seriesValues.isEmpty ? 0.0 : seriesValues.reduce(math.max);
    final prValue = seriesValues.isEmpty ? null : maxValue;
    final range = _chartRange(minValue, maxValue);
    final interval = _niceInterval(range / 4);
    final minY = minValue < 0 ? _floorToInterval(minValue, interval) : 0.0;
    final maxY = _ceilToInterval(maxValue, interval);
    final chartMaxY = maxY == minY ? minY + interval : maxY;
    final xLabelInterval = _labelInterval(totalDays + 1, targetLabels: 4);

    final lineBars = <LineChartBarData>[];
    final legendItems = <Widget>[];

    switch (inputType) {
      case ExerciseInputType.repsAndWeight:
        if (selectedMetric == _ProgressMetric.weight) {
          lineBars.add(_buildLine(
            points
                .map((p) => FlSpot(
                      p.xValue,
                      convertWeightToDisplay(p.weight, widget.weightUnit),
                    ))
                .toList(),
            colors.primary,
            prValue: prValue,
            prColor: colors.success,
          ));
        } else {
          lineBars.add(_buildLine(
            points.map((p) => FlSpot(p.xValue, p.reps.toDouble())).toList(),
            colors.secondary,
            prValue: prValue,
            prColor: colors.success,
          ));
        }
        legendItems.addAll([
          _buildLegendItem(
            'Weight (${weightUnitLabel(widget.weightUnit)})',
            colors.primary,
            active: selectedMetric == _ProgressMetric.weight,
            onTap: () => _setSelectedMetric(_ProgressMetric.weight),
          ),
          SizedBox(width: spacing.lg),
          _buildLegendItem(
            'Reps',
            colors.secondary,
            active: selectedMetric == _ProgressMetric.reps,
            onTap: () => _setSelectedMetric(_ProgressMetric.reps),
          ),
        ]);
        break;
      case ExerciseInputType.repsOnly:
        lineBars.add(_buildLine(
          points.map((p) => FlSpot(p.xValue, p.reps.toDouble())).toList(),
          colors.secondary,
          prValue: prValue,
          prColor: colors.success,
        ));
        legendItems.add(_buildLegendItem('Reps', colors.secondary, active: true));
        break;
      case ExerciseInputType.distanceAndTime:
        if (selectedMetric == _ProgressMetric.distance) {
          lineBars.add(_buildLine(
            points
                .map((p) => FlSpot(
                      p.xValue,
                      convertDistanceToDisplay(p.distance, widget.distanceUnit),
                    ))
                .toList(),
            colors.primary,
            prValue: prValue,
            prColor: colors.success,
          ));
        } else {
          lineBars.add(_buildLine(
            points.map((p) => FlSpot(p.xValue, p.durationMinutes)).toList(),
            colors.secondary,
            prValue: prValue,
            prColor: colors.success,
          ));
        }
        legendItems.addAll([
          _buildLegendItem(
            'Distance (${distanceUnitLabel(widget.distanceUnit)})',
            colors.primary,
            active: selectedMetric == _ProgressMetric.distance,
            onTap: () => _setSelectedMetric(_ProgressMetric.distance),
          ),
          SizedBox(width: spacing.lg),
          _buildLegendItem(
            'Time (min)',
            colors.secondary,
            active: selectedMetric == _ProgressMetric.time,
            onTap: () => _setSelectedMetric(_ProgressMetric.time),
          ),
        ]);
        break;
      case ExerciseInputType.timeOnly:
        lineBars.add(_buildLine(
          points.map((p) => FlSpot(p.xValue, p.durationMinutes)).toList(),
          colors.secondary,
          prValue: prValue,
          prColor: colors.success,
        ));
        legendItems.add(_buildLegendItem('Time (min)', colors.secondary, active: true));
        break;
    }

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        AppCard(
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  widget.exercise.name,
                  style: AppTextStyle.title,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: spacing.lg),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      backgroundColor: colors.surface,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colors.outline.withValues(alpha: 0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      minY: minY,
                      maxY: chartMaxY,
                      minX: 0,
                      maxX: totalDays.toDouble(),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: colorScheme.surfaceContainerLow,
                          tooltipRoundedRadius: radii.sm,
                          getTooltipItems: (items) {
                            return items.map((item) {
                              return LineTooltipItem(
                                item.y.toStringAsFixed(1),
                                typography.caption.copyWith(
                                  color: onSurface,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatYAxisValue(value, inputType, selectedMetric, range),
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
                            interval: xLabelInterval.toDouble(),
                            getTitlesWidget: (value, meta) {
                              final dayIndex = value.toInt();
                              if (dayIndex < 0 || dayIndex > totalDays) {
                                return const SizedBox.shrink();
                              }
                              if (!_shouldShowXLabel(dayIndex, totalDays, xLabelInterval)) {
                                return const SizedBox.shrink();
                              }
                              final date = startDate.add(Duration(days: dayIndex));
                              return Padding(
                                padding: EdgeInsets.only(top: spacing.sm),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
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
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      lineBarsData: lineBars,
                    ),
                  ),
                ),
                SizedBox(height: spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: legendItems,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine(
    List<FlSpot> spots,
    Color color, {
    double? prValue,
    Color? prColor,
  }) {
    const prEpsilon = 0.0001;
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final isPr = prValue != null && (spot.y - prValue).abs() <= prEpsilon;
          final dotColor = isPr ? (prColor ?? color) : color;
          return FlDotCirclePainter(
            radius: isPr ? 5 : 3.5,
            color: dotColor,
            strokeWidth: isPr ? 2 : 0,
            strokeColor: isPr
                ? dotColor.withValues(alpha: 0.35)
                : Colors.transparent,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.12),
      ),
    );
  }

  List<_ProgressPoint> _buildProgressPoints(List<ExerciseWorkoutHistory> history) {
    final dailyMap = <DateTime, _ProgressPoint>{};
    for (final item in history) {
      for (final entry in item.entries) {
        if (!entry.isComplete) {
          continue;
        }
        final date = entry.timestamp ?? item.session.date;
        final dayKey = DateTime(date.year, date.month, date.day);
        final existing = dailyMap[dayKey];
        final weight = entry.weight;
        final reps = entry.reps;
        final distance = entry.distance ?? 0.0;
        final durationSeconds = entry.duration ?? 0;
        if (existing == null) {
          dailyMap[dayKey] = _ProgressPoint(
            date: dayKey,
            weight: weight,
            reps: reps,
            distance: distance,
            durationSeconds: durationSeconds,
          );
        } else {
          dailyMap[dayKey] = existing.copyWith(
            weight: math.max(existing.weight, weight),
            reps: math.max(existing.reps, reps),
            distance: math.max(existing.distance, distance),
            durationSeconds: math.max(existing.durationSeconds, durationSeconds),
          );
        }
      }
    }
    final entries = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (entries.isEmpty) {
      return entries;
    }
    final startDate = entries.first.date;
    for (var i = 0; i < entries.length; i++) {
      final dayIndex = entries[i].date.difference(startDate).inDays.toDouble();
      entries[i] = entries[i].copyWith(xValue: dayIndex);
    }
    return entries;
  }

  List<double> _collectSeriesValues(
    List<_ProgressPoint> points,
    ExerciseInputType inputType,
    _ProgressMetric selectedMetric,
    WeightUnit weightUnit,
    DistanceUnit distanceUnit,
  ) {
    switch (inputType) {
      case ExerciseInputType.repsAndWeight:
        return selectedMetric == _ProgressMetric.weight
            ? [for (final point in points) convertWeightToDisplay(point.weight, weightUnit)]
            : [for (final point in points) point.reps.toDouble()];
      case ExerciseInputType.repsOnly:
        return [for (final point in points) point.reps.toDouble()];
      case ExerciseInputType.distanceAndTime:
        return selectedMetric == _ProgressMetric.distance
            ? [for (final point in points) convertDistanceToDisplay(point.distance, distanceUnit)]
            : [for (final point in points) point.durationMinutes];
      case ExerciseInputType.timeOnly:
        return [for (final point in points) point.durationMinutes];
    }
  }

  double _chartRange(double minValue, double maxValue) {
    final range = (maxValue - minValue).abs();
    if (range == 0) {
      return maxValue == 0 ? 1.0 : maxValue.abs();
    }
    return range;
  }

  double _niceInterval(double roughInterval) {
    if (roughInterval <= 0) {
      return 1.0;
    }
    final exponent = math.pow(10, (math.log(roughInterval) / math.ln10).floor()).toDouble();
    final fraction = roughInterval / exponent;
    final niceFraction = fraction <= 1
        ? 1
        : fraction <= 2
            ? 2
            : fraction <= 5
                ? 5
                : 10;
    return niceFraction * exponent;
  }

  double _floorToInterval(double value, double interval) {
    if (interval == 0) {
      return value;
    }
    return (value / interval).floorToDouble() * interval;
  }

  double _ceilToInterval(double value, double interval) {
    if (interval == 0) {
      return value;
    }
    return (value / interval).ceilToDouble() * interval;
  }

  int _labelInterval(int count, {int targetLabels = 4}) {
    if (count <= targetLabels) return 1;
    return (count / targetLabels).ceil();
  }

  bool _shouldShowXLabel(int dayIndex, int totalDays, int interval) {
    if (dayIndex == 0 || dayIndex == totalDays) return true;
    return dayIndex % interval == 0;
  }

  String _formatYAxisValue(
    double value,
    ExerciseInputType inputType,
    _ProgressMetric selectedMetric,
    double range,
  ) {
    switch (inputType) {
      case ExerciseInputType.repsOnly:
        return _formatNumber(value, 0);
      case ExerciseInputType.timeOnly:
        return _formatNumber(value, range <= 5 ? 1 : 0);
      case ExerciseInputType.repsAndWeight:
        return selectedMetric == _ProgressMetric.reps
            ? _formatNumber(value, 0)
            : _formatNumber(value, range <= 5 ? 1 : 0);
      case ExerciseInputType.distanceAndTime:
        return selectedMetric == _ProgressMetric.distance
            ? _formatNumber(value, range <= 5 ? 1 : 0)
            : _formatNumber(value, range <= 5 ? 1 : 0);
    }
  }

  String _formatNumber(double value, int decimals) {
    if (decimals == 0 || value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(decimals);
  }

  _ProgressMetric _defaultMetricFor(ExerciseInputType inputType) {
    switch (inputType) {
      case ExerciseInputType.repsAndWeight:
        return _ProgressMetric.weight;
      case ExerciseInputType.repsOnly:
        return _ProgressMetric.reps;
      case ExerciseInputType.distanceAndTime:
        return _ProgressMetric.distance;
      case ExerciseInputType.timeOnly:
        return _ProgressMetric.time;
    }
  }

  void _setSelectedMetric(_ProgressMetric metric) {
    if (_selectedMetric == metric) {
      return;
    }
    setState(() {
      _selectedMetric = metric;
    });
  }

  Widget _buildLegendItem(
    String label,
    Color color, {
    bool active = true,
    VoidCallback? onTap,
  }) {
    final displayColor = active ? color : color.withValues(alpha: 0.35);
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = typography.caption.copyWith(
      color: active
          ? colorScheme.onSurface
          : colorScheme.onSurface.withValues(alpha: 0.5),
      fontWeight: FontWeight.w500,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: displayColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: spacing.xs),
        Text(label, style: textStyle),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radii.full),
      pressedScale: 0.98,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(radii.full),
        ),
        child: content,
      ),
    );
  }
}

class _ProgressPoint {
  final DateTime date;
  final double weight;
  final int reps;
  final double distance;
  final int durationSeconds;
  final double xValue;

  _ProgressPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.distance,
    required this.durationSeconds,
    this.xValue = 0,
  });

  double get durationMinutes => durationSeconds / 60.0;

  _ProgressPoint copyWith({
    double? xValue,
    double? weight,
    int? reps,
    double? distance,
    int? durationSeconds,
  }) {
    return _ProgressPoint(
      date: date,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      distance: distance ?? this.distance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      xValue: xValue ?? this.xValue,
    );
  }
}
