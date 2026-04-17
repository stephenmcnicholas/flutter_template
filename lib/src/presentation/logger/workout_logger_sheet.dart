import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/providers/audio_coaching_settings_provider.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/providers/scorecard_update_service.dart';
import 'package:fytter/src/providers/user_scorecard_provider.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/presentation/logger/post_workout_mood_screen.dart';
import 'package:fytter/src/presentation/logger/rest_timer_banner.dart';
import 'package:fytter/src/presentation/logger/rest_timer_overlay.dart';
import 'package:fytter/src/presentation/logger/workout_duration_estimate.dart';
import 'package:fytter/src/presentation/logger/workout_intro_modal.dart';
import 'package:fytter/src/presentation/logger/workout_logger_core.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/workout/workout_completion_screen.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:fytter/src/utils/set_outcome_utils.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class WorkoutLoggerSheet extends ConsumerStatefulWidget {
  final String workoutName;
  final String? workoutId;
  final String? programId;
  final List<Exercise> initialExercises;
  final Map<String, List<Map<String, dynamic>>>? initialSetsByExercise;
  final bool minimized;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  const WorkoutLoggerSheet({
    super.key,
    required this.workoutName,
    this.workoutId,
    this.programId,
    this.initialExercises = const [],
    this.initialSetsByExercise,
    this.minimized = false,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
  });

  @override
  ConsumerState<WorkoutLoggerSheet> createState() => _WorkoutLoggerSheetState();
}

Future<void> _playTemplate2FirstExercise(WidgetRef ref, String firstExerciseId) async {
  try {
    final instructions = await ref.read(exerciseInstructionsProvider(firstExerciseId).future);
    final sentences = await ref.read(sentenceLibraryProvider.future);
    if (instructions == null) return;
    final tier = ref.read(audioClipPathsProvider).sessionCoachingTierOrBeginner;
    final engine = ref.read(audioTemplateEngineProvider);
    final audio = ref.read(audioServiceProvider);
    final specs = engine.template2FirstExerciseSetup(
      exerciseId: firstExerciseId,
      instructions: instructions,
      tier: tier,
      sentences: sentences,
    );
    await audio.playSequence(specs);
  } catch (_) {}
}

