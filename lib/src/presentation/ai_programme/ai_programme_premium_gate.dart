import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';

/// Wraps AI programme flow screens so non-premium users cannot use deep links
/// to bypass the Programs tab card (Task 13 — premium gating).
class AiProgrammePremiumGate extends ConsumerWidget {
  const AiProgrammePremiumGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(aiProgrammePremiumProvider);
    if (premium) return child;

    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();

    return Scaffold(
      appBar: AppBar(
        title: AppText(
          AiProgrammeStrings.gateAppBarTitle,
          style: AppTextStyle.title,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              AiProgrammeStrings.teaserTitle,
              style: AppTextStyle.title,
            ),
            SizedBox(height: spacing.md),
            AppText(
              AiProgrammeStrings.teaserBody,
              style: AppTextStyle.body,
              color: colors.outline,
            ),
            SizedBox(height: spacing.lg),
            AppText(
              AiProgrammeStrings.teaserCta,
              style: AppTextStyle.body,
              color: colors.primary,
            ),
            SizedBox(height: spacing.sm),
            AppText(
              AiProgrammeStrings.teaserFootnote,
              style: AppTextStyle.caption,
              color: colors.outline,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              child: const Text(AiProgrammeStrings.gateBack),
            ),
          ],
        ),
      ),
    );
  }
}
