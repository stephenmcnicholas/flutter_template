import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/utils/format_utils.dart';

class RestTimerSettingsScreen extends ConsumerWidget {
  const RestTimerSettingsScreen({super.key});

  static const int _stepSeconds = 5;
  static const int _minSeconds = 5;
  static const int _maxSeconds = 3600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(restTimerSettingsProvider);
    final notifier = ref.read(restTimerSettingsProvider.notifier);
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    final canDecrease = settings.defaultSeconds > _minSeconds;
    final canIncrease = settings.defaultSeconds < _maxSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rest Timer'),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Default duration',
              style: AppTextStyle.title,
            ),
            SizedBox(height: spacing.md),
            AppCard(
              child: Column(
                children: [
                  AppText(
                    formatDuration(settings.defaultSeconds),
                    style: AppTextStyle.display,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: spacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: canDecrease
                            ? () => notifier.setDefaultSeconds(
                                  settings.defaultSeconds - _stepSeconds,
                                )
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: colors.primary,
                        iconSize: 32,
                        tooltip: 'Decrease by 5 seconds',
                      ),
                      SizedBox(width: spacing.lg),
                      IconButton(
                        onPressed: canIncrease
                            ? () => notifier.setDefaultSeconds(
                                  settings.defaultSeconds + _stepSeconds,
                                )
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: colors.primary,
                        iconSize: 32,
                        tooltip: 'Increase by 5 seconds',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.md),
            AppText(
              'Adjust in 5-second increments.',
              style: AppTextStyle.caption,
              color: colors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
