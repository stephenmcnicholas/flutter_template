import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/presentation/logger/coaching_panel.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/services/audio/audio_sentence_specs.dart';
import 'package:fytter/src/services/audio/audio_service.dart' show AudioClipSpec;
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:go_router/go_router.dart';

/// Full-screen overlay that displays the rest timer when workout logger is maximized
class RestTimerOverlay extends ConsumerWidget {
  final VoidCallback? onMinimize;
  
  const RestTimerOverlay({super.key, this.onMinimize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    
    if (!timerState.isActive) {
      return const SizedBox.shrink();
    }

    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // Allow tapping the background to minimize
        onTap: onMinimize,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.7),
          child: Center(
            child: GestureDetector(
              // Prevent taps on the card from minimizing
              onTap: () {},
              child: Container(
            margin: EdgeInsets.all(spacing.xl),
            padding: EdgeInsets.all(spacing.xxl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timerState.customTitle ?? 'Rest Timer',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                        ),
                        if (timerState.customSubtitle != null) ...[
                          SizedBox(height: spacing.xs),
                          Text(
                            timerState.customSubtitle!,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.outline,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings/rest-timer'),
                      icon: const Icon(Icons.settings),
                      tooltip: 'Rest timer settings',
                      color: colors.primary,
                    ),
                  ],
                ),
                SizedBox(height: spacing.xl),
                
                // Timer display
                Text(
                  timerState.formattedTime,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 72,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: spacing.xl),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrease button
                    IconButton(
                      onPressed: () => ref.read(restTimerProvider.notifier).decreaseDuration(),
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Decrease 15 seconds',
                    ),
                    SizedBox(width: spacing.lg),

                    // Skip button
                    ElevatedButton.icon(
                      onPressed: () => ref.read(restTimerProvider.notifier).skip(),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.lg),

                    // Increase button
                    IconButton(
                      onPressed: () => ref.read(restTimerProvider.notifier).increaseDuration(),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Increase 15 seconds',
                    ),
                  ],
                ),
                if (timerState.completedExerciseId != null) ...[
                  Divider(color: colors.outline.withValues(alpha: 0.2)),
                  SizedBox(height: spacing.sm),
                  _CoachingPanelInRest(completedExerciseId: timerState.completedExerciseId!),
                ],
              ],
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coaching cues embedded in the rest timer overlay. Loads instructions
/// lazily; no-ops silently if unavailable.
class _CoachingPanelInRest extends ConsumerWidget {
  final String completedExerciseId;
  const _CoachingPanelInRest({required this.completedExerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instrAsync = ref.watch(exerciseInstructionsProvider(completedExerciseId));
    final sentAsync = ref.watch(sentenceLibraryProvider);

    return instrAsync.when(
      data: (instructions) => sentAsync.when(
        data: (sentences) {
          if (instructions == null) return const SizedBox.shrink();
          final hasContent = instructions.goodFormFeels != null ||
              instructions.commonFixes.isNotEmpty;
          if (!hasContent) return const SizedBox.shrink();
          return CoachingPanel(
            instructions: instructions,
            sentences: sentences,
            onSetupTap: () => _play(ref, instructions, sentences, 3),
            onMovementTap: () => _play(ref, instructions, sentences, 4),
            onBreathingTap: () => _play(ref, instructions, sentences, 5),
            onGoodFormTap: () => _play(ref, instructions, sentences, 0),
            onFix1Tap: () => _play(ref, instructions, sentences, 1),
            onFix2Tap: () => _play(ref, instructions, sentences, 2),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _play(
    WidgetRef ref,
    ExerciseInstructions instructions,
    SentenceLibrary sentences,
    int cueIndex,
  ) {
    final tier = ref.read(audioClipPathsProvider).sessionCoachingTierOrBeginner;
    final engine = ref.read(audioTemplateEngineProvider);
    final audio = ref.read(audioServiceProvider);
    final List<AudioClipSpec> specs;
    switch (cueIndex) {
      case 0:
        specs = engine.template6OnDemandGoodForm(instructions: instructions, tier: tier, sentences: sentences);
      case 1:
        specs = engine.template7OnDemandCommonFix1(instructions: instructions, tier: tier, sentences: sentences);
      case 2:
        specs = engine.template8OnDemandCommonFix2(instructions: instructions, tier: tier, sentences: sentences, hasFix2: instructions.commonFixes.length >= 2);
      case 3:
        specs = audioSpecsForCueField(field: instructions.setup, tier: tier, sentences: sentences);
      case 4:
        specs = audioSpecsForCueField(field: instructions.movement, tier: tier, sentences: sentences);
      case 5:
        final breathing = instructions.breathingCue;
        specs = breathing != null
            ? audioSpecsForCueField(field: breathing, tier: tier, sentences: sentences)
            : [];
      default:
        specs = [];
    }
    unawaited(audio.playSequence(specs));
  }
}
