import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/theme_settings_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 5; i++) {
      final state = container.read(themeSettingsProvider);
      if (!state.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('loads system theme when no preference exists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(themeSettingsProvider);
    expect(state.mode, ThemeMode.system);
    expect(state.isLoading, isFalse);
  });

  test('setThemeMode updates state and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(themeSettingsProvider.notifier).setThemeMode(ThemeMode.dark);

    expect(container.read(themeSettingsProvider).mode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'dark');
  });

  test('restores persisted theme on new container', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(themeSettingsProvider);
    expect(state.mode, ThemeMode.light);
    expect(state.isLoading, isFalse);
  });

  test('themeModeLabel returns correct labels', () {
    expect(themeModeLabel(ThemeMode.light), 'Light');
    expect(themeModeLabel(ThemeMode.dark), 'Dark');
    expect(themeModeLabel(ThemeMode.system), 'System');
  });

  test('ThemeSettingsState copyWith', () {
    const state = ThemeSettingsState(mode: ThemeMode.system, isLoading: false);
    expect(state.copyWith(mode: ThemeMode.dark).mode, ThemeMode.dark);
    expect(state.copyWith(isLoading: true).isLoading, isTrue);
  });
}
