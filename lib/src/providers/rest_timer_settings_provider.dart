import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class RestTimerSettingsState {
  final int defaultSeconds;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool isLoading;

  const RestTimerSettingsState({
    required this.defaultSeconds,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.isLoading = false,
  });

  RestTimerSettingsState copyWith({
    int? defaultSeconds,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? isLoading,
  }) {
    return RestTimerSettingsState(
      defaultSeconds: defaultSeconds ?? this.defaultSeconds,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RestTimerSettingsNotifier extends StateNotifier<RestTimerSettingsState> {
  static const _prefsKeyDefaultSeconds = 'restTimerDefaultSeconds';
  static const _prefsKeyHapticsEnabled = 'restTimerHapticsEnabled';
  static const _prefsKeySoundEnabled = 'restTimerSoundEnabled';
  static const int _defaultSeconds = 120;
  static const int _minSeconds = 5;
  static const int _maxSeconds = 3600;

  RestTimerSettingsNotifier()
      : super(const RestTimerSettingsState(
          defaultSeconds: _defaultSeconds,
          isLoading: true,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final secondsValue = await prefs.getInt(_prefsKeyDefaultSeconds);
    final seconds = (secondsValue ?? _defaultSeconds).clamp(_minSeconds, _maxSeconds);
    final hapticsEnabled = await prefs.getBool(_prefsKeyHapticsEnabled) ?? true;
    final soundEnabled = await prefs.getBool(_prefsKeySoundEnabled) ?? true;
    state = state.copyWith(
      defaultSeconds: seconds,
      hapticsEnabled: hapticsEnabled,
      soundEnabled: soundEnabled,
      isLoading: false,
    );
  }

  Future<void> setDefaultSeconds(int seconds) async {
    final clamped = seconds.clamp(_minSeconds, _maxSeconds);
    if (clamped == state.defaultSeconds && !state.isLoading) return;
    state = state.copyWith(defaultSeconds: clamped, isLoading: false);
    await SharedPrefs.instance.setInt(_prefsKeyDefaultSeconds, clamped);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (enabled == state.hapticsEnabled && !state.isLoading) return;
    state = state.copyWith(hapticsEnabled: enabled, isLoading: false);
    await SharedPrefs.instance.setBool(_prefsKeyHapticsEnabled, enabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (enabled == state.soundEnabled && !state.isLoading) return;
    state = state.copyWith(soundEnabled: enabled, isLoading: false);
    await SharedPrefs.instance.setBool(_prefsKeySoundEnabled, enabled);
  }
}

final restTimerSettingsProvider =
    StateNotifierProvider<RestTimerSettingsNotifier, RestTimerSettingsState>((ref) {
  return RestTimerSettingsNotifier();
});
