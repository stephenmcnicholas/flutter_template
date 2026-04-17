import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/exercise_card.dart';
import 'package:fytter/src/presentation/shared/exercise_media_widget.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/utils/format_utils.dart' show formatWeight, formatDuration, formatDistance, WeightUnit, DistanceUnit;

/// Active exercise card for the evolved workout logger: name, [i], muscle group,
/// image, Set X of Y, last-set row, reps/weight inputs, "Complete Set" button.
class ActiveExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final List<Map<String, dynamic>> sets;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  final void Function(int reps, double weight, double? distance, int? duration) onSetChanged;
  final VoidCallback onCompleteSet;
  final VoidCallback onAddSet;
  final VoidCallback? onInfoTap;
  final VoidCallback? onSkipSet;
  /// When non-null, shows the coaching icon and calls this when tapped (premium only).
  final VoidCallback? onCoachingTap;
  /// When true, shows a dot badge on the coaching icon indicating content is available.
  final bool coachingHasContent;
  /// When non-null, displayed above the exercise name as a muted caption.
  /// Format: "Superset · Round X of Y"
  final String? supersetLabel;

  const ActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.weightUnit,
    required this.distanceUnit,
    required this.onSetChanged,
    required this.onCompleteSet,
    required this.onAddSet,
    this.onInfoTap,
    this.onSkipSet,
    this.onCoachingTap,
    this.coachingHasContent = false,
    this.supersetLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final inputType = getExerciseInputType(exercise);

    final totalCount = sets.length;
    final firstIncompleteIndex = sets.indexWhere((s) => (s['isComplete'] ?? false) != true);
    final hasIncompleteSet = firstIncompleteIndex >= 0;
    final currentSet = hasIncompleteSet ? sets[firstIncompleteIndex] : null;
    final currentSetNumber = firstIncompleteIndex + 1;

    // Last set: use last session's data for set 1, current session's previous set for set 2+,
    // or the final completed set when all sets are done.
    final lastRecorded = ref.watch(lastRecordedValuesProvider(exercise.id)).valueOrNull;
    final allSetsComplete = totalCount > 0 && !hasIncompleteSet;
    String lastSetText;
    if (currentSetNumber == 1 && lastRecorded != null && lastRecorded.hasValues) {
      lastSetText = _formatLastSet(lastRecorded, inputType);
    } else if (firstIncompleteIndex > 0) {
      final prev = sets[firstIncompleteIndex - 1];
      lastSetText = _formatLastSetFromMap(prev, inputType);
    } else if (allSetsComplete && totalCount > 0) {
      lastSetText = _formatLastSetFromMap(sets[totalCount - 1], inputType);
    } else {
      lastSetText = '—';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (supersetLabel != null) ...[
          AppText(
            supersetLabel!,
            style: AppTextStyle.caption,
            color: colors.outline,
          ),
          SizedBox(height: spacing.xs / 2),
        ],
        Row(
          children: [
            Expanded(
              child: AppText(
                exercise.name,
                style: AppTextStyle.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (exercise.bodyPart != null)
              Padding(
                padding: EdgeInsets.only(left: spacing.xs, right: spacing.xs),
                child: AppText(
                  exercise.bodyPart!,
                  style: AppTextStyle.caption,
                  color: colors.outline,
                ),
              ),
            if (onCoachingTap != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tips_and_updates_outlined),
                    tooltip: 'Coaching cues',
                    onPressed: onCoachingTap,
                  ),
                  if (coachingHasContent)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Instructions',
              onPressed: onInfoTap,
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        // Fixed-height image so set/inputs/Complete Set fit above the fold (no inner scroll)
        ClipRRect(
          borderRadius: BorderRadius.circular(context.themeExt<AppRadii>().md),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: ExerciseMediaWidget(
              assetPath: exercise.thumbnailPath ?? exercise.mediaPath,
              isThumbnail: false,
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        if (!allSetsComplete) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Set $currentSetNumber of ${totalCount > 0 ? totalCount : 1}',
                style: AppTextStyle.label,
              ),
              AppText(
                'Last set: $lastSetText',
                style: AppTextStyle.caption,
                color: colors.outline,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
        ],
        if (hasIncompleteSet && currentSet != null)
          SetEditor(
            key: ValueKey('active_set_${currentSet['id']}'),
            set: currentSet,
            inputType: inputType,
            setNumber: currentSetNumber,
            weightUnit: weightUnit,
            distanceUnit: distanceUnit,
            onChanged: onSetChanged,
            hideCompleteCheckbox: true,
          )
        else if (!allSetsComplete && totalCount == 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: AppText(
              'Add your first set below.',
              style: AppTextStyle.body,
            ),
          )
        else if (allSetsComplete)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText('All sets complete', style: AppTextStyle.label),
                AppText(
                  'Last set: $lastSetText',
                  style: AppTextStyle.caption,
                  color: colors.outline,
                ),
              ],
            ),
          ),
        if (hasIncompleteSet) ...[
          SizedBox(height: spacing.md),
          AppButton(
            label: 'Complete Set',
            onPressed: onCompleteSet,
            isFullWidth: true,
          ),
        ],
        if (hasIncompleteSet) ...[
          SizedBox(height: spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onSkipSet != null)
                TextButton(
                  onPressed: onSkipSet,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.secondary,
                  ),
                  child: AppText('Skip set', style: AppTextStyle.caption),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(supersetLabel != null ? 'Add Round' : 'Add Set'),
                onPressed: onAddSet,
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                ),
              ),
            ],
          ),
        ] else
          Padding(
            padding: EdgeInsets.only(top: spacing.xs),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(supersetLabel != null ? 'Add Round' : 'Add Set'),
                onPressed: onAddSet,
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatLastSet(dynamic lastRecorded, ExerciseInputType inputType) {
    if (lastRecorded is LastRecordedValues) {
      switch (inputType) {
        case ExerciseInputType.repsAndWeight:
          final r = lastRecorded.reps ?? 0;
          final w = lastRecorded.weight ?? 0.0;
          return '$r reps · ${formatWeight(w, unit: weightUnit)}';
        case ExerciseInputType.repsOnly:
          return '${lastRecorded.reps ?? 0} reps';
        case ExerciseInputType.distanceAndTime:
          final d = lastRecorded.distance;
          final t = lastRecorded.duration;
          if (d != null && t != null) return '${formatDistance(d, unit: distanceUnit)} · ${formatDuration(t)}';
          if (d != null) return formatDistance(d, unit: distanceUnit);
          if (t != null) return formatDuration(t);
          return '—';
        case ExerciseInputType.timeOnly:
          return lastRecorded.duration != null ? formatDuration(lastRecorded.duration!) : '—';
      }
    }
    return '—';
  }

  String _formatLastSetFromMap(Map<String, dynamic> set, ExerciseInputType inputType) {
    switch (inputType) {
      case ExerciseInputType.repsAndWeight:
        final r = set['reps'] ?? 0;
        final w = (set['weight'] as num?)?.toDouble() ?? 0.0;
        return '$r reps · ${formatWeight(w, unit: weightUnit)}';
      case ExerciseInputType.repsOnly:
        return '${set['reps'] ?? 0} reps';
      case ExerciseInputType.distanceAndTime:
        final d = set['distance'] != null ? (set['distance'] as num).toDouble() : null;
        final t = set['duration'] as int?;
        if (d != null && t != null) return '${formatDistance(d, unit: distanceUnit)} · ${formatDuration(t)}';
        if (d != null) return formatDistance(d, unit: distanceUnit);
        if (t != null) return formatDuration(t);
        return '—';
      case ExerciseInputType.timeOnly:
        return set['duration'] != null ? formatDuration(set['duration'] as int) : '—';
    }
  }
}
