import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class ThemeSettingsState {
  final ThemeMode mode;
  final bool isLoading;

  const ThemeSettingsState({
    required this.mode,
    this.isLoading = false,
  });

  ThemeSettingsState copyWith({
    ThemeMode? mode,
    bool? isLoading,
  }) {
    return ThemeSettingsState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsState> {
  static const _prefsKeyThemeMode = 'themeMode';

  ThemeSettingsNotifier()
      : super(const ThemeSettingsState(
          mode: ThemeMode.system,
          isLoading: true,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final stored = await prefs.getString(_prefsKeyThemeMode);
    final mode = _parseThemeMode(stored);
    state = state.copyWith(mode: mode, isLoading: false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.mode && !state.isLoading) return;
    state = state.copyWith(mode: mode, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyThemeMode, _serializeThemeMode(mode));
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return ThemeMode.system;
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>((ref) {
  return ThemeSettingsNotifier();
});

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System';
  }
}
