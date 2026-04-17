// lib/src/presentation/history/history_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:uuid/uuid.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/pr_utils.dart';
import 'package:fytter/src/domain/session_check_in.dart';

/// Displays the details of a single logged workout, including date and all entries.
class HistoryDetailScreen extends ConsumerWidget {
  final String workoutId;

  const HistoryDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionByIdProvider(workoutId));
    final templatesAsync = ref.watch(workoutTemplatesFutureProvider);
    final unitSettings = ref.watch(unitSettingsProvider);
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final checkInsAsync = ref.watch(sessionCheckInsForSessionProvider(workoutId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: sessionAsync.when(
        data: (WorkoutSession? session) {
          if (session == null) return const SizedBox.shrink();
          final title = (session.name?.isNotEmpty == true)
              ? session.name!
              : DateFormat.yMMMd().format(session.date);
          final formattedDateTime =
              DateFormat('d MMM, yyyy • HH:mm').format(session.date);
          // Fetch all exercises for name lookup
          final exercisesAsync = ref.watch(exercisesFutureProvider);
          return exercisesAsync.when(
            data: (allExercises) {
              final colors = context.themeExt<AppColors>();
              final spacing = context.themeExt<AppSpacing>();
              final exerciseMap = {for (var ex in allExercises) ex.id: ex};
              final inputTypes = <String, ExerciseInputType>{
                for (final ex in allExercises) ex.id: getExerciseInputType(ex),
              };
              final templates = templatesAsync.value ?? const <Workout>[];
              final isAlreadyTemplate = templatesAsync.hasValue
                  ? _isSessionAlreadyTemplate(session, templates)
                  : true;
              // Group entries by exerciseId
              final entriesByExercise = <String, List<WorkoutEntry>>{};
              final completedEntries =
                  session.entries.where((entry) => entry.isComplete).toList();
              for (final entry in completedEntries) {
                entriesByExercise.putIfAbsent(entry.exerciseId, () => []).add(entry);
                inputTypes.putIfAbsent(
                  entry.exerciseId,
                  () => ExerciseInputType.repsAndWeight,
                );
              }
              // Determine superset groups: groupId → ordered list of exerciseIds
              final supersetGroupOrder = <String, List<String>>{};
              for (final entry in completedEntries) {
                final gid = entry.supersetGroupId;
                if (gid != null) {
                  supersetGroupOrder.putIfAbsent(gid, () => []);
                  if (!supersetGroupOrder[gid]!.contains(entry.exerciseId)) {
                    supersetGroupOrder[gid]!.add(entry.exerciseId);
                  }
                }
              }
              // Build render list: each item is either a standalone exerciseId
              // or a group marker (isGroup=true, id=groupId)
              final renderItems = <({bool isGroup, String id})>[];
              final seenGroupIds = <String>{};
              for (final exerciseId in entriesByExercise.keys) {
                final gid = completedEntries
                    .firstWhere(
                      (e) => e.exerciseId == exerciseId,
                      orElse: () => completedEntries.first,
                    )
                    .supersetGroupId;
                if (gid != null && !seenGroupIds.contains(gid)) {
                  renderItems.add((isGroup: true, id: gid));
                  seenGroupIds.add(gid);
                } else if (gid == null) {
                  renderItems.add((isGroup: false, id: exerciseId));
                }
              }
              final totals = calculateWorkoutTotals(
                entries: completedEntries,
                inputTypes: inputTypes,
              );
              final allSessions = sessionsAsync.value ?? const <WorkoutSession>[];
              final exercisesWithPrs = sessionsAsync.hasValue
                  ? exercisesWithNewPrsInSession(
                      session: session,
                      allSessions: allSessions,
                      inputTypes: inputTypes,
                    )
                  : <String>{};
              return Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: AppTextStyle.title,
                    ),
                    SizedBox(height: spacing.xs),
                    AppText(
                      formattedDateTime,
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                    _PostWorkoutCheckInSection(
                      checkIns: checkInsAsync.valueOrNull ?? [],
                      spacing: spacing,
                      colors: colors,
                    ),
                    if (!isAlreadyTemplate) ...[
                      SizedBox(height: spacing.md),
                      AppButton(
                        label: 'Save as template',
                        variant: AppButtonVariant.secondary,
                        onPressed: () async {
                          final name = await showWorkoutNameDialog(
                            context,
                            initial: session.name ?? DateFormat('d MMM, yyyy').format(session.date),
                          );
                          if (name == null || name.trim().isEmpty) return;
                          final repo = ref.read(workoutRepositoryProvider);
                          final workout = Workout(
                            id: const Uuid().v4(),
                            name: name.trim(),
                            entries: session.entries,
                          );
                          await repo.save(workout);
                          ref.invalidate(workoutTemplatesFutureProvider);

                          // Rename the history entry so it matches the saved template name.
                          final sessionRepo = ref.read(workoutSessionRepositoryProvider);
                          await sessionRepo.save(session.copyWith(name: name.trim()));
                          ref.invalidate(workoutSessionsProvider);
                          ref.invalidate(workoutSessionByIdProvider(workoutId));
                        },
                      ),
                    ],
                    SizedBox(height: spacing.lg),
                    AppCard(
                      compact: true,
                      child: AppStatsRow(
                        items: [
                          AppStatItem(
                            label: 'Total Reps',
                            value: totals.totalReps.toString(),
                          ),
                          AppStatItem(
                            label: 'Total Volume',
                            value: formatWeight(
                              totals.totalVolumeKg,
                              unit: unitSettings.weightUnit,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Expanded(
                      child: ListView.separated(
                        itemCount: renderItems.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: spacing.md),
                        itemBuilder: (context, index) {
                          final item = renderItems[index];
                          if (item.isGroup) {
                            final groupExIds =
                                supersetGroupOrder[item.id] ?? [];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                      color: colors.primary, width: 3),
                                ),
                              ),
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    'SUPERSET',
                                    style: AppTextStyle.caption,
                                    color: colors.outline,
                                  ),
                                  SizedBox(height: spacing.xs),
                                  ...groupExIds.map((exId) {
                                    final exercise = exerciseMap[exId];
                                    final exerciseName =
                                        exercise?.name ?? exId;
                                    final inputType = exercise != null
                                        ? getExerciseInputType(exercise)
                                        : ExerciseInputType.repsAndWeight;
                                    final exEntries =
                                        entriesByExercise[exId] ?? [];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          bottom: spacing.xs),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AppText(
                                                    exerciseName,
                                                    style:
                                                        AppTextStyle.label),
                                              ),
                                              if (exercisesWithPrs
                                                  .contains(exId))
                                                Tooltip(
                                                  message:
                                                      'PR achieved in this workout',
                                                  child: Icon(
                                                    Icons.emoji_events,
                                                    size: 18,
                                                    color: colors.success,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: spacing.xs),
                                          ...exEntries
                                              .map((WorkoutEntry entry) {
                                            final displayText =
                                                formatWorkoutEntryDisplay(
                                              entry,
                                              inputType,
                                              weightUnit:
                                                  unitSettings.weightUnit,
                                              distanceUnit:
                                                  unitSettings.distanceUnit,
                                            );
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                left: spacing.md,
                                                bottom: spacing.xs,
                                              ),
                                              child: AppText(
                                                displayText,
                                                style: AppTextStyle.body,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          } else {
                            // Standalone exercise
                            final exerciseGroup = entriesByExercise.entries
                                .firstWhere(
                                  (e) => e.key == item.id,
                                  orElse: () => MapEntry(item.id, []),
                                );
                            final exercise = exerciseMap[exerciseGroup.key];
                            final exerciseName =
                                exercise?.name ?? exerciseGroup.key;
                            final inputType = exercise != null
                                ? getExerciseInputType(exercise)
                                : ExerciseInputType.repsAndWeight;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        exerciseName,
                                        style: AppTextStyle.label,
                                      ),
                                    ),
                                    if (exercisesWithPrs
                                        .contains(exerciseGroup.key))
                                      Tooltip(
                                        message:
                                            'PR achieved in this workout',
                                        child: Icon(
                                          Icons.emoji_events,
                                          size: 18,
                                          color: colors.success,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: spacing.xs),
                                ...exerciseGroup.value
                                    .map((WorkoutEntry entry) {
                                  final displayText =
                                      formatWorkoutEntryDisplay(
                                    entry,
                                    inputType,
                                    weightUnit: unitSettings.weightUnit,
                                    distanceUnit: unitSettings.distanceUnit,
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: spacing.md,
                                      bottom: spacing.xs,
                                    ),
                                    child: AppText(
                                      displayText,
                                      style: AppTextStyle.body,
                                    ),
                                  );
                                }),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading exercises: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading workout: $err')),
      ),
    );
  }

  bool _isSessionAlreadyTemplate(WorkoutSession session, List<Workout> templates) {
    if (session.workoutId.isNotEmpty) {
      final hasMatchingTemplate = templates.any(
        (template) => template.id == session.workoutId,
      );
      if (hasMatchingTemplate) {
        return true;
      }
    }

    if (session.name != null && session.name!.isNotEmpty) {
      final hasMatchingName = templates.any(
        (template) => template.name.toLowerCase().trim() == session.name!.toLowerCase().trim(),
      );
      if (hasMatchingName) {
        return true;
      }
    }

    final sessionStructure = _getWorkoutStructure(session.entries);
    for (final template in templates) {
      final templateStructure = _getWorkoutStructure(template.entries);
      if (_structuresMatch(sessionStructure, templateStructure)) {
        return true;
      }
    }
    return false;
  }

  Map<String, int> _getWorkoutStructure(List<WorkoutEntry> entries) {
    final structure = <String, int>{};
    for (final entry in entries) {
      structure[entry.exerciseId] = (structure[entry.exerciseId] ?? 0) + 1;
    }
    return structure;
  }

  bool _structuresMatch(Map<String, int> structure1, Map<String, int> structure2) {
    if (structure1.length != structure2.length) return false;
    for (final entry in structure1.entries) {
      if (structure2[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// Displays the post-workout rating and optional note from the session check-in.
/// Renders nothing if no post-session check-in exists for this session.
class _PostWorkoutCheckInSection extends StatelessWidget {
  const _PostWorkoutCheckInSection({
    required this.checkIns,
    required this.spacing,
    required this.colors,
  });

  final List<SessionCheckIn> checkIns;
  final AppSpacing spacing;
  final AppColors colors;

  static String _ratingEmoji(CheckInRating rating) => switch (rating) {
        CheckInRating.great => '💪',
        CheckInRating.okay => '😐',
        CheckInRating.tough => '😓',
        _ => '',
      };

  static String _ratingLabel(CheckInRating rating) => switch (rating) {
        CheckInRating.great => 'Strong',
        CheckInRating.okay => 'OK',
        CheckInRating.tough => 'Tough',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final postCheckIn = checkIns
        .where((c) => c.checkInType == CheckInType.postSession)
        .firstOrNull;
    if (postCheckIn == null) return const SizedBox.shrink();

    final emoji = _ratingEmoji(postCheckIn.rating);
    final label = _ratingLabel(postCheckIn.rating);
    if (emoji.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              SizedBox(width: spacing.xs),
              AppText(label, style: AppTextStyle.caption, color: colors.outline),
            ],
          ),
          if (postCheckIn.freeText != null &&
              postCheckIn.freeText!.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            AppText(
              postCheckIn.freeText!,
              style: AppTextStyle.caption,
              color: colors.outline,
            ),
          ],
        ],
      ),
    );
  }
}
