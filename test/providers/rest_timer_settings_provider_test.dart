import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 5; i++) {
      final state = container.read(restTimerSettingsProvider);
      if (!state.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('loads default value when no preference exists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(restTimerSettingsProvider);
    expect(state.defaultSeconds, 120);
    expect(state.hapticsEnabled, isTrue);
    expect(state.soundEnabled, isTrue);
    expect(state.isLoading, isFalse);
  });

  test('persists updated default seconds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(restTimerSettingsProvider.notifier).setDefaultSeconds(150);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('restTimerDefaultSeconds'), 150);
  });

  test('persists haptics and sound toggles', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(restTimerSettingsProvider.notifier).setHapticsEnabled(false);
    await container.read(restTimerSettingsProvider.notifier).setSoundEnabled(false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('restTimerHapticsEnabled'), isFalse);
    expect(prefs.getBool('restTimerSoundEnabled'), isFalse);
  });

  test('restores persisted value on new container', () async {
    SharedPreferences.setMockInitialValues({
      'restTimerDefaultSeconds': 180,
      'restTimerHapticsEnabled': false,
      'restTimerSoundEnabled': false,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(restTimerSettingsProvider);
    expect(state.defaultSeconds, 180);
    expect(state.hapticsEnabled, isFalse);
    expect(state.soundEnabled, isFalse);
    expect(state.isLoading, isFalse);
  });
}
