import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_adaptive_policy.dart';
import 'package:fytter/src/domain/rule_engine/workout_adjuster.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/data/programme_intensity_store.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/providers/scorecard_update_service.dart';
import 'package:fytter/src/providers/user_scorecard_provider.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:uuid/uuid.dart';

class PreWorkoutCheckInScreen extends ConsumerStatefulWidget {
  final PreWorkoutCheckInArgs args;

  const PreWorkoutCheckInScreen({super.key, required this.args});

  @override
  ConsumerState<PreWorkoutCheckInScreen> createState() =>
      _PreWorkoutCheckInScreenState();
}

class _PreWorkoutCheckInScreenState extends ConsumerState<PreWorkoutCheckInScreen> {
  CheckInRating? _selectedRating;
  final _freeTextController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  Future<void> _saveAndProceed(CheckInRating rating) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(sessionCheckInRepositoryProvider);
    final checkIn = SessionCheckIn(
      id: const Uuid().v4(),
      sessionId: null,
      programmeId: widget.args.programId,
      checkInType: CheckInType.preWorkout,
      rating: rating,
      freeText: _freeTextController.text.trim().isNotEmpty
          ? _freeTextController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );
    await repo.save(checkIn);

    if (!mounted) return;
    final scorecard = await ref.read(userScorecardProvider.future);
    if (!mounted) return;
    final premium = ref.read(workoutAdaptationPremiumProvider);
    final loadScale = await ProgrammeIntensityStore.loadScaleForProgram(widget.args.programId);
    PreWorkoutCheckInArgs outArgs = WorkoutAdjuster.adjust(
      args: widget.args,
      rating: rating,
      premiumAdaptation: premium,
      programmeLoadScale: loadScale,
      scorecard: scorecard,
    );

    var recordAdaptability = false;
    var adjustmentAccepted = false;
    if (premium && rating == CheckInRating.red) {
      recordAdaptability = true;
      final text = _freeTextController.text.trim();
      final canLlm = widget.args.initialSetsByExercise != null &&
          widget.args.initialSetsByExercise!.isNotEmpty &&
          widget.args.initialExercises.isNotEmpty &&
          text.isNotEmpty;
      if (canLlm) {
        try {
          outArgs = await ref.read(workoutAdjustmentServiceProvider).adjustPreWorkoutWithLlm(
                args: widget.args,
                userIssue: text,
              );
          adjustmentAccepted = true;
        } catch (_) {
          outArgs = WorkoutAdjuster.adjust(
            args: widget.args,
            rating: CheckInRating.amber,
            premiumAdaptation: true,
            programmeLoadScale: loadScale,
            scorecard: scorecard,
          );
          adjustmentAccepted = false;
        }
      } else {
        outArgs = WorkoutAdjuster.adjust(
          args: widget.args,
          rating: CheckInRating.amber,
          premiumAdaptation: true,
          programmeLoadScale: loadScale,
          scorecard: scorecard,
        );
        adjustmentAccepted = false;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (recordAdaptability) {
      unawaited(
        ref.read(scorecardUpdateServiceProvider).onPreWorkoutAdaptability(
              adjustmentAccepted: adjustmentAccepted,
            ),
      );
    }
    Navigator.of(context).pop(outArgs);
  }

  void _onSkip() {
    Navigator.of(context).pop(widget.args);
  }

  void _onOptionTap(CheckInRating rating) {
    setState(() => _selectedRating = rating);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final isPremium = ref.watch(workoutAdaptationPremiumProvider);
    final checkInSubtitle = isPremium
        ? ref.watch(userScorecardProvider).maybeWhen(
            data: (s) => ScorecardAdaptivePolicy.preWorkoutSubtitle(
              ScorecardAdaptivePolicy.checkInDensity(s?.computedLevel ?? 1),
            ),
            orElse: () => ScorecardAdaptivePolicy.preWorkoutSubtitle(
              CheckInPromptDensity.full,
            ),
          )
        : 'Track how you feel over time. Upgrade to premium for real-time workout adjustments.';

    return Scaffold(
      appBar: AppBar(
        title: AppText('How are you feeling?', style: AppTextStyle.title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSkip,
            child: AppText('Skip', style: AppTextStyle.label),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: spacing.md),
              AppText(
                checkInSubtitle,
                style: AppTextStyle.body,
              ),
              SizedBox(height: spacing.xl),
              _OptionCard(
                emoji: '🟢',
                label: "Let's go",
                subtitle: 'Ready to train',
                color: colors.success,
                isSelected: _selectedRating == CheckInRating.green,
                onTap: () {
                  _onOptionTap(CheckInRating.green);
                  _saveAndProceed(CheckInRating.green);
                },
              ),
              SizedBox(height: spacing.md),
              _OptionCard(
                emoji: '🟡',
                label: 'Fine',
                subtitle: 'Not great, but I can train',
                color: colors.warning,
                isSelected: _selectedRating == CheckInRating.amber,
                onTap: () {
                  _onOptionTap(CheckInRating.amber);
                  _saveAndProceed(CheckInRating.amber);
                },
              ),
              SizedBox(height: spacing.md),
              _OptionCard(
                emoji: '🔴',
                label: 'Some concerns',
                subtitle: 'Not feeling it today',
                color: colors.error,
                isSelected: _selectedRating == CheckInRating.red,
                onTap: () => _onOptionTap(CheckInRating.red),
              ),
              if (_selectedRating == CheckInRating.red) ...[
                SizedBox(height: spacing.md),
                if (ref.watch(workoutAdaptationPremiumProvider)) ...[
                  // Premium: show text input for LLM-based adjustment
                  Padding(
                    padding: EdgeInsets.only(left: spacing.md),
                    child: AppText(
                      "What's going on? Sharing helps us adjust (e.g. skip heavy sets, suggest alternatives).",
                      style: AppTextStyle.caption,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Padding(
                    padding: EdgeInsets.only(left: spacing.md),
                    child: TextField(
                      controller: _freeTextController,
                      decoration: InputDecoration(
                        hintText: 'e.g. tired, sore shoulder, low sleep',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 2,
                      onSubmitted: (_) => _saveAndProceed(CheckInRating.red),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  AppButton(
                    label: 'Continue',
                    onPressed: () => _saveAndProceed(CheckInRating.red),
                    isFullWidth: true,
                    isLoading: _isSaving,
                  ),
                ] else ...[
                  // Free user: upsell — no text collected since it won't be acted on
                  Padding(
                    padding: EdgeInsets.only(left: spacing.md),
                    child: AppText(
                      "Tell us what's going on and we'll adjust today's session. Upgrade to premium to unlock.",
                      style: AppTextStyle.body,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  AppButton(
                    label: 'Continue anyway',
                    onPressed: () => _saveAndProceed(CheckInRating.red),
                    isFullWidth: true,
                    isLoading: _isSaving,
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return Material(
      color: isSelected ? color.withValues(alpha: 0.12) : null,
      borderRadius: BorderRadius.circular(radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(label, style: AppTextStyle.title),
                    AppText(subtitle, style: AppTextStyle.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
