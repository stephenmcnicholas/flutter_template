import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 5; i++) {
      final state = container.read(notificationSettingsProvider);
      if (!state.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('initial state has isLoading true then loads default false', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(notificationSettingsProvider);
    expect(state.notificationsEnabled, isFalse);
    expect(state.reminderTimeMinutes, 8 * 60);
    expect(state.isLoading, isFalse);
  });

  test('setNotificationsEnabled updates state and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(notificationSettingsProvider.notifier).setNotificationsEnabled(true);

    expect(container.read(notificationSettingsProvider).notificationsEnabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isTrue);
  });

  test('setReminderTimeMinutes updates state and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container
        .read(notificationSettingsProvider.notifier)
        .setReminderTimeMinutes(21 * 60 + 30);

    expect(
      container.read(notificationSettingsProvider).reminderTimeMinutes,
      21 * 60 + 30,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('notifications_reminder_time_minutes'), 21 * 60 + 30);
  });

  test('setNotificationsEnabled to false persists', () async {
    SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    SharedPrefs.instance.resetForTests();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    expect(container.read(notificationSettingsProvider).notificationsEnabled, isTrue);

    await container.read(notificationSettingsProvider.notifier).setNotificationsEnabled(false);
    expect(container.read(notificationSettingsProvider).notificationsEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isFalse);
  });

  test('restores persisted value on new container', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'notifications_reminder_time_minutes': 21 * 60 + 5,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(notificationSettingsProvider);
    expect(state.notificationsEnabled, isTrue);
    expect(state.reminderTimeMinutes, 21 * 60 + 5);
    expect(state.isLoading, isFalse);
  });

  test('NotificationSettingsState copyWith', () {
    const state = NotificationSettingsState(
      notificationsEnabled: false,
      reminderTimeMinutes: 8 * 60,
      isLoading: false,
    );
    expect(state.copyWith(notificationsEnabled: true).notificationsEnabled, isTrue);
    expect(state.copyWith(reminderTimeMinutes: 9 * 60).reminderTimeMinutes, 9 * 60);
    expect(state.copyWith(isLoading: true).isLoading, isTrue);
  });
}
