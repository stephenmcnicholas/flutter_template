import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class NotificationSettingsState {
  final bool notificationsEnabled;
  final int reminderTimeMinutes;
  final bool isLoading;

  const NotificationSettingsState({
    this.notificationsEnabled = false,
    this.reminderTimeMinutes = 8 * 60,
    this.isLoading = true,
  });

  NotificationSettingsState copyWith({
    bool? notificationsEnabled,
    int? reminderTimeMinutes,
    bool? isLoading,
  }) {
    return NotificationSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  static const _prefsKeyNotificationsEnabled = 'notifications_enabled';
  static const _prefsKeyReminderTimeMinutes = 'notifications_reminder_time_minutes';

  NotificationSettingsNotifier()
      : super(const NotificationSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final enabled = await prefs.getBool(_prefsKeyNotificationsEnabled);
    final reminderTime = await prefs.getInt(_prefsKeyReminderTimeMinutes);
    state = state.copyWith(
      notificationsEnabled: enabled ?? false,
      reminderTimeMinutes: reminderTime ?? 8 * 60,
      isLoading: false,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == state.notificationsEnabled && !state.isLoading) return;
    state = state.copyWith(notificationsEnabled: value);
    await SharedPrefs.instance.setBool(_prefsKeyNotificationsEnabled, value);
  }

  Future<void> setReminderTimeMinutes(int value) async {
    if (value < 0 || value > 1439) return;
    if (value == state.reminderTimeMinutes && !state.isLoading) return;
    state = state.copyWith(reminderTimeMinutes: value);
    await SharedPrefs.instance.setInt(_prefsKeyReminderTimeMinutes, value);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
        (ref) => NotificationSettingsNotifier());
