import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_divider.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/providers/theme_settings_provider.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/utils/format_utils.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatReminderTime(int minutesSinceMidnight) {
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final unitSettings = ref.watch(unitSettingsProvider);
    final unitNotifier = ref.read(unitSettingsProvider.notifier);
    final themeSettings = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final notificationNotifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const AppText(
            'Notifications',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          AppCard(
            child: Column(
              children: [
                AppListRow(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const AppText(
                    'Reminders',
                    style: AppTextStyle.body,
                  ),
                  subtitle: AppText(
                    'Daily reminders',
                    style: AppTextStyle.caption,
                    color: colors.outline,
                  ),
                  trailing: Switch(
                    value: notificationSettings.notificationsEnabled,
                    onChanged: (value) async {
                      if (value) {
                        final granted = await requestNotificationPermission();
                        if (!granted) return;
                        await notificationNotifier.setNotificationsEnabled(true);
                        await syncNotificationSchedule(ref);
                      } else {
                        await notificationNotifier.setNotificationsEnabled(false);
                      }
                    },
                  ),
                ),
                if (notificationSettings.notificationsEnabled) ...[
                  const AppDivider(),
                  AppListRow(
                    leading: const Icon(Icons.schedule),
                    title: const AppText(
                      'Reminder time',
                      style: AppTextStyle.body,
                    ),
                    subtitle: AppText(
                      _formatReminderTime(notificationSettings.reminderTimeMinutes),
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final minutes = notificationSettings.reminderTimeMinutes;
                      final initial = TimeOfDay(
                        hour: minutes ~/ 60,
                        minute: minutes % 60,
                      );
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                      );
                      if (picked == null) return;
                      await notificationNotifier.setReminderTimeMinutes(
                        picked.hour * 60 + picked.minute,
                      );
                      await syncNotificationSchedule(ref);
                    },
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: spacing.xl),
          const AppText(
            'Appearance',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          AppCard(
            child: Column(
              children: [
                AppListRow(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const AppText(
                    'Theme',
                    style: AppTextStyle.body,
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeSettings.mode,
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                    items: ThemeMode.values
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(themeModeLabel(mode)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.xl),
          const AppText(
            'Units',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          AppCard(
            child: Column(
              children: [
                AppListRow(
                  leading: const Icon(Icons.fitness_center),
                  title: const AppText(
                    'Weight',
                    style: AppTextStyle.body,
                  ),
                  trailing: DropdownButton<WeightUnit>(
                    value: unitSettings.weightUnit,
                    onChanged: (value) {
                      if (value != null) {
                        unitNotifier.setWeightUnit(value);
                      }
                    },
                    items: WeightUnit.values
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(weightUnitLabel(unit)),
                            ))
                        .toList(),
                  ),
                ),
                const AppDivider(),
                AppListRow(
                  leading: const Icon(Icons.route),
                  title: const AppText(
                    'Distance',
                    style: AppTextStyle.body,
                  ),
                  trailing: DropdownButton<DistanceUnit>(
                    value: unitSettings.distanceUnit,
                    onChanged: (value) {
                      if (value != null) {
                        unitNotifier.setDistanceUnit(value);
                      }
                    },
                    items: DistanceUnit.values
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(distanceUnitLabel(unit)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.xl),
          const AppText(
            'About',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          AppCard(
            child: Column(
              children: const [
                AppListRow(
                  leading: Icon(Icons.info_outline),
                  title: AppText(
                    'Version',
                    style: AppTextStyle.body,
                  ),
                  trailing: AppText(
                    '1.0.0',
                    style: AppTextStyle.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
