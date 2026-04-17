import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

/// Guided = auto-play at key moments. On-demand = user taps speaker only.
enum AudioCoachingMode { guided, onDemand }

class AudioCoachingSettingsState {
  final AudioCoachingMode mode;
  final bool isLoading;

  const AudioCoachingSettingsState({
    this.mode = AudioCoachingMode.guided,
    this.isLoading = false,
  });

  bool get isGuided => mode == AudioCoachingMode.guided;
}

class AudioCoachingSettingsNotifier extends StateNotifier<AudioCoachingSettingsState> {
  static const _prefsKeyMode = 'audio_coaching_mode';

  AudioCoachingSettingsNotifier()
      : super(const AudioCoachingSettingsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final value = await prefs.getString(_prefsKeyMode);
    final mode = value == 'on_demand'
        ? AudioCoachingMode.onDemand
        : AudioCoachingMode.guided;
    state = AudioCoachingSettingsState(mode: mode, isLoading: false);
  }

  Future<void> setMode(AudioCoachingMode mode) async {
    if (mode == state.mode && !state.isLoading) return;
    state = AudioCoachingSettingsState(mode: mode, isLoading: false);
    await SharedPrefs.instance.setString(
      _prefsKeyMode,
      mode == AudioCoachingMode.onDemand ? 'on_demand' : 'guided',
    );
  }
}

final audioCoachingSettingsProvider =
    StateNotifierProvider<AudioCoachingSettingsNotifier, AudioCoachingSettingsState>((ref) {
  return AudioCoachingSettingsNotifier();
});