class _WorkoutLoggerSheetState extends ConsumerState<WorkoutLoggerSheet> {
  bool _introModalShown = false;
  bool _audioSessionPrepared = false;
  bool _sessionAudioMuted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _prepareCoachingAudio(LoggerSessionState session) async {
    try {
      final premium = await ref.read(premiumServiceProvider).isPremium();
      final clipPaths = ref.read(audioClipPathsProvider);
      if (!premium) {
        clipPaths.clearSessionCoachingTier();
        return;
      }
      final scorecard = await ref.read(userScorecardProvider.future);
      final tier = coachingTierFromComputedLevel(scorecard?.computedLevel ?? 1);
      clipPaths.setSessionCoachingTier(tier);
      final download = ref.read(audioDownloadServiceProvider);
      unawaited(download.triggerTypeADownloadOnPremiumActivation());
      unawaited(
        download.syncTierChangeAndMaybeGraduate(
          newTier: tier,
          nextProgramExerciseIds: session.exercises.map((e) => e.id),
        ),
      );
      unawaited(
        download.triggerTypeBDownloadForWorkout(
          tier: tier,
          exerciseIds: session.exercises.map((e) => e.id),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioCoaching] prepare session failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final loggerSession = ref.watch(loggerSessionProvider);
    final loggerSessionNotifier = ref.read(loggerSessionProvider.notifier);
    if (widget.minimized) {
      // Minimized persistent bar, designed to overlay the AppBar
      return GestureDetector(
        onTap: widget.onMaximize,
        child: Material(
          elevation: 4.0,
          child: Container(
            height: kToolbarHeight,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Workout in progress: ${widget.workoutName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const RestTimerBanner(),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () {
                    // Stop rest timer when workout is closed
                    ref.read(restTimerProvider.notifier).stop();
                    widget.onClose();
                    loggerSessionNotifier.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (loggerSession == null) {
        _audioSessionPrepared = false;
      }
      // On first open, initialize the session provider if not already
      if (loggerSession == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loggerSessionNotifier.startSession(
            widget.workoutName,
            widget.initialExercises,
            widget.initialSetsByExercise,
            workoutId: widget.workoutId,
          );
        });
      }
      if (loggerSession != null && !_audioSessionPrepared) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _audioSessionPrepared = true;
          unawaited(_prepareCoachingAudio(loggerSession));
        });
      }
      // Show workout intro modal once when premium + guided (session ready)
      if (loggerSession != null &&
          !_introModalShown &&
          loggerSession.exercises.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryShowIntroModal(context, ref, loggerSession);
        });
      }
      return Stack(
        children: [
          // Dimmed background
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onMinimize,
              child: AnimatedOpacity(
                opacity: 0.5,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Theme.of(context).colorScheme.shadow.withAlpha(128),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: Material(
                type: MaterialType.card,
                borderRadius: BorderRadius.circular(32),
                elevation: 8,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).colorScheme.shadow.withAlpha(41),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Fixed header: workout name + progress bar + actions
                        Padding(
                          padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.workoutName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (loggerSession != null)
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Add exercise',
                                  onPressed: () async {
                                    final exercises = ref.read(exercisesFutureProvider).value ?? <Exercise>[];
                                    if (exercises.isEmpty) return;
                                    final alreadySelectedIds = loggerSession.exercises.map((e) => e.id).toList();
                                    final uri = Uri(
                                      path: '/exercises/select',
                                      queryParameters: alreadySelectedIds.isNotEmpty
                                          ? {'alreadySelected': alreadySelectedIds.join(',')}
                                          : null,
                                    );
                                    final selectedIds = await context.push<List<String>>(uri.toString());
                                    if (selectedIds != null && context.mounted) {
                                      for (final id in selectedIds) {
                                        final matched = exercises.where((e) => e.id == id).toList();
                                        if (matched.isNotEmpty) {
                                          ref.read(loggerSessionProvider.notifier).addExercise(matched.first);
                                        }
                                      }
                                    }
                                  },
                                ),
                              if (loggerSession != null)
                                IconButton(
                                  icon: const Icon(Icons.link),
                                  tooltip: 'Create superset',
                                  onPressed: () => _showSupersetPicker(context, loggerSession),
                                ),
                              if (ref.read(audioCoachingSettingsProvider).isGuided)
                                IconButton(
                                  icon: Icon(_sessionAudioMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up_outlined),
                                  tooltip: _sessionAudioMuted
                                      ? 'Unmute coaching audio'
                                      : 'Mute coaching audio',
                                  onPressed: () {
                                    if (!_sessionAudioMuted) {
                                      ref.read(audioServiceProvider).stop();
                                    }
                                    setState(() => _sessionAudioMuted = !_sessionAudioMuted);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.minimize),
                                tooltip: 'Minimize',
                                onPressed: widget.onMinimize,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Close',
                                onPressed: () {
                                  ref.read(restTimerProvider.notifier).stop();
                                  widget.onClose();
                                  loggerSessionNotifier.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                        // Thin full-width progress bar (completed sets / total sets; never retreats)
                        if (loggerSession != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: loggerSession.maxProgress.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        // Main logger content (scrollable)
                        Expanded(
                          child: loggerSession == null
                              ? const Center(child: CircularProgressIndicator())
                              : WorkoutLoggerCore(
                                  initialExercises: loggerSession.exercises,
                                  initialSetsByExercise: loggerSession.setsByExercise,
                                  workoutName: loggerSession.workoutName,
                                  isAudioMuted: () => _sessionAudioMuted,
                                  onSessionComplete: (allSetsByExercise) async {
                                    final sessionRepo = ref.read(workoutSessionRepositoryProvider);
                                    final templateRepo = ref.read(workoutRepositoryProvider);
                                    final uuid = const Uuid();
                                    final now = DateTime.now();
                                    final startedAt = loggerSession.startedAt;
                                    
                                    // Filter for completed sets to save to session history
                                    // IMPORTANT: Generate new UUIDs for entry IDs to ensure uniqueness per session
                                    // This prevents ID collisions when the same set is used in multiple workouts
                                    final entries = <WorkoutEntry>[];
                                    debugPrint('═══════════════════════════════════════════════════════════');
                                    debugPrint('workout_logger_sheet: Preparing to save workout session');
                                    debugPrint('  Workout name: ${widget.workoutName}');
                                    debugPrint('  Total exercises with sets: ${allSetsByExercise.length}');
                                    
                                    allSetsByExercise.forEach((exerciseId, sets) {
                                      debugPrint('  Exercise $exerciseId: ${sets.length} total sets');
                                      final completedSets = sets.where((s) => s['isComplete'] == true).toList();
                                      debugPrint('    Completed sets: ${completedSets.length}');
                                      
                                      for (var i = 0; i < completedSets.length; i++) {
                                        final set = completedSets[i];
                                        final newEntryId = uuid.v4(); // Generate new UUID for each entry
                                        final reps = set['reps'] ?? 0;
                                        final weight = set['weight'] ?? 0.0;
                                        final distance = set['distance'];
                                        final duration = set['duration'];
                                        debugPrint('      Set ${i + 1}: reps=$reps, weight=$weight, distance=$distance, duration=$duration (original id: ${set['id']}, new entry id: $newEntryId, isComplete: ${set['isComplete']})');
                                        entries.add(WorkoutEntry(
                                          id: newEntryId, // Use new UUID instead of set ID
                                          exerciseId: exerciseId,
                                          reps: set['reps'] ?? 0,
                                          weight: set['weight'] ?? 0.0,
                                          distance: set['distance'],
                                          duration: set['duration'],
                                          isComplete: true,
                                          timestamp: now,
                                          setOutcome: set['setOutcome'] as String?,
                                          supersetGroupId: set['supersetGroupId'] as String?,
                                        ));
                                      }
                                    });
                                    
                                    debugPrint('  Total entries to save: ${entries.length}');
                                    debugPrint('  Entries by exercise:');
                                    final entriesByExercise = <String, int>{};
                                    for (final entry in entries) {
                                      entriesByExercise[entry.exerciseId] = (entriesByExercise[entry.exerciseId] ?? 0) + 1;
                                    }
                                    entriesByExercise.forEach((exId, count) {
                                      debugPrint('    $exId: $count entries');
                                    });
                                    debugPrint('═══════════════════════════════════════════════════════════');

                                    // Only prompt to save as template for standalone workouts (no programId).
                                    // Programme workouts (AI or manual) are managed through the programme UI —
                                    // the post-session template dialog is not appropriate there.
                                    bool? saveAsTemplate;
                                    final isStandaloneWorkout = widget.programId == null || widget.programId!.isEmpty;
                                    if (isStandaloneWorkout && _hasTemplateStructuralChanges(
                                      initialExercises: widget.initialExercises,
                                      initialSetsByExercise: widget.initialSetsByExercise,
                                      currentExercises: loggerSession.exercises,
                                      currentSetsByExercise: allSetsByExercise,
                                    )) {
                                      saveAsTemplate = await _showSaveAsTemplateDialog(context);
                                    } else {
                                      saveAsTemplate = false; // Don't save if no structural changes
                                    }
                                    
                                    // Track the final workout name to use for history
                                    // If user saves as template with a new name, use that name for history too
                                    String? finalWorkoutName = widget.workoutName;
                                    String? finalWorkoutId = loggerSession.workoutId;

                                    // Save as template if needed, using ALL sets
                                    if (saveAsTemplate == true) {
                                      final templateEntries = <WorkoutEntry>[];
                                      allSetsByExercise.forEach((exerciseId, sets) {
                                        for (final set in sets) {
                                           templateEntries.add(WorkoutEntry(
                                            id: uuid.v4(), // New ID for template entry
                                            exerciseId: exerciseId,
                                            reps: set['reps'],
                                            weight: set['weight'],
                                            isComplete: false, // Not relevant for template
                                            timestamp: null, // Not relevant for template
                                            sessionId: null,
                                          ));
                                        }
                                      });
                                      
                                      String? nameToSave = widget.workoutName;
                                      final buildContext = context;
                                      while(true) {
                                        if (!buildContext.mounted) break;
                                        final name = await showWorkoutNameDialog(buildContext, initial: nameToSave);
                                        if (name == null || name.trim().isEmpty) break;

                                        nameToSave = name.trim();
                                        final allTemplates = await templateRepo.findAll();
                                        Workout? existingTemplate;
                                        try {
                                          existingTemplate = allTemplates.firstWhere((t) => t.name.toLowerCase() == nameToSave!.toLowerCase());
                                        } catch (e) {
                                          existingTemplate = null;
                                        }

                                        if (existingTemplate == null) {
                                          final newTemplateId = uuid.v4();
                                          await templateRepo.save(Workout(id: newTemplateId, name: nameToSave, entries: templateEntries));
                                          ref.invalidate(workoutTemplatesFutureProvider);
                                          // Update final workout name to use for history
                                          finalWorkoutName = nameToSave;
                                          if (finalWorkoutId == null || finalWorkoutId.isEmpty) {
                                            finalWorkoutId = newTemplateId;
                                          }
                                          break;
                                        } else {
                                          if (!buildContext.mounted) break;
                                          final choice = await _showOverwriteDialog(buildContext, nameToSave);
                                          if (choice == 'overwrite') {
                                            await templateRepo.save(Workout(id: existingTemplate.id, name: nameToSave, entries: templateEntries));
                                            ref.invalidate(workoutTemplatesFutureProvider);
                                            // Update final workout name to use for history
                                            finalWorkoutName = nameToSave;
                                            if (finalWorkoutId == null || finalWorkoutId.isEmpty) {
                                              finalWorkoutId = existingTemplate.id;
                                            }
                                            break;
                                          } else if (choice == 'rename') {
                                            continue;
                                          } else {
                                            break;
                                          }
                                        }
                                      }
                                    }
                                    
                                    // Save to history if there were any completed sets
                                    // Use finalWorkoutName which will be the template name if saved, otherwise the original workoutName
                                    String? savedSessionId;
                                    if (entries.isNotEmpty) {
                                      final uuid = const Uuid();
                                      final session = WorkoutSession(
                                        id: uuid.v4(), // Use UUID to prevent collisions
                                        workoutId: finalWorkoutId ?? '',
                                        date: now,
                                        entries: entries,
                                        name: finalWorkoutName,
                                        notes: null,
                                      );
                                      await sessionRepo.save(session);
                                      savedSessionId = session.id;
                                      final sessionDuration =
                                          now.difference(startedAt);
                                      unawaited(
                                        ref
                                            .read(scorecardUpdateServiceProvider)
                                            .onSessionCompleted(
                                              session: session,
                                              allSetsByExercise:
                                                  allSetsByExercise,
                                              sessionExercises:
                                                  loggerSession.exercises,
                                              sessionDuration: sessionDuration,
                                              programId: widget.programId,
                                            ),
                                      );
                                    }

                                    ref.invalidate(workoutSessionsProvider);
                                    // Cancel any in-progress coaching sequence; pause (not stop) to
                                    // keep the iOS audio session alive for the celebration chime.
                                    ref.read(restTimerProvider.notifier).stop();
                                    unawaited(ref.read(audioServiceProvider).cancelSequenceAndPause());
                                    widget.onClose();
                                    loggerSessionNotifier.clear();

                                    final exercisesCompleted = entries
                                        .map((entry) => entry.exerciseId)
                                        .toSet()
                                        .length;
                                    final totalReps = entries.fold<int>(
                                      0,
                                      (sum, entry) => sum + entry.reps,
                                    );
                                    final totalVolume = entries.fold<double>(
                                      0,
                                      (sum, entry) => sum + (entry.weight * entry.reps),
                                    );
                                    final duration = now.difference(startedAt);
                                    final summary = WorkoutCompletionSummary(
                                      workoutName: finalWorkoutName ?? widget.workoutName,
                                      exercisesCompleted: exercisesCompleted,
                                      totalSets: entries.length,
                                      totalReps: totalReps,
                                      totalVolume: totalVolume,
                                      duration: duration,
                                    );
                                    if (!context.mounted) return;
                                    final programId = widget.programId;
                                    int? programSessionCount;
                                    if (programId != null &&
                                        programId.isNotEmpty &&
                                        entries.isNotEmpty) {
                                      try {
                                        final program =
                                            await ref.read(programRepositoryProvider).findById(programId);
                                        final sessions =
                                            await ref.read(workoutSessionRepositoryProvider).findAll();
                                        programSessionCount =
                                            countSessionsForProgramSchedule(program, sessions);
                                      } catch (_) {
                                        programSessionCount = null;
                                      }
                                    }
                                    if (!context.mounted) return;
                                    final failedSetCount = entries
                                        .where(
                                          (e) =>
                                              e.setOutcome ==
                                              SetOutcomeValues.failed,
                                        )
                                        .length;
                                    context.push(
                                      '/workout/mood',
                                      extra: PostWorkoutMoodArgs(
                                        summary: summary,
                                        sessionId: savedSessionId,
                                        programId: programId,
                                        programCompletedSessionCount:
                                            programSessionCount,
                                        postWorkoutFailedSetCount:
                                            failedSetCount,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Rest timer overlay (when active) - positioned to cover entire screen
          // Must be last in Stack to appear on top of everything
          Positioned.fill(
            child: RestTimerOverlay(onMinimize: widget.onMinimize),
          ),
        ],
      );
    }
  }

  Future<void> _showSupersetPicker(
    BuildContext context,
    LoggerSessionState session,
  ) async {
    final ungrouped = session.exercises
        .where((e) => !session.supersetGroups.containsKey(e.id))
        .toList();

    // Build existing circuits: groupId → exercises in session order.
    final existingCircuits = <String, List<Exercise>>{};
    for (final ex in session.exercises) {
      final gid = session.supersetGroups[ex.id];
      if (gid != null) existingCircuits.putIfAbsent(gid, () => []).add(ex);
    }

    // No circuits yet and fewer than 2 ungrouped → nothing to do.
    if (existingCircuits.isEmpty && ungrouped.length < 2) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least 2 exercises to create a circuit.',
          ),
        ),
      );
      return;
    }

    // All exercises already grouped and nothing to add.
    if (ungrouped.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All exercises are already in circuits.',
          ),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<_LoggerSupersetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LoggerSupersetPickerSheet(
        ungroupedExercises: ungrouped,
        existingCircuits: existingCircuits,
      ),
    );

    if (result == null) return;
    final notifier = ref.read(loggerSessionProvider.notifier);
    if (result is _AddToGroupResult) {
      for (final exId in result.exerciseIds) {
        notifier.addToGroup(exId, result.groupId);
      }
    } else if (result is _CreateNewResult) {
      notifier.groupExercisesAsSuperset(result.exerciseIds);
    }
  }

  Future<void> _tryShowIntroModal(
    BuildContext context,
    WidgetRef ref,
    LoggerSessionState loggerSession,
  ) async {
    if (_introModalShown) return;
    // Quickstart sessions have no workoutId and no prescribed sets — the duration
    // estimate would always be the 30-min fallback, so skip the modal entirely.
    if (loggerSession.workoutId == null) return;
    final premium = await ref.read(premiumServiceProvider).isPremium();
    final settings = ref.read(audioCoachingSettingsProvider);
    if (!premium || !settings.isGuided) return;
    if (!mounted) return;
    setState(() => _introModalShown = true);

    final restSettings = ref.read(restTimerSettingsProvider);
    final restSeconds = restSettings.isLoading ? 120 : restSettings.defaultSeconds;
    final durationMinutes = estimateWorkoutDurationMinutes(
      initialSetsByExercise: loggerSession.setsByExercise,
      restSeconds: restSeconds,
    );
    final firstExerciseId = loggerSession.exercises.isNotEmpty
        ? loggerSession.exercises.first.id
        : null;

    if (!mounted) return;
    await showDialog<void>(
      context: context, // ignore: use_build_context_synchronously
      barrierDismissible: false,
      builder: (ctx) => WorkoutIntroModal(
        workoutId: loggerSession.workoutId,
        exerciseCount: loggerSession.exercises.length,
        durationMinutes: durationMinutes,
        firstExerciseId: firstExerciseId,
        onDismiss: () {
          if (_sessionAudioMuted) return;
          final audio = ref.read(audioServiceProvider);
          audio.startBackgroundSession();
          if (firstExerciseId != null) {
            unawaited(_playTemplate2FirstExercise(ref, firstExerciseId));
          }
        },
      ),
    );
  }

  /// Checks if structural changes were made to the template (exercises added/removed/reordered, sets added)
  /// Returns false if no template was used (Quickstart) or if only values/completion status changed
  bool _hasTemplateStructuralChanges({
    required List<Exercise> initialExercises,
    required Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
    required List<Exercise> currentExercises,
    required Map<String, List<Map<String, dynamic>>> currentSetsByExercise,
  }) {
    // If no initial template was provided (Quickstart workout), no structural changes possible
    if (initialSetsByExercise == null || initialSetsByExercise.isEmpty) {
      return false;
    }

    // Check if exercises were added or removed
    final initialExerciseIds = initialExercises.map((e) => e.id).toList();
    final currentExerciseIds = currentExercises.map((e) => e.id).toList();
    
    if (initialExerciseIds.length != currentExerciseIds.length) {
      return true; // Exercises added or removed
    }

    // Check if exercises were reordered (different order)
    for (int i = 0; i < initialExerciseIds.length; i++) {
      if (initialExerciseIds[i] != currentExerciseIds[i]) {
        return true; // Exercises reordered
      }
    }

    // Check if sets were added to any existing exercise
    for (final exerciseId in initialExerciseIds) {
      final initialSetCount = initialSetsByExercise[exerciseId]?.length ?? 0;
      final currentSetCount = currentSetsByExercise[exerciseId]?.length ?? 0;
      
      if (currentSetCount > initialSetCount) {
        return true; // Sets added to this exercise
      }
    }

    // Check if any new exercises were added (not in initial list)
    for (final exerciseId in currentExerciseIds) {
      if (!initialExerciseIds.contains(exerciseId)) {
        return true; // New exercise added
      }
    }

    // No structural changes - only values or completion status may have changed
    return false;
  }

  Future<bool?> _showSaveAsTemplateDialog(BuildContext context) async {
    return showConfirmDialog(
      context,
      title: 'Update workout template?',
      message: "You added or removed exercises in this workout. Do you want to save these changes to the template so future sessions use this version?",
      confirmText: 'Save changes',
      cancelText: 'No',
    );
  }

  Future<String?> _showOverwriteDialog(BuildContext context, String name) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Name Exists'),
        content: Text('A template named "$name" already exists. Would you like to overwrite it or save with a new name?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop('rename'),
            child: const Text('Save with New Name'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result types returned by _LoggerSupersetPickerSheet
// ---------------------------------------------------------------------------

sealed class _LoggerSupersetResult {}

class _AddToGroupResult extends _LoggerSupersetResult {
  final String groupId;
  final List<String> exerciseIds;
  _AddToGroupResult({required this.groupId, required this.exerciseIds});
}

class _CreateNewResult extends _LoggerSupersetResult {
  final List<String> exerciseIds;
  _CreateNewResult({required this.exerciseIds});
}

// ---------------------------------------------------------------------------
// Picker sheet
// ---------------------------------------------------------------------------

/// Bottom sheet that lets the user:
///   • Add ungrouped exercises to an existing circuit, OR
///   • Create a new circuit from ≥ 2 ungrouped exercises.
///
/// Shows only the sections that are available given the current session state.
class _LoggerSupersetPickerSheet extends StatefulWidget {
  final List<Exercise> ungroupedExercises;
  /// groupId → ordered list of exercises already in that circuit.
  final Map<String, List<Exercise>> existingCircuits;

  const _LoggerSupersetPickerSheet({
    required this.ungroupedExercises,
    required this.existingCircuits,
  });

  @override
  State<_LoggerSupersetPickerSheet> createState() =>
      _LoggerSupersetPickerSheetState();
}

class _LoggerSupersetPickerSheetState
    extends State<_LoggerSupersetPickerSheet> {
  // "Add to circuit" section state
  String? _selectedGroupId;
  final Set<String> _selectedToAdd = {};

  // "Create new circuit" section state
  final Set<String> _selectedNew = {};

  bool get _hasExistingCircuits => widget.existingCircuits.isNotEmpty;
  bool get _canCreateNew => widget.ungroupedExercises.length >= 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Add to existing circuit ──────────────────────────────────
            if (_hasExistingCircuits) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('Add to existing circuit', style: tt.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Select a circuit, then choose which exercises to add.',
                  style: tt.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),
              // Circuit cards — tapping one selects it as the target
              ...widget.existingCircuits.entries.toList().asMap().entries.map(
                (mapEntry) {
                  final circuitIndex = mapEntry.key + 1;
                  final groupId = mapEntry.value.key;
                  final members = mapEntry.value.value;
                  final isSelected = _selectedGroupId == groupId;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() {
                        _selectedGroupId =
                            isSelected ? null : groupId;
                        _selectedToAdd.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? scheme.primary.withValues(alpha: 0.06)
                              : null,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Circuit $circuitIndex',
                                    style: tt.labelMedium?.copyWith(
                                      color: isSelected
                                          ? scheme.primary
                                          : scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    members.map((e) => e.name).join(', '),
                                    style: tt.bodySmall
                                        ?.copyWith(color: scheme.outline),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Ungrouped exercises to add to the selected circuit
              if (_selectedGroupId != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Exercises to add:',
                    style: tt.labelSmall?.copyWith(color: scheme.outline),
                  ),
                ),
                ...widget.ungroupedExercises.map(
                  (ex) => CheckboxListTile(
                    dense: true,
                    value: _selectedToAdd.contains(ex.id),
                    title: Text(ex.name),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedToAdd.add(ex.id);
                      } else {
                        _selectedToAdd.remove(ex.id);
                      }
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ElevatedButton(
                    onPressed: _selectedToAdd.isNotEmpty
                        ? () => Navigator.of(context).pop(
                              _AddToGroupResult(
                                groupId: _selectedGroupId!,
                                exerciseIds: _selectedToAdd.toList(),
                              ),
                            )
                        : null,
                    child: const Text('Add to circuit'),
                  ),
                ),
              ],
              if (_canCreateNew)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Divider(),
                ),
            ],

            // ── Create new circuit ───────────────────────────────────────
            if (_canCreateNew) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, _hasExistingCircuits ? 8 : 16, 16, 4),
                child: Text('Create new circuit', style: tt.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Select 2 or more exercises to group together.',
                  style: tt.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),
              ...widget.ungroupedExercises.map(
                (ex) => CheckboxListTile(
                  dense: true,
                  value: _selectedNew.contains(ex.id),
                  title: Text(ex.name),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedNew.add(ex.id);
                    } else {
                      _selectedNew.remove(ex.id);
                    }
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ElevatedButton(
                  onPressed: _selectedNew.length >= 2
                      ? () => Navigator.of(context).pop(
                            _CreateNewResult(
                                exerciseIds: _selectedNew.toList()),
                          )
                      : null,
                  child: const Text('Create circuit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}