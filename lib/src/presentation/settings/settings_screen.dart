import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_divider.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_coaching_settings_provider.dart';
import 'package:fytter/src/providers/workout_experience_settings_provider.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/providers/theme_settings_provider.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:go_router/go_router.dart';

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
    final restTimerSettings = ref.watch(restTimerSettingsProvider);
    final settingsNotifier = ref.read(restTimerSettingsProvider.notifier);
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
            'Workout',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          AppCard(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Starting a workout',
                        style: AppTextStyle.label,
                      ),
                      SizedBox(height: spacing.sm),
                      Builder(
                        builder: (context) {
                          final experience = ref.watch(workoutExperienceSettingsProvider);
                          final experienceNotifier =
                              ref.read(workoutExperienceSettingsProvider.notifier);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: SegmentedButton<WorkoutExperienceMode>(
                                  segments: const [
                                    ButtonSegment<WorkoutExperienceMode>(
                                      value: WorkoutExperienceMode.guided,
                                      label: Text('Guided'),
                                      icon: Icon(Icons.flag_outlined, size: 18),
                                    ),
                                    ButtonSegment<WorkoutExperienceMode>(
                                      value: WorkoutExperienceMode.logger,
                                      label: Text('Logger'),
                                      icon: Icon(Icons.edit_note, size: 18),
                                    ),
                                  ],
                                  selected: {experience.mode},
                                  onSelectionChanged: (selected) {
                                    experienceNotifier.setMode(selected.single);
                                  },
                                ),
                              ),
                              SizedBox(height: spacing.sm),
                              AppText(
                                experience.isLoggerStart
                                    ? 'Opens the workout logger right away.'
                                    : 'A brief check-in adjusts your session intensity and sets up audio coaching.',
                                style: AppTextStyle.caption,
                                color: colors.outline,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const AppDivider(),
                AppListRow(
                  leading: const Icon(Icons.timer),
                  title: const AppText(
                    'Rest timer default',
                    style: AppTextStyle.body,
                  ),
                  subtitle: AppText(
                    formatDuration(restTimerSettings.defaultSeconds),
                    style: AppTextStyle.caption,
                    color: colors.outline,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/rest-timer'),
                ),
                const AppDivider(),
                AppListRow(
                  leading: const Icon(Icons.vibration),
                  title: const AppText(
                    'Haptics',
                    style: AppTextStyle.body,
                  ),
                  trailing: Switch(
                    value: restTimerSettings.hapticsEnabled,
                    onChanged: (value) => settingsNotifier.setHapticsEnabled(value),
                  ),
                ),
                const AppDivider(),
                AppListRow(
                  leading: const Icon(Icons.volume_up),
                  title: const AppText(
                    'Sound',
                    style: AppTextStyle.body,
                  ),
                  trailing: Switch(
                    value: restTimerSettings.soundEnabled,
                    onChanged: (value) => settingsNotifier.setSoundEnabled(value),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.xl),
          const AppText(
            'Audio coaching',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.md),
          Builder(
            builder: (context) {
              final audioCoaching = ref.watch(audioCoachingSettingsProvider);
              final audioNotifier = ref.read(audioCoachingSettingsProvider.notifier);
              return AppCard(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Mode',
                        style: AppTextStyle.label,
                      ),
                      SizedBox(height: spacing.sm),
                      Center(
                        child: SegmentedButton<AudioCoachingMode>(
                          segments: const [
                            ButtonSegment<AudioCoachingMode>(
                              value: AudioCoachingMode.guided,
                              label: Text('Guided'),
                              icon: Icon(Icons.headphones, size: 18),
                            ),
                            ButtonSegment<AudioCoachingMode>(
                              value: AudioCoachingMode.onDemand,
                              label: Text('On-demand'),
                              icon: Icon(Icons.touch_app, size: 18),
                            ),
                          ],
                          selected: {audioCoaching.mode},
                          onSelectionChanged: (Set<AudioCoachingMode> selected) {
                            final mode = selected.single;
                            audioNotifier.setMode(mode);
                          },
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      AppText(
                        audioCoaching.isGuided
                            ? 'Cues play automatically at key moments.'
                            : 'Tap the speaker icon during a set for cues.',
                        style: AppTextStyle.caption,
                        color: colors.outline,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.xl),
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
                    'Workout reminders',
                    style: AppTextStyle.body,
                  ),
                  subtitle: AppText(
                    'Daily reminder for scheduled program workouts',
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
