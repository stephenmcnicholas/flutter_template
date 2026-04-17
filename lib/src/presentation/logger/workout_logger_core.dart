import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/rule_engine/failed_set_adjuster.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/presentation/logger/active_exercise_card.dart';
import 'package:fytter/src/presentation/logger/coaching_panel.dart';
import 'package:fytter/src/presentation/logger/exercise_instructions_sheet.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_coaching_settings_provider.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_updater.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/providers/scorecard_update_service.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/utils/haptic_utils.dart';
import 'package:fytter/src/services/audio/audio_service.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/utils/set_outcome_utils.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_sentence_specs.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class WorkoutLoggerCore extends ConsumerStatefulWidget {
  final List<Exercise> initialExercises;
  final Map<String, List<Map<String, dynamic>>>? initialSetsByExercise;
  final void Function(Map<String, List<Map<String, dynamic>>> setsByExercise) onSessionComplete;
  final String workoutName;
  final List<Exercise>? testExercises;
  final void Function(WorkoutSession)? onSave;
  final void Function()? onEnd;
  final bool Function() isAudioMuted;
  const WorkoutLoggerCore({
    super.key,
    required this.initialExercises,
    this.initialSetsByExercise,
    required this.onSessionComplete,
    required this.workoutName,
    this.testExercises,
    this.onSave,
    this.onEnd,
    required this.isAudioMuted,
  });

  @override
  ConsumerState<WorkoutLoggerCore> createState() => _WorkoutLoggerCoreState();
}

class _WorkoutLoggerCoreState extends ConsumerState<WorkoutLoggerCore> {
  final _uuid = Uuid();
  String? _activeExerciseId;
  late final PageController _pageController;
  /// When non-null, the rest timer listener returns to this exercise after rest
  /// completes (instead of advancing forward). Used for superset round returns.
  String? _pendingGroupReturnExId;

  /// T5 clips to play when the rest timer ends. Computed async when rest starts.
  List<AudioClipSpec>? _pendingRestEndSpecs;

  /// Tracks the previous mute state to detect unmute transitions.
  bool _prevMuted = false;

  /// Returns the supersetGroupId for [exerciseId] from its first set map.
  String? _supersetGroupIdOf(
    String exerciseId,
    Map<String, List<Map<String, dynamic>>> setsByExercise,
  ) {
    return (setsByExercise[exerciseId]?.firstOrNull)?['supersetGroupId'] as String?;
  }

  /// Returns all exercises in [groupId]'s group, in the order they appear
  /// in [allExercises].
  List<Exercise> _groupExercisesInOrder(
    String groupId,
    List<Exercise> allExercises,
    Map<String, List<Map<String, dynamic>>> setsByExercise,
  ) {
    return allExercises.where((ex) {
      return _supersetGroupIdOf(ex.id, setsByExercise) == groupId;
    }).toList();
  }

