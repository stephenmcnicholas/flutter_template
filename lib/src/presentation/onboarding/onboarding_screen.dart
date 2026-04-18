import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_profile_provider.dart';
import '../shared/app_button.dart';
import '../theme.dart';

/// First-launch onboarding screen.
///
/// This is a placeholder onboarding flow. Replace with app-specific steps when
/// building a concrete app on top of this template.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome', style: typography.headline),
                    SizedBox(height: spacing.md),
                    Text(
                      'Set up your profile to get started.',
                      style: typography.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Get Started',
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(hasCompletedOnboardingProvider);
                  context.go('/');
                },
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
