import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/presentation/exercise/exercise_instruction_text.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';

/// Modal bottom sheet showing full exercise instructions (setup, movement,
/// cues, common mistakes). Used from the workout logger active card [i] button.
class ExerciseInstructionsSheet extends ConsumerWidget {
  final String exerciseId;
  final String? exerciseName;
  final ScrollController? scrollController;

  /// Shows the instructions sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, WidgetRef ref, String exerciseId, {String? exerciseName}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ExerciseInstructionsSheet(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          scrollController: scrollController,
        ),
      ),
    );
  }

  const ExerciseInstructionsSheet({
    super.key,
    required this.exerciseId,
    this.exerciseName,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructionsAsync = ref.watch(exerciseInstructionsProvider(exerciseId));
    final sentenceLibraryAsync = ref.watch(sentenceLibraryProvider);
    final spacing = context.themeExt<AppSpacing>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: AppText(
            exerciseName ?? 'Instructions',
            style: AppTextStyle.title,
          ),
        ),
        Flexible(
          child: instructionsAsync.when(
            data: (instructions) {
              if (instructions == null) {
                return Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Center(
                    child: AppText('No instructions for this exercise.', style: AppTextStyle.body),
                  ),
                );
              }
              return sentenceLibraryAsync.when(
                data: (lib) => SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(spacing.lg),
                  child: buildExerciseInstructionsSheetBody(context, instructions, lib),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Center(
                    child: AppText('Could not load sentence library.', style: AppTextStyle.body),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: EdgeInsets.all(spacing.xl),
              child: Center(
                child: AppText('Could not load instructions.', style: AppTextStyle.body),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildExerciseInstructionsSheetBody(
  BuildContext context,
  ExerciseInstructions instructions,
  SentenceLibrary lib,
) {
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
      child: AppText(title, style: AppTextStyle.label, fontWeight: FontWeight.w600),
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
        sectionTitle('Common mistakes & fixes'),
        ...instructions.commonFixes.map((fix) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(lib.getText(fix.issue), style: AppTextStyle.body, fontWeight: FontWeight.w600),
                SizedBox(height: spacing.xs),
                AppText(
                  ExerciseInstructionText.paragraphFromFixIds(fix.fix, lib),
                  style: AppTextStyle.body,
                ),
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
