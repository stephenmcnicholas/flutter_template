import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/domain/exercise.dart';
//import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/presentation/exercise/exercise_instruction_text.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/utils/one_rm_calculator.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import '../shared/app_text.dart';
import '../shared/app_card.dart';
import '../shared/app_stats_row.dart';
import '../shared/app_loading_state.dart';
import '../shared/exercise_media_widget.dart';
import '../shared/exercise_progress_chart.dart';
import '../shared/exercise_category_utils.dart';
import '../theme.dart';
import 'package:fytter/src/utils/pr_utils.dart';

/// Screen to view exercise details including history.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh history when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(exerciseHistoryProvider(widget.exerciseId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(widget.exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exerciseId));
    final unitPrefs = ref.watch(unitSettingsProvider);
    final favoritesAsync = ref.watch(exerciseFavoritesProvider);
    final colors = context.themeExt<AppColors>();
    final isFavorite = favoritesAsync.value?.contains(widget.exerciseId) ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
        title: exerciseAsync.when(
          data: (exercise) => exercise != null ? AppText(exercise.name, style: AppTextStyle.headline) : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? colors.primary : colors.outline,
            onPressed: () {
              ref
                  .read(exerciseFavoritesProvider.notifier)
                  .toggleFavorite(widget.exerciseId);
            },
            tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
          ),
          TextButton(
            onPressed: () async {
              await context.push('/exercise/${widget.exerciseId}?edit=true');
              // Refresh exercise data after edit
              ref.invalidate(exerciseByIdProvider(widget.exerciseId));
            },
            child: const Text('Edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'History'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: exerciseAsync.when(
        data: (exercise) {
          if (exercise == null) {
            return const Center(child: Text('Exercise not found'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(exercise),
              _buildHistoryTab(
                historyAsync,
                exercise,
                unitPrefs.weightUnit,
                unitPrefs.distanceUnit,
              ),
              _buildProgressTab(
                historyAsync,
                exercise,
                unitPrefs.weightUnit,
                unitPrefs.distanceUnit,
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAboutTab(Exercise exercise) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final categoryColor = categoryColorForBodyPart(context, exercise.bodyPart);
    final instructionsAsync =
        ref.watch(exerciseInstructionsProvider(exercise.id));
    final sentenceLibraryAsync = ref.watch(sentenceLibraryProvider);
    final primaryMusclesAsync =
        ref.watch(exercisePrimaryMusclesProvider(exercise.id));
    final secondaryMusclesAsync =
        ref.watch(exerciseSecondaryMusclesProvider(exercise.id));
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise media
          if (exercise.mediaPath != null)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radii.md),
                child: ExerciseMediaWidget(
                  assetPath: exercise.mediaPath,
                  isThumbnail: false,
                ),
              ),
            ),
          // Exercise details
          if (exercise.description.isNotEmpty) ...[
            AppText('Description', style: AppTextStyle.title, fontWeight: FontWeight.bold),
            SizedBox(height: spacing.sm),
            AppText(exercise.description, style: AppTextStyle.body),
            SizedBox(height: spacing.lg),
          ],
          if (exercise.bodyPart != null) ...[
            AppText('Body Part', style: AppTextStyle.title, fontWeight: FontWeight.bold),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                if (categoryColor != null)
                  Container(
                    width: spacing.sm,
                    height: spacing.sm,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (categoryColor != null) SizedBox(width: spacing.sm),
                AppText(exercise.bodyPart!, style: AppTextStyle.body),
              ],
            ),
            SizedBox(height: spacing.lg),
          ],
          if (exercise.equipment != null) ...[
            AppText('Equipment', style: AppTextStyle.title, fontWeight: FontWeight.bold),
            SizedBox(height: spacing.sm),
            AppText(exercise.equipment!, style: AppTextStyle.body),
            SizedBox(height: spacing.lg),
          ],
          primaryMusclesAsync.when(
            data: (muscles) {
              if (muscles.isEmpty) return const SizedBox.shrink();
              return _buildMuscleTagsSection(
                title: 'Primary muscles',
                muscles: muscles,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          secondaryMusclesAsync.when(
            data: (muscles) {
              if (muscles.isEmpty) return const SizedBox.shrink();
              return _buildMuscleTagsSection(
                title: 'Secondary muscles',
                muscles: muscles,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          instructionsAsync.when(
            data: (instructions) {
              if (instructions == null) {
                return const SizedBox.shrink();
              }
              return sentenceLibraryAsync.when(
                data: (lib) => _buildInstructionsSection(instructions, lib),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(ExerciseInstructions instructions, SentenceLibrary lib) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    Widget bulletItem(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('•', style: AppTextStyle.body, color: colors.secondary),
            SizedBox(width: spacing.sm),
            Expanded(child: AppText(text, style: AppTextStyle.body)),
          ],
        ),
      );
    }

    Widget sectionTitle(String title) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing.sm, top: spacing.lg),
        child: AppText(title, style: AppTextStyle.title, fontWeight: FontWeight.bold),
      );
    }

    final setupLines = ExerciseInstructionText.bulletsFromCue(instructions.setup, lib);
    final movementLines = ExerciseInstructionText.bulletsFromCue(instructions.movement, lib);
    final goodFormText = ExerciseInstructionText.paragraphFromCue(instructions.goodFormFeels, lib);
    final breathingText = ExerciseInstructionText.paragraphFromCue(instructions.breathingCue, lib);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (setupLines.isNotEmpty) ...[
          sectionTitle('Setup'),
          ...setupLines.map(bulletItem),
        ],
        if (movementLines.isNotEmpty) ...[
          sectionTitle('Movement'),
          ...movementLines.map(bulletItem),
        ],
        if (goodFormText.trim().isNotEmpty) ...[
          sectionTitle('Good form feels like'),
          AppText(goodFormText, style: AppTextStyle.body),
        ],
        if (instructions.commonFixes.isNotEmpty) ...[
          sectionTitle('Common fixes'),
          ...instructions.commonFixes.map((fix) {
            final issueText = lib.getText(fix.issue);
            final fixText = ExerciseInstructionText.paragraphFromFixIds(fix.fix, lib);
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(issueText, style: AppTextStyle.body, fontWeight: FontWeight.w600),
                  SizedBox(height: spacing.xs),
                  AppText(fixText, style: AppTextStyle.body),
                ],
              ),
            );
          }),
        ],
        if (instructions.makeItEasier.isNotEmpty) ...[
          sectionTitle('Make it easier'),
          ...instructions.makeItEasier.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(item.name, style: AppTextStyle.body, fontWeight: FontWeight.w600),
                  SizedBox(height: spacing.xs),
                  AppText(item.description, style: AppTextStyle.body),
                ],
              ),
            );
          }),
        ],
        if (instructions.levelUp != null &&
            instructions.levelUp!.description.trim().isNotEmpty) ...[
          sectionTitle('Level up'),
          AppText(instructions.levelUp!.description, style: AppTextStyle.body),
        ],
        if (breathingText.trim().isNotEmpty) ...[
          sectionTitle('Breathing'),
          AppText(breathingText, style: AppTextStyle.body),
        ],
        if (instructions.safetyNote != null &&
            instructions.safetyNote!.trim().isNotEmpty) ...[
          sectionTitle('Safety note'),
          AppText(instructions.safetyNote!, style: AppTextStyle.body),
        ],
      ],
    );
  }

  Widget _buildMuscleTagsSection({
    required String title,
    required List<String> muscles,
  }) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, style: AppTextStyle.title, fontWeight: FontWeight.bold),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: muscles
              .map((muscle) => _buildMuscleTag(_formatMuscleLabel(muscle), colors))
              .toList(),
        ),
        SizedBox(height: spacing.lg),
      ],
    );
  }

  Widget _buildMuscleTag(String label, AppColors colors) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.full),
        border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
      ),
      child: AppText(
        label,
        style: AppTextStyle.caption,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatMuscleLabel(String value) {
    final cleaned = value.replaceAll('_', '-').trim();
    return cleaned
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Widget _buildHistoryTab(
    AsyncValue<List<ExerciseWorkoutHistory>> historyAsync,
    Exercise exercise,
    WeightUnit weightUnit,
    DistanceUnit distanceUnit,
  ) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: AppText(
              'No workout history for this exercise',
              style: AppTextStyle.body,
            ),
          );
        }

        // Group by month (using year-month as key for easier sorting)
        final groupedByMonth = <String, List<ExerciseWorkoutHistory>>{};
        final monthKeys = <String, DateTime>{};
        for (final item in history) {
          final date = item.session.date;
          final yearMonth = DateTime(date.year, date.month);
          final monthKey = DateFormat('MMMM yyyy').format(date).toUpperCase();
          groupedByMonth.putIfAbsent(monthKey, () => []).add(item);
          monthKeys[monthKey] = yearMonth;
        }

        // Sort months (most recent first)
        final sortedMonths = groupedByMonth.keys.toList()
          ..sort((a, b) {
            final dateA = monthKeys[a]!;
            final dateB = monthKeys[b]!;
            return dateB.compareTo(dateA);
          });

        // Sort sessions within each month (most recent first)
        for (final month in groupedByMonth.keys) {
          groupedByMonth[month]!.sort((a, b) {
            return b.session.date.compareTo(a.session.date);
          });
        }

        final spacing = context.themeExt<AppSpacing>();

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh the history provider
            ref.invalidate(exerciseHistoryProvider(widget.exerciseId));
            // Wait for the provider to refresh
            await ref.read(exerciseHistoryProvider(widget.exerciseId).future);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(spacing.lg),
            itemCount: sortedMonths.length,
          itemBuilder: (context, monthIndex) {
            final month = sortedMonths[monthIndex];
            final sessions = groupedByMonth[month]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.md, top: monthIndex > 0 ? spacing.xl : 0),
                  child: AppText(
                    month,
                    style: AppTextStyle.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Sessions for this month
                ...sessions.map((item) {
                  final session = item.session;
                  final entries = item.entries;
                  
                  // Format date and time
                  final dateStr = DateFormat('EEEE, d MMM yyyy').format(session.date);
                  final timeStr = DateFormat('HH:mm').format(session.date);
                  final sessionName = session.name ?? 'Workout';

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.lg),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session header
                          AppText(
                            sessionName,
                            style: AppTextStyle.title,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: spacing.xs),
                          AppText(
                            '$timeStr, $dateStr',
                            style: AppTextStyle.caption,
                          ),
                          SizedBox(height: spacing.md),
                          // Sets performed
                          AppText(
                            'Sets Performed',
                            style: AppTextStyle.label,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: spacing.xs),
                          ...entries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final workoutEntry = entry.value;
                            final inputType = getExerciseInputType(exercise);
                            final displayText = formatWorkoutEntryDisplay(
                              workoutEntry,
                              inputType,
                              weightUnit: weightUnit,
                              distanceUnit: distanceUnit,
                            );
                            final oneRm = inputType == ExerciseInputType.repsAndWeight
                                ? OneRmCalculator.calculate(workoutEntry.weight, workoutEntry.reps)
                                : null;
                            
                            return Padding(
                              padding: EdgeInsets.only(left: spacing.md, top: spacing.xs),
                              child: Row(
                                children: [
                                  AppText(
                                    'Set ${index + 1}: ',
                                    style: AppTextStyle.body,
                                  ),
                                  AppText(
                                    displayText,
                                    style: AppTextStyle.body,
                                  ),
                                  if (oneRm != null) ...[
                                    SizedBox(width: spacing.sm),
                                    AppText(
                                      '1RM: ${formatWeight(oneRm.toDouble(), unit: weightUnit)}',
                                      style: AppTextStyle.caption,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          ),
        );
      },
      loading: () => const AppLoadingState(),
      error: (err, _) => Center(child: Text('Error loading history: $err')),
    );
  }

  Widget _buildProgressTab(
    AsyncValue<List<ExerciseWorkoutHistory>> historyAsync,
    Exercise exercise,
    WeightUnit weightUnit,
    DistanceUnit distanceUnit,
  ) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final inputType = getExerciseInputType(exercise);
    return historyAsync.when(
      data: (history) {
        final entries = history
            .expand((session) => session.entries)
            .where((entry) => entry.isComplete)
            .toList();
        final pr = calculateExercisePr(inputType: inputType, entries: entries);
        final prItems = _buildPrItems(
          inputType: inputType,
          pr: pr,
          weightUnit: weightUnit,
          distanceUnit: distanceUnit,
        );
        return Column(
          children: [
            if (prItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  spacing.lg,
                  spacing.lg,
                  0,
                ),
                child: AppCard(
                  compact: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppText(
                            'Personal Records',
                            style: AppTextStyle.label,
                          ),
                          SizedBox(width: spacing.xs),
                          Tooltip(
                            message: 'Best performance for this exercise',
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: colors.outline,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      AppStatsRow(items: prItems),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ExerciseProgressChart(
                exercise: exercise,
                history: history,
                weightUnit: weightUnit,
                distanceUnit: distanceUnit,
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoadingState(
        useShimmer: true,
        variant: AppLoadingVariant.card,
      ),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  List<AppStatItem> _buildPrItems({
    required ExerciseInputType inputType,
    required ExercisePersonalRecord pr,
    required WeightUnit weightUnit,
    required DistanceUnit distanceUnit,
  }) {
    final items = <AppStatItem>[];
    switch (inputType) {
      case ExerciseInputType.repsOnly:
        if (pr.maxReps != null) {
          items.add(
            AppStatItem(
              label: 'Best Reps',
              value: pr.maxReps.toString(),
            ),
          );
        }
        break;
      case ExerciseInputType.repsAndWeight:
        if (pr.maxWeightKg != null) {
          items.add(
            AppStatItem(
              label: 'Best Weight',
              value: formatWeight(pr.maxWeightKg!, unit: weightUnit),
            ),
          );
        }
        break;
      case ExerciseInputType.timeOnly:
        if (pr.maxDurationSec != null) {
          items.add(
            AppStatItem(
              label: 'Best Time',
              value: formatDuration(pr.maxDurationSec!),
            ),
          );
        }
        break;
      case ExerciseInputType.distanceAndTime:
        if (pr.maxDistanceKm != null) {
          items.add(
            AppStatItem(
              label: 'Best Distance',
              value: formatDistance(pr.maxDistanceKm!, unit: distanceUnit),
            ),
          );
        }
        if (pr.maxDurationSec != null) {
          items.add(
            AppStatItem(
              label: 'Best Time',
              value: formatDuration(pr.maxDurationSec!),
            ),
          );
        }
        break;
    }
    return items;
  }

}

