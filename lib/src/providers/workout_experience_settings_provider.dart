import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

/// How the app starts a workout session (independent of audio coaching mode).
/// [guided] = pre-workout check-in → Let's go → logger sheet.
/// [logger] = open logger sheet immediately (no check-in / transition).
enum WorkoutExperienceMode { guided, logger }

class WorkoutExperienceSettingsState {
  final WorkoutExperienceMode mode;
  final bool isLoading;

  const WorkoutExperienceSettingsState({
    this.mode = WorkoutExperienceMode.guided,
    this.isLoading = false,
  });

  bool get isLoggerStart => mode == WorkoutExperienceMode.logger;
}

class WorkoutExperienceSettingsNotifier
    extends StateNotifier<WorkoutExperienceSettingsState> {
  static const _prefsKey = 'workout_experience_mode';

  WorkoutExperienceSettingsNotifier()
      : super(const WorkoutExperienceSettingsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final value = await prefs.getString(_prefsKey);
    final mode = value == 'logger'
        ? WorkoutExperienceMode.logger
        : WorkoutExperienceMode.guided;
    state = WorkoutExperienceSettingsState(mode: mode, isLoading: false);
  }

  Future<void> setMode(WorkoutExperienceMode mode) async {
    if (mode == state.mode && !state.isLoading) return;
    state = WorkoutExperienceSettingsState(mode: mode, isLoading: false);
    await SharedPrefs.instance.setString(
      _prefsKey,
      mode == WorkoutExperienceMode.logger ? 'logger' : 'guided',
    );
  }
}

final workoutExperienceSettingsProvider = StateNotifierProvider<
    WorkoutExperienceSettingsNotifier, WorkoutExperienceSettingsState>(
  (ref) => WorkoutExperienceSettingsNotifier(),
);