  /// Scroll the carousel to [exerciseId] and update [_activeExerciseId].
  void _scrollToExerciseId(String exerciseId) {
    final exercises = ref.read(loggerSessionProvider)?.exercises ?? const <Exercise>[];
    final targetIndex = exercises.indexWhere((e) => e.id == exerciseId);
    if (targetIndex < 0) return;
    setState(() => _activeExerciseId = exerciseId);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Builds the superset badge label for [exerciseId], or null if standalone.
  String? _supersetLabel(
    String exerciseId,
    List<Map<String, dynamic>> sets,
  ) {
    final groupId = (sets.firstOrNull)?['supersetGroupId'] as String?;
    if (groupId == null) return null;
    final firstIncompleteIndex =
        sets.indexWhere((s) => (s['isComplete'] ?? false) != true);
    final currentRound =
        firstIncompleteIndex >= 0 ? firstIncompleteIndex + 1 : sets.length;
    return 'Superset · Round $currentRound of ${sets.length}';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _prevMuted = widget.isAudioMuted();
  }

  @override
  void didUpdateWidget(WorkoutLoggerCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowMuted = widget.isAudioMuted();
    if (_prevMuted && !nowMuted) {
      // Just unmuted — play contextual good-form cue for the active exercise.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final exerciseId = _activeExerciseId;
        if (exerciseId == null) return;
        if (widget.isAudioMuted()) return;
        unawaited(_playCueByIndex(ref, exerciseId, 0));
      });
    }
    _prevMuted = nowMuted;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise ex) {
    ref.read(loggerSessionProvider.notifier).addExercise(ex);
    // Auto-seed the first set so the card is immediately ready to log.
    unawaited(_addSet(ex.id));
  }

  Future<void> _addSet(String exerciseId) async {
    final exercises = widget.testExercises ?? (ref.read(exercisesFutureProvider).value ?? []);
    final exercise = exercises.firstWhere((e) => e.id == exerciseId);
    final inputType = getExerciseInputType(exercise);

    final loggerSession = ref.read(loggerSessionProvider);
    final existingSets = loggerSession?.setsByExercise[exerciseId] ?? [];
    final isFirstSet = existingSets.isEmpty;

    Map<String, dynamic> newSet;

    if (!isFirstSet) {
      // Copy from the last set logged this session so the user just hits Complete.
      final last = existingSets.last;
      newSet = {
        'id': _uuid.v4(),
        'isComplete': false,
        'reps': last['reps'],
        'weight': last['weight'],
        'distance': last['distance'],
        'duration': last['duration'],
        'targetReps': last['reps'],
        'targetWeight': last['weight'],
        'targetDistance': last['distance'],
        'targetDuration': last['duration'],
      };
    } else {
      // First set: prefer last recorded values, then sensible defaults.
      LastRecordedValues? lastValues;
      try {
        lastValues = await ref.read(lastRecordedValuesProvider(exerciseId).future);
      } catch (_) {
        lastValues = null;
      }

      newSet = {'id': _uuid.v4(), 'isComplete': false};

      switch (inputType) {
        case ExerciseInputType.repsAndWeight:
          newSet['reps'] = lastValues?.reps ?? 10;
          newSet['weight'] = lastValues?.weight ?? 0.0;
          newSet['distance'] = null;
          newSet['duration'] = null;
          break;
        case ExerciseInputType.repsOnly:
          newSet['reps'] = lastValues?.reps ?? 10;
          newSet['weight'] = 0.0;
          newSet['distance'] = null;
          newSet['duration'] = null;
          break;
        case ExerciseInputType.distanceAndTime:
          newSet['reps'] = 0;
          newSet['weight'] = 0.0;
          newSet['distance'] = lastValues?.distance ?? 5.0;
          newSet['duration'] = lastValues?.duration ?? 1800;
          break;
        case ExerciseInputType.timeOnly:
          newSet['reps'] = 0;
          newSet['weight'] = 0.0;
          newSet['distance'] = null;
          newSet['duration'] = lastValues?.duration ?? 60;
          break;
      }
      newSet['targetReps'] = newSet['reps'];
      newSet['targetWeight'] = newSet['weight'];
      newSet['targetDistance'] = newSet['distance'];
      newSet['targetDuration'] = newSet['duration'];
    }

    ref.read(loggerSessionProvider.notifier).addSet(exerciseId, newSet);

    // Circuit parity: add a matching set to any circuit peer that has fewer sets
    // than this exercise now has, so all members stay in lockstep.
    final updatedSession = ref.read(loggerSessionProvider);
    if (updatedSession != null) {
      final groupId = updatedSession.supersetGroups[exerciseId];
      if (groupId != null) {
        final myCount = updatedSession.setsByExercise[exerciseId]?.length ?? 0;
        for (final peer in updatedSession.exercises) {
          if (peer.id == exerciseId) continue;
          if (updatedSession.supersetGroups[peer.id] != groupId) continue;
          final peerCount = updatedSession.setsByExercise[peer.id]?.length ?? 0;
          if (peerCount < myCount) {
            ref.read(loggerSessionProvider.notifier).addSet(peer.id, {
              'id': _uuid.v4(),
              'isComplete': false,
              'reps': newSet['reps'],
              'weight': newSet['weight'],
              'distance': newSet['distance'],
              'duration': newSet['duration'],
              'targetReps': newSet['reps'],
              'targetWeight': newSet['weight'],
              'targetDistance': newSet['distance'],
              'targetDuration': newSet['duration'],
            });
          }
        }
      }
    }
  }

  void _showExercisePicker(BuildContext context, List<Exercise> allExercises) async {
    final loggerSession = ref.watch(loggerSessionProvider);
    final selectedExercises = loggerSession?.exercises ?? [];
    final alreadySelectedIds = selectedExercises.map((e) => e.id).toList();
    
    // Navigate to exercise selection screen with already selected IDs
    final uri = Uri(
      path: '/exercises/select',
      queryParameters: alreadySelectedIds.isNotEmpty
          ? {'alreadySelected': alreadySelectedIds.join(',')}
          : null,
    );
    final selectedIds = await context.push<List<String>>(uri.toString());
    if (selectedIds != null && selectedIds.isNotEmpty) {
      final selected = allExercises.where((ex) => selectedIds.contains(ex.id)).toList();
      for (final ex in selected) {
        _addExercise(ex);
      }
    }
  }

  void _advanceToNextExercise() {
    final loggerSession = ref.read(loggerSessionProvider);
    final exercises = loggerSession?.exercises ?? const <Exercise>[];
    if (_activeExerciseId == null || exercises.isEmpty) return;
    final currentIndex =
        exercises.indexWhere((exercise) => exercise.id == _activeExerciseId);
    if (currentIndex == -1) return;
    final nextIndex = currentIndex + 1;
    if (nextIndex < exercises.length) {
      setState(() {
        _activeExerciseId = exercises[nextIndex].id;
      });
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RestTimerState>(restTimerProvider, (previous, next) {
      final wasActive = previous?.isActive ?? false;
      final nowActive = next.isActive;
      if (wasActive && !nowActive) {
        // Play T5 rest-end audio (exercise name + setup/movement or set label + breathing)
        final specs = _pendingRestEndSpecs;
        if (specs != null && specs.isNotEmpty && !widget.isAudioMuted()) {
          _pendingRestEndSpecs = null;
          unawaited(ref.read(audioServiceProvider).playSequence(specs));
        } else {
          _pendingRestEndSpecs = null;
        }

        // If a superset round just completed and more rounds remain,
        // return to the first exercise in the group
        if (_pendingGroupReturnExId != null) {
          final targetId = _pendingGroupReturnExId!;
          _pendingGroupReturnExId = null;
          _scrollToExerciseId(targetId);
          return;
        }
        // Original logic: if active exercise has no more incomplete sets, advance
        final activeExerciseId = _activeExerciseId;
        if (activeExerciseId == null) return;
        final loggerSession = ref.read(loggerSessionProvider);
        final sets = loggerSession?.setsByExercise[activeExerciseId] ?? const [];
        final hasIncompleteSet =
            sets.any((set) => (set['isComplete'] ?? false) != true);
        if (!hasIncompleteSet) {
          _advanceToNextExercise();
        }
      }
    });
    final exercises = widget.testExercises ?? (ref.watch(exercisesFutureProvider).value ?? []);
    // debugPrint('WorkoutLoggerCore.build: testExercises = ${widget.testExercises}, exercises = ${exercises.map((e) => e.name).toList()}, Add Exercise enabled: ${exercises.isNotEmpty}');
    final loggerSession = ref.watch(loggerSessionProvider);
    final unitSettings = ref.watch(unitSettingsProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    final selectedExercises = loggerSession?.exercises ?? [];
    final isPremium = premiumStatus.valueOrNull == true;
    if (_activeExerciseId == null && selectedExercises.isNotEmpty) {
      _activeExerciseId = selectedExercises.first.id;
    }
    final setsByExercise = loggerSession?.setsByExercise ?? {};
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedExercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Exercise'),
                onPressed: exercises.isNotEmpty ? () => _showExercisePicker(context, exercises) : null,
              ),
            ),
          ),
        Expanded(
          flex: 6,
          child: selectedExercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText('No exercises yet', style: AppTextStyle.body),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Exercise'),
                        onPressed: exercises.isNotEmpty ? () => _showExercisePicker(context, exercises) : null,
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final activeId = _activeExerciseId ?? selectedExercises.first.id;
                    final currentIndex = selectedExercises.indexWhere((e) => e.id == activeId);
                    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
                    final previousEx = safeIndex > 0 ? selectedExercises[safeIndex - 1] : null;
                    final nextEx = safeIndex < selectedExercises.length - 1 ? selectedExercises[safeIndex + 1] : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (previousEx != null)
                          _ExercisePeekStrip(
                            name: previousEx.name,
                            label: 'Previous',
                            compact: true,
                            onTap: () {
                              setState(() => _activeExerciseId = previousEx.id);
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  safeIndex - 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            scrollDirection: Axis.vertical,
                            itemCount: selectedExercises.length,
                            onPageChanged: (index) {
                              setState(() => _activeExerciseId = selectedExercises[index].id);
                            },
                            itemBuilder: (context, index) {
                              final ex = selectedExercises[index];
                              final activeSets = setsByExercise[ex.id] ?? [];
                              final firstIncompleteIndex = activeSets.indexWhere((s) => (s['isComplete'] ?? false) != true);
                              return SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Dismissible(
                                    key: ValueKey('focus_${ex.id}'),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      final confirmed = await showConfirmDialog(
                                        context,
                                        title: 'Remove exercise?',
                                        message: 'Remove "${ex.name}" from this workout? You can add it again from the Add button.',
                                        confirmText: 'Remove',
                                        cancelText: 'Cancel',
                                      );
                                      return confirmed == true;
                                    },
                                    onDismissed: (_) {
                                      ref.read(loggerSessionProvider.notifier).removeExercise(ex.id);
                                    },
                                    child: _FocusCardWrapper(
                                      child: AppCard(
                                        padding: EdgeInsets.all(context.themeExt<AppSpacing>().lg),
                                        elevation: 4,
                                        child: ActiveExerciseCard(
                                          exercise: ex,
                                          sets: activeSets,
                                          weightUnit: unitSettings.weightUnit,
                                          distanceUnit: unitSettings.distanceUnit,
                                          supersetLabel: _supersetLabel(ex.id, activeSets),
                                          onSetChanged: (reps, weight, distance, duration) {
                                            if (firstIncompleteIndex < 0) return;
                                            final set = activeSets[firstIncompleteIndex];
                                            ref.read(loggerSessionProvider.notifier).updateSet(
                                                  ex.id,
                                                  firstIncompleteIndex,
                                                  {...set, 'reps': reps, 'weight': weight, 'distance': distance, 'duration': duration},
                                                );
                                          },
                                          onCompleteSet: () {
                                            if (firstIncompleteIndex < 0) return;
                                            ref.read(hapticsServiceProvider).medium();
                                            final set = Map<String, dynamic>.from(activeSets[firstIncompleteIndex]);
                                            final inputType = getExerciseInputType(ex);
                                            final outcome = computeSetOutcomeOnComplete(
                                              inputType: inputType,
                                              set: set,
                                            );
                                            final completed = {
                                              ...set,
                                              'isComplete': true,
                                              'setOutcome': outcome,
                                            };
                                            ref.read(loggerSessionProvider.notifier).updateSet(
                                                  ex.id,
                                                  firstIncompleteIndex,
                                                  completed,
                                                );
                                            // Copy forward: seed the next pending set with
                                            // the values the user just confirmed.
                                            final nextIdx = firstIncompleteIndex + 1;
                                            if (nextIdx < activeSets.length &&
                                                activeSets[nextIdx]['isComplete'] != true) {
                                              ref.read(loggerSessionProvider.notifier).updateSet(
                                                    ex.id,
                                                    nextIdx,
                                                    {
                                                      ...activeSets[nextIdx],
                                                      'reps': set['reps'],
                                                      'weight': set['weight'],
                                                      'distance': set['distance'],
                                                      'duration': set['duration'],
                                                    },
                                                  );
                                            }
                                            final premium = ref.read(workoutAdaptationPremiumProvider);
                                            if (outcome == SetOutcomeValues.failed && premium) {
                                              final laterWeighted = activeSets
                                                  .skip(firstIncompleteIndex + 1)
                                                  .any(
                                                    (s) =>
                                                        (s['isComplete'] != true) &&
                                                        (((s['weight'] as num?) ?? 0) > 0),
                                                  );
                                              if (laterWeighted) {
                                                ref.read(loggerSessionProvider.notifier).applyFailedSetLoadReduction(
                                                      ex.id,
                                                      firstIncompleteIndex,
                                                    );
                                                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Reduced weight ~10% on remaining sets for this exercise.',
                                                    ),
                                                  ),
                                                );
                                              }
                                              unawaited(_maybeShowRegressionHint(ref, context, ex));
                                            }
                                            _onSetComplete(
                                              ref,
                                              ex.id,
                                              activeSets,
                                              firstIncompleteIndex,
                                              nextEx?.id,
                                              completed,
                                            );
                                          },
                                          onSkipSet: () {
                                            if (firstIncompleteIndex < 0) return;
                                            ref.read(hapticsServiceProvider).light();
                                            final set = activeSets[firstIncompleteIndex];
                                            ref.read(loggerSessionProvider.notifier).updateSet(
                                                  ex.id,
                                                  firstIncompleteIndex,
                                                  {...set, 'isComplete': true, 'setOutcome': 'skipped'},
                                                );
                                            _onSetComplete(
                                              ref,
                                              ex.id,
                                              activeSets,
                                              firstIncompleteIndex,
                                              nextEx?.id,
                                              set,
                                            );
                                          },
                                          onAddSet: () {
                                            ref.read(hapticsServiceProvider).light();
                                            unawaited(_addSet(ex.id));
                                          },
                                          onCoachingTap: isPremium
                                              ? () => _showCoachingSheet(context, ref, ex.id)
                                              : null,
                                          coachingHasContent: isPremium &&
                                              ((ref.watch(exerciseInstructionsProvider(ex.id)).valueOrNull?.setup.sentences.isNotEmpty ?? false) ||
                                               (ref.watch(exerciseInstructionsProvider(ex.id)).valueOrNull?.movement.sentences.isNotEmpty ?? false) ||
                                               (ref.watch(exerciseInstructionsProvider(ex.id)).valueOrNull?.breathingCue?.sentences.isNotEmpty ?? false) ||
                                               ref.watch(exerciseInstructionsProvider(ex.id)).valueOrNull?.goodFormFeels != null ||
                                               (ref.watch(exerciseInstructionsProvider(ex.id)).valueOrNull?.commonFixes.isNotEmpty ?? false)),
                                          onInfoTap: () {
                                            unawaited(
                                              ref
                                                  .read(
                                                    scorecardUpdateServiceProvider,
                                                  )
                                                  .onCuriosityInteraction(
                                                    ScorecardInteractionKind
                                                        .instructionViewed,
                                                  ),
                                            );
                                            ExerciseInstructionsSheet.show(
                                              context,
                                              ref,
                                              ex.id,
                                              exerciseName: ex.name,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (nextEx != null)
                          _ExercisePeekStrip(
                            name: nextEx.name,
                            label: () {
                              final currentGroup = _supersetGroupIdOf(
                                selectedExercises[safeIndex].id,
                                setsByExercise,
                              );
                              final nextGroup =
                                  _supersetGroupIdOf(nextEx.id, setsByExercise);
                              return (currentGroup != null &&
                                      currentGroup == nextGroup)
                                  ? 'Next in superset'
                                  : 'Next';
                            }(),
                            compact: true,
                            onTap: () {
                              setState(() => _activeExerciseId = nextEx.id);
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  safeIndex + 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                            child: AppText(
                              'Last exercise — tap End Workout when done.',
                              style: AppTextStyle.caption,
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Center(
            child: ElevatedButton(
              onPressed: selectedExercises.isEmpty
                  ? null
                  : () {
                      ref.read(hapticsServiceProvider).heavy();
                      widget.onSessionComplete(setsByExercise);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                elevation: 2,
              ),
              child: const Text('End Workout'),
            ),
          ),
        ),
      ],
      ),
    );
  }

  /// On set complete: handle superset auto-advance or standard rest timer logic.
  void _onSetComplete(
    WidgetRef ref,
    String exerciseId,
    List<Map<String, dynamic>> activeSets,
    int completedSetIndex0Based,
    String? nextExerciseId,
    Map<String, dynamic> completedSet,
  ) {
    final setsByExercise = ref.read(loggerSessionProvider)?.setsByExercise ?? {};
    final allExercises = ref.read(loggerSessionProvider)?.exercises ?? [];
    final groupId = _supersetGroupIdOf(exerciseId, setsByExercise);

    if (groupId != null) {
      final groupExercises =
          _groupExercisesInOrder(groupId, allExercises, setsByExercise);
      final isLastInGroup = groupExercises.lastOrNull?.id == exerciseId;

      if (!isLastInGroup) {
        // Non-final superset exercise: auto-scroll to next in group, no rest
        if (nextExerciseId != null) {
          _scrollToExerciseId(nextExerciseId);
        }
        return;
      }

      // Final exercise in the group
      final isLastRound = completedSetIndex0Based + 1 >= activeSets.length;
      if (isLastRound) {
        // All rounds done: rest normally, advance past group when rest ends
        _pendingGroupReturnExId = null;
        _startRestWithContext(
          ref, exerciseId, activeSets, completedSetIndex0Based, nextExerciseId,
        );
      } else {
        // More rounds: fire rest, then return to first in group
        final completedRound = completedSetIndex0Based + 1;
        final totalRounds = activeSets.length;
        final remainingRounds = totalRounds - completedRound;
        _pendingGroupReturnExId = groupExercises.first.id;
        ref.read(restTimerProvider.notifier).start(
          customTitle: 'Round $completedRound complete',
          customSubtitle: remainingRounds == 1
              ? 'Last round — well done!'
              : '$remainingRounds more rounds to go',
        );
      }
    } else {
      // Non-superset: original behaviour
      final isGuided = ref.read(audioCoachingSettingsProvider).isGuided;
      if (isGuided) {
        unawaited(_playTemplate4ThenRest(
          ref,
          exerciseId,
          activeSets,
          completedSetIndex0Based,
          nextExerciseId,
          completedSet,
        ));
      } else {
        _startRestWithContext(ref, exerciseId, activeSets, completedSetIndex0Based, nextExerciseId);
      }
    }
  }

  Future<void> _playTemplate4ThenRest(
    WidgetRef ref,
    String exerciseId,
    List<Map<String, dynamic>> activeSets,
    int completedSetIndex0Based,
    String? nextExerciseId,
    Map<String, dynamic> completedSet,
  ) async {
    try {
      final premium = await ref.read(premiumServiceProvider).isPremium();
      if (!premium) {
        _startRestWithContext(ref, exerciseId, activeSets, completedSetIndex0Based, nextExerciseId);
        return;
      }
      final engine = ref.read(audioTemplateEngineProvider);
      final audio = ref.read(audioServiceProvider);
      final hasNextSet = completedSetIndex0Based + 1 < activeSets.length;
      final isFinalSet = !hasNextSet;
      final currentWeight = (completedSet['weight'] as num?)?.toDouble();
      final nextSet = !isFinalSet ? activeSets[completedSetIndex0Based + 1] : null;
      final nextWeight = nextSet != null ? (nextSet['weight'] as num?)?.toDouble() : null;

      final specs = engine.template4SameExerciseNextSet(
        isFinalSetOfExercise: isFinalSet,
        currentSetWeight: currentWeight,
        nextSetProgrammedWeight: nextWeight,
      );
      if (!widget.isAudioMuted()) {
        await audio.playSequence(specs);
      }
    } catch (_) {
      // Audio is enhancement only; continue to start rest
    }
    if (!mounted) return;

    final hasNextSet = completedSetIndex0Based + 1 < activeSets.length;
    final isFinalSet = !hasNextSet;
    final isFinalExercise = nextExerciseId == null;

    // After the final set of the final exercise the workout is over — no rest needed.
    if (isFinalSet && isFinalExercise) return;

    _startRestWithContext(ref, exerciseId, activeSets, completedSetIndex0Based, nextExerciseId);
  }

  void _showCoachingSheet(BuildContext context, WidgetRef ref, String exerciseId) {
    unawaited(_showCoachingSheetAsync(context, ref, exerciseId));
  }

  Future<void> _showCoachingSheetAsync(
      BuildContext context, WidgetRef ref, String exerciseId) async {
    try {
      final instructions =
          await ref.read(exerciseInstructionsProvider(exerciseId).future);
      final sentences = await ref.read(sentenceLibraryProvider.future);
      if (!context.mounted || instructions == null) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => CoachingPanel(
          instructions: instructions,
          sentences: sentences,
          onSetupTap: () => unawaited(
              _playOnDemandCueField(ref, exerciseId, (i) => i.setup)),
          onMovementTap: () => unawaited(
              _playOnDemandCueField(ref, exerciseId, (i) => i.movement)),
          onBreathingTap: () => unawaited(
              _playOnDemandCueField(ref, exerciseId, (i) => i.breathingCue)),
          onGoodFormTap: () => unawaited(_playCueByIndex(ref, exerciseId, 0)),
          onFix1Tap: () => unawaited(_playCueByIndex(ref, exerciseId, 1)),
          onFix2Tap: () => unawaited(_playCueByIndex(ref, exerciseId, 2)),
        ),
      );
    } catch (_) {}
  }

  Future<void> _playCueByIndex(WidgetRef ref, String exerciseId, int index) async {
    if (widget.isAudioMuted()) return;
    try {
      final instructions = await ref.read(exerciseInstructionsProvider(exerciseId).future);
      final sentences = await ref.read(sentenceLibraryProvider.future);
      if (instructions == null) return;
      final hasFix2 = instructions.commonFixes.length >= 2;
      final tier = ref.read(audioClipPathsProvider).sessionCoachingTierOrBeginner;
      final engine = ref.read(audioTemplateEngineProvider);
      final audio = ref.read(audioServiceProvider);
      final specs = index == 0
          ? engine.template6OnDemandGoodForm(
              instructions: instructions,
              tier: tier,
              sentences: sentences,
            )
          : index == 1
              ? engine.template7OnDemandCommonFix1(
                  instructions: instructions,
                  tier: tier,
                  sentences: sentences,
                )
              : engine.template8OnDemandCommonFix2(
                  instructions: instructions,
                  tier: tier,
                  sentences: sentences,
                  hasFix2: hasFix2,
                );
      await audio.playSequence(specs);
    } catch (_) {}
  }

  /// Plays a named cue field on demand using a selector function.
  /// Resolves [ExerciseCueField] via [selector], builds specs with
  /// [audioSpecsForCueField], and dispatches to [AudioService.playSequence].
  /// No-ops when muted, field is null, or field has no sentences.
  Future<void> _playOnDemandCueField(
    WidgetRef ref,
    String exerciseId,
    ExerciseCueField? Function(ExerciseInstructions) selector,
  ) async {
    if (widget.isAudioMuted()) return;
    try {
      final instructions =
          await ref.read(exerciseInstructionsProvider(exerciseId).future);
      final sentences = await ref.read(sentenceLibraryProvider.future);
      if (instructions == null) return;
      final field = selector(instructions);
      if (field == null || field.sentences.isEmpty) return;
      final tier = ref.read(audioClipPathsProvider).sessionCoachingTierOrBeginner;
      final specs = audioSpecsForCueField(
        field: field,
        tier: tier,
        sentences: sentences,
      );
      await ref.read(audioServiceProvider).playSequence(specs);
    } catch (_) {}
  }

  /// Starts the rest timer immediately and schedules T5 rest-end audio asynchronously.
  /// For exercise transitions: fires T3a (teaser) immediately before the timer starts.
  void _startRestWithContext(
    WidgetRef ref,
    String currentExerciseId,
    List<Map<String, dynamic>> activeSets,
    int completedSetIndex0Based,
    String? nextExerciseId,
  ) {
    final hasNextInSameExercise = completedSetIndex0Based + 1 < activeSets.length;

    // T3a: fire teaser immediately when transitioning to a new exercise
    if (!hasNextInSameExercise && nextExerciseId != null && !widget.isAudioMuted()) {
      try {
        unawaited(ref.read(audioServiceProvider).playSequence(
          ref.read(audioTemplateEngineProvider)
              .template3aExerciseTeaser(exerciseId: nextExerciseId),
        ));
      } catch (_) {
        // Audio is enhancement only; do not block rest timer
      }
    }

    // Start rest timer immediately — countdown begins now
    ref.read(restTimerProvider.notifier).start(
      completedExerciseId: currentExerciseId,
    );

    // Schedule T5 notification asynchronously (uses timer's remaining time for end time)
    unawaited(_scheduleRestEndAudioAsync(
      ref,
      hasNextInSameExercise: hasNextInSameExercise,
      currentExerciseId: currentExerciseId,
      activeSets: activeSets,
      completedSetIndex0Based: completedSetIndex0Based,
      nextExerciseId: nextExerciseId,
    ));
  }

  /// Builds T5 rest-end specs and stores them in [_pendingRestEndSpecs].
  /// Called after the timer has already started. Specs play in-process when
  /// the rest timer fires (wasActive && !nowActive in the listener above).
  Future<void> _scheduleRestEndAudioAsync(
    WidgetRef ref, {
    required bool hasNextInSameExercise,
    required String currentExerciseId,
    required List<Map<String, dynamic>> activeSets,
    required int completedSetIndex0Based,
    required String? nextExerciseId,
  }) async {
    try {
      // Only build specs in guided mode.
      final settings = ref.read(audioCoachingSettingsProvider);
      if (!settings.isGuided) return;

      // Only build specs for premium users.
      final premium = await ref.read(premiumStatusProvider.future);
      if (!mounted) return;
      if (!premium) return;

      final String contextExId;
      final int nextSetIndex1Based;
      final bool isFirstSet;
      final bool isLastSet;

      if (hasNextInSameExercise) {
        contextExId = currentExerciseId;
        nextSetIndex1Based = completedSetIndex0Based + 2;
        isFirstSet = false;
        isLastSet = nextSetIndex1Based == activeSets.length;
      } else if (nextExerciseId != null) {
        contextExId = nextExerciseId;
        nextSetIndex1Based = 1;
        isFirstSet = true;
        final nextSets =
            ref.read(loggerSessionProvider)?.setsByExercise[nextExerciseId] ?? const [];
        isLastSet = nextSets.length <= 1;
      } else {
        return;
      }

      final instructions =
          await ref.read(exerciseInstructionsProvider(contextExId).future);
      if (!mounted || instructions == null) return;

      final sentences = await ref.read(sentenceLibraryProvider.future);
      if (!mounted) return;

      final engine = ref.read(audioTemplateEngineProvider);
      final tier = ref.read(audioClipPathsProvider).sessionCoachingTierOrBeginner;

      _pendingRestEndSpecs = engine.template5RestEnd(
        exerciseId: contextExId,
        setIndex1Based: nextSetIndex1Based,
        isFirstSetOfExercise: isFirstSet,
        isLastSetOfExercise: isLastSet,
        instructions: instructions,
        sentences: sentences,
        tier: tier,
      );
    } catch (_) {}
  }

  /// After logging a failed set, if there was already a recent failure for this exercise, nudge regression.
  Future<void> _maybeShowRegressionHint(
    WidgetRef ref,
    BuildContext context,
    Exercise exercise,
  ) async {
    try {
      final entries = await ref.read(workoutEntryRepositoryProvider).findByExercise(exercise.id);
      final priorFailed = FailedSetAdjuster.consecutiveFailedStreakFromNewest(entries);
      if (!context.mounted || priorFailed < 1) return;
      final allExercises = ref.read(exercisesFutureProvider).value ?? const <Exercise>[];
      String? regName;
      final regId = exercise.regressionId;
      if (regId != null) {
        for (final e in allExercises) {
          if (e.id == regId) {
            regName = e.name;
            break;
          }
        }
      }
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final text = regName != null
          ? 'Repeated misses — consider easier variation: $regName'
          : 'Repeated misses — consider a lighter or easier variation.';
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } catch (_) {}
  }
}

/// Wraps the focus card with elevation and primary-tinted border for carousel emphasis.
class _FocusCardWrapper extends StatelessWidget {
  final Widget child;

  const _FocusCardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final radii = context.themeExt<AppRadii>();
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radii.lg),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radii.lg),
        child: child,
      ),
    );
  }
}

/// Small tappable strip for previous/next exercise in the carousel.
class _ExercisePeekStrip extends StatelessWidget {
  final String name;
  final String? label;
  final bool compact;
  final VoidCallback onTap;

  const _ExercisePeekStrip({
    required this.name,
    this.label,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final padding = compact
        ? EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.xs)
        : EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md);
    final textStyle = compact ? AppTextStyle.caption : AppTextStyle.label;
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (label != null) ...[
                AppText(label!, style: textStyle),
                SizedBox(width: spacing.sm),
              ],
              Expanded(
                child: AppText(name, style: textStyle, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 