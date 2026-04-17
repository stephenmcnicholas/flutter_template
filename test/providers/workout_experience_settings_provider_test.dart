import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/workout_experience_settings_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> waitForLoad(ProviderContainer container) async {
    // [WorkoutExperienceSettingsNotifier._load] is async after construction.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (!container.read(workoutExperienceSettingsProvider).isLoading) break;
    }
  }

  test('defaults to guided', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();

    final container = ProviderContainer();
    container.read(workoutExperienceSettingsProvider);
    await waitForLoad(container);

    expect(container.read(workoutExperienceSettingsProvider).isLoading, false);
    expect(
      container.read(workoutExperienceSettingsProvider).mode,
      WorkoutExperienceMode.guided,
    );
    container.dispose();
  });

  test('persists logger mode', () async {
    SharedPreferences.setMockInitialValues({'workout_experience_mode': 'logger'});
    SharedPrefs.instance.resetForTests();

    final container = ProviderContainer();
    container.read(workoutExperienceSettingsProvider);
    await waitForLoad(container);

    expect(
      container.read(workoutExperienceSettingsProvider).mode,
      WorkoutExperienceMode.logger,
    );
    container.dispose();
  });

  test('setMode updates state and prefs', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();

    final container = ProviderContainer();
    container.read(workoutExperienceSettingsProvider);
    await waitForLoad(container);

    await container
        .read(workoutExperienceSettingsProvider.notifier)
        .setMode(WorkoutExperienceMode.logger);

    expect(
      container.read(workoutExperienceSettingsProvider).mode,
      WorkoutExperienceMode.logger,
    );
    final prefs = SharedPrefs.instance;
    expect(await prefs.getString('workout_experience_mode'), 'logger');
    container.dispose();
  });
}
