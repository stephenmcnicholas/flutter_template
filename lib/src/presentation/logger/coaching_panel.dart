import 'package:flutter/material.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

/// Coaching advice panel: tap rows to hear cues on demand.
/// Rows shown (when content exists, in order):
///   1. How to set up   (setup sentences)
///   2. Movement cue    (movement sentences)
///   3. Breathing       (breathingCue non-null)
///   4. Good form feels like  (goodFormFeels non-null)
///   5. Fix 1 / Fix 2   (commonFixes)
class CoachingPanel extends StatelessWidget {
  final ExerciseInstructions instructions;
  final SentenceLibrary sentences;
  final VoidCallback? onSetupTap;
  final VoidCallback? onMovementTap;
  final VoidCallback? onBreathingTap;
  final VoidCallback? onGoodFormTap;
  final VoidCallback? onFix1Tap;
  final VoidCallback? onFix2Tap;

  const CoachingPanel({
    super.key,
    required this.instructions,
    required this.sentences,
    this.onSetupTap,
    this.onMovementTap,
    this.onBreathingTap,
    this.onGoodFormTap,
    this.onFix1Tap,
    this.onFix2Tap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    final hasSetup    = instructions.setup.sentences.isNotEmpty;
    final hasMovement = instructions.movement.sentences.isNotEmpty;
    // Non-null AND has sentences — a breathingCue key with no sentences produces no audio.
    final hasBreathing = instructions.breathingCue?.sentences.isNotEmpty == true;
    final hasGoodForm = instructions.goodFormFeels != null;
    final fixes = instructions.commonFixes;

    if (!hasSetup && !hasMovement && !hasBreathing && !hasGoodForm && fixes.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: AppText(
          'No coaching cues available for this exercise.',
          style: AppTextStyle.body,
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.lg,
          spacing.lg,
          spacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: spacing.lg),
              decoration: BoxDecoration(
                color: colors.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppText('Coaching', style: AppTextStyle.title),
          SizedBox(height: spacing.md),

          if (hasSetup)
            _CoachingRow(
              icon: Icons.tune,
              iconColor: colors.outline,
              label: 'How to set up',
              onTap: onSetupTap,
            ),

          if (hasMovement)
            _CoachingRow(
              icon: Icons.directions_run,
              iconColor: colors.outline,
              label: 'Movement cue',
              onTap: onMovementTap,
            ),

          if (hasBreathing)
            _CoachingRow(
              icon: Icons.air,
              iconColor: colors.outline,
              label: 'Breathing',
              onTap: onBreathingTap,
            ),

          if (hasGoodForm)
            _CoachingRow(
              icon: Icons.star_border_rounded,
              iconColor: Colors.amber,
              label: 'Good form feels like',
              onTap: onGoodFormTap,
            ),

          if (fixes.isNotEmpty)
            _CoachingRow(
              icon: Icons.lightbulb_outline,
              iconColor: colors.primary,
              label: sentences.getText(fixes[0].issue),
              onTap: onFix1Tap,
            ),

          if (fixes.length >= 2)
            _CoachingRow(
              icon: Icons.lightbulb_outline,
              iconColor: colors.primary,
              label: sentences.getText(fixes[1].issue),
              onTap: onFix2Tap,
            ),
        ],
      ),
    ),
    );
  }
}

class _CoachingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _CoachingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.sm),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            SizedBox(width: spacing.md),
            Expanded(
              child: AppText(label, style: AppTextStyle.body),
            ),
            Icon(
              Icons.play_circle_outline,
              color: iconColor.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
