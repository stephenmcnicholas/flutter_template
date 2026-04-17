import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/presentation/ai_programme/programme_audio_bootstrap.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;

/// Parsed workout breakdown item for the About screen.
/// [spokenIntro] is the stored spoken workout intro text (for TTS regeneration if file missing).
class _WorkoutBreakdownItem {
  final String workoutId;
  final String briefDescription;
  final String? spokenIntro;
  final List<_ExerciseBreakdownItem> exercises;

  _WorkoutBreakdownItem({
    required this.workoutId,
    required this.briefDescription,
    this.spokenIntro,
    required this.exercises,
  });
}

class _SetSpec {
  final int reps;
  final double? targetLoadKg;
  const _SetSpec({required this.reps, this.targetLoadKg});
}

class _ExerciseBreakdownItem {
  final String exerciseId;
  final List<_SetSpec> sets;
  final String coachNote;

  _ExerciseBreakdownItem({
    required this.exerciseId,
    required this.sets,
    required this.coachNote,
  });
}

List<_WorkoutBreakdownItem> _parseWorkoutBreakdowns(String? jsonStr) {
  if (jsonStr == null || jsonStr.trim().isEmpty) return [];
  try {
    final list = jsonDecode(jsonStr) as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final exercises = (map['exercises'] as List<dynamic>? ?? []).map((ex) {
        final exMap = ex as Map<String, dynamic>;
        final rawSets = exMap['sets'];
        final List<_SetSpec> sets;
        if (rawSets is List) {
          // New format: array of { reps, targetLoadKg? }
          sets = rawSets.map((s) {
            final sm = s as Map<String, dynamic>;
            return _SetSpec(
              reps: (sm['reps'] as num?)?.toInt() ?? 8,
              targetLoadKg: (sm['targetLoadKg'] as num?)?.toDouble(),
            );
          }).toList();
        } else {
          // Legacy flat format: sets: number, reps: number
          final count = (rawSets as num?)?.toInt() ?? 3;
          final reps = (exMap['reps'] as num?)?.toInt() ?? 8;
          final load = (exMap['targetLoadKg'] as num?)?.toDouble();
          sets = List.generate(count, (_) => _SetSpec(reps: reps, targetLoadKg: load));
        }
        return _ExerciseBreakdownItem(
          exerciseId: (exMap['exerciseId'] as String?) ?? '',
          sets: sets,
          coachNote: (exMap['coachNote'] as String?) ?? '',
        );
      }).toList();
      return _WorkoutBreakdownItem(
        workoutId: (map['workoutId'] as String?) ?? '',
        briefDescription: (map['briefDescription'] as String?) ?? '',
        spokenIntro: map['spokenIntro'] as String?,
        exercises: exercises,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// Screen showing coach rationale and workout breakdowns for a programme.
/// Premium: requests programme + workout intro TTS when opened (if not already on disk);
/// app bar play control when audio is ready (same asset as programme detail).
class AboutProgrammeScreen extends ConsumerStatefulWidget {
  const AboutProgrammeScreen({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<AboutProgrammeScreen> createState() => _AboutProgrammeScreenState();
}

class _AboutProgrammeScreenState extends ConsumerState<AboutProgrammeScreen> {
  /// Prevents queuing multiple post-frame kickoffs while [program] is stable.
  bool _programAudioKickoffScheduled = false;

  bool _isPlaying = false;
  bool _isPaused = false;
  /// Incremented when a new playback starts. Lets the completion callback tell
  /// whether its playback is still the active session.
  int _playGeneration = 0;

  @override
  void dispose() {
    if (_isPlaying || _isPaused) {
      ref.read(audioServiceProvider).stop();
    }
    super.dispose();
  }

  Future<void> _bootstrapProgrammeAudio(Program program) async {
    await bootstrapProgrammeDescriptionAudio(ref, program);
  }

  void _toggleProgrammeAudio(String path) {
    if (_isPlaying) {
      // Pause — keeps position, playPath future keeps awaiting.
      ref.read(audioServiceProvider).pause();
      setState(() { _isPlaying = false; _isPaused = true; });
    } else if (_isPaused) {
      // Resume from paused position — playPath future is still alive.
      ref.read(audioServiceProvider).resume();
      setState(() { _isPlaying = true; _isPaused = false; });
    } else {
      // Start fresh.
      final gen = ++_playGeneration;
      setState(() { _isPlaying = true; _isPaused = false; });
      ref.read(audioServiceProvider).playPath(path).whenComplete(() {
        if (mounted && _playGeneration == gen) {
          setState(() { _isPlaying = false; _isPaused = false; });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final exercisesAsync = ref.watch(exercisesFutureProvider);
    final workoutsAsync = ref.watch(workoutTemplatesFutureProvider);
    final programmeAudioAsync = ref.watch(programmeAudioStatusProvider(widget.programId));
    final programmeAudio = programmeAudioAsync.valueOrNull;
    final premium = ref.watch(premiumStatusProvider).valueOrNull == true;

    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final radii = context.themeExt<AppRadii>();
    final typography = context.themeExt<AppTypography>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isPlaying || _isPaused) {
              ref.read(audioServiceProvider).stop();
            }
            context.pop();
          },
        ),
        title: Text(AiProgrammeStrings.aboutTitle, style: typography.label),
        actions: [
          if (premium &&
              programmeAudio != null &&
              (programmeAudio.isGenerating || programmeAudio.path != null))
            programmeAudio.isGenerating
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: _isPlaying ? 'Pause' : (_isPaused ? 'Resume' : 'Play programme overview'),
                    icon: Icon(_isPlaying
                        ? Icons.pause
                        : (_isPaused ? Icons.play_arrow : Icons.volume_up_outlined)),
                    onPressed: programmeAudio.path != null
                        ? () => _toggleProgrammeAudio(programmeAudio.path!)
                        : null,
                  ),
        ],
      ),
      body: programAsync.when(
        data: (program) {
          if (program == null) {
            return Center(
              child: AppText('Programme not found.', style: AppTextStyle.body),
            );
          }

          if (!_programAudioKickoffScheduled) {
            _programAudioKickoffScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _bootstrapProgrammeAudio(program);
            });
          }

          final breakdowns = _parseWorkoutBreakdowns(program.workoutBreakdowns);
          final exerciseMap = exercisesAsync.valueOrNull != null
              ? {for (final e in exercisesAsync.value!) e.id: e.name}
              : <String, String>{};
          final workoutMap = workoutsAsync.valueOrNull != null
              ? {for (final w in workoutsAsync.value!) w.id: w.name}
              : <String, String>{};

          return SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (program.coachRationale != null &&
                    program.coachRationale!.trim().isNotEmpty) ...[
                  AppText(
                    AiProgrammeStrings.aboutWhyThisProgrammeTitle,
                    style: AppTextStyle.title,
                  ),
                  SizedBox(height: spacing.sm),
                  AppText(
                    program.coachRationale!,
                    style: AppTextStyle.body,
                  ),
                  SizedBox(height: spacing.xl),
                ],
                if (breakdowns.isNotEmpty) ...[
                  AppText(
                    AiProgrammeStrings.aboutWorkoutBreakdownsTitle,
                    style: AppTextStyle.title,
                  ),
                  SizedBox(height: spacing.xs),
                  AppText(
                    AiProgrammeStrings.aboutWorkoutBreakdownsCaption,
                    style: AppTextStyle.caption,
                    color: colors.outline,
                  ),
                  SizedBox(height: spacing.md),
                  ...breakdowns.map((b) {
                    final workoutName =
                        workoutMap[b.workoutId] ?? 'Workout';
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.md),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          expansionTileTheme: ExpansionTileThemeData(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radii.md),
                            ),
                            tilePadding: EdgeInsets.symmetric(
                              horizontal: spacing.lg,
                              vertical: spacing.sm,
                            ),
                            childrenPadding: EdgeInsets.fromLTRB(
                              spacing.lg,
                              0,
                              spacing.lg,
                              spacing.md,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(radii.md),
                            border: Border.all(
                              color: colors.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.fitness_center,
                              color: colors.primary,
                              size: 24,
                            ),
                            title: AppText(
                              workoutName,
                              style: AppTextStyle.label,
                            ),
                            subtitle: b.briefDescription.isNotEmpty
                                ? Padding(
                                    padding: EdgeInsets.only(top: spacing.xs),
                                    child: AppText(
                                      b.briefDescription,
                                      style: AppTextStyle.caption,
                                      color: colors.outline,
                                    ),
                                  )
                                : null,
                            children: [
                              for (final ex in b.exercises) ...[
                                SizedBox(height: spacing.sm),
                                _ExerciseBreakdownRow(
                                  exerciseName: exerciseMap[ex.exerciseId] ?? ex.exerciseId,
                                  sets: ex.sets,
                                  coachNote: ex.coachNote,
                                  spacing: spacing,
                                  colors: colors,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: AppText(
            'Something went wrong.',
            style: AppTextStyle.body,
          ),
        ),
      ),
    );
  }
}

class _ExerciseBreakdownRow extends StatelessWidget {
  const _ExerciseBreakdownRow({
    required this.exerciseName,
    required this.sets,
    required this.coachNote,
    required this.spacing,
    required this.colors,
  });

  final String exerciseName;
  final List<_SetSpec> sets;
  final String coachNote;
  final AppSpacing spacing;
  final AppColors colors;

  /// Returns a compact set summary string.
  /// Straight sets (all equal): "3 × 10 @ 60 kg"
  /// Varying sets: "3 sets (10×60, 8×65, 6×70)"
  String _setsSummary() {
    if (sets.isEmpty) return '';
    final allEqual = sets.every(
      (s) => s.reps == sets[0].reps && s.targetLoadKg == sets[0].targetLoadKg,
    );
    if (allEqual) {
      final s = sets[0];
      final loadPart = (s.targetLoadKg != null && s.targetLoadKg! > 0)
          ? ' @ ${s.targetLoadKg!.toStringAsFixed(s.targetLoadKg! % 1 == 0 ? 0 : 1)} kg'
          : '';
      return '${sets.length} × ${s.reps}$loadPart';
    }
    final detail = sets.map((s) {
      final load = (s.targetLoadKg != null && s.targetLoadKg! > 0)
          ? '×${s.targetLoadKg!.toStringAsFixed(s.targetLoadKg! % 1 == 0 ? 0 : 1)}'
          : '';
      return '${s.reps}$load';
    }).join(', ');
    return '${sets.length} sets ($detail)';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '$exerciseName — ${_setsSummary()}',
            style: AppTextStyle.label,
          ),
          if (coachNote.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            AppText(
              coachNote,
              style: AppTextStyle.caption,
              color: colors.outline,
            ),
          ],
        ],
      ),
    );
  }
}
