import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class LoginPromptState {
  final bool isLoading;
  final bool dismissed;

  const LoginPromptState({
    required this.isLoading,
    required this.dismissed,
  });

  LoginPromptState copyWith({
    bool? isLoading,
    bool? dismissed,
  }) {
    return LoginPromptState(
      isLoading: isLoading ?? this.isLoading,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

class LoginPromptNotifier extends StateNotifier<LoginPromptState> {
  static const _prefsKey = 'loginPromptDismissed';

  LoginPromptNotifier()
      : super(const LoginPromptState(
          isLoading: true,
          dismissed: false,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final dismissed = await prefs.getBool(_prefsKey) ?? false;
    state = state.copyWith(isLoading: false, dismissed: dismissed);
  }

  Future<void> dismiss() async {
    if (state.dismissed) return;
    state = state.copyWith(dismissed: true);
    await SharedPrefs.instance.setBool(_prefsKey, true);
  }
}

final loginPromptProvider =
    StateNotifierProvider<LoginPromptNotifier, LoginPromptState>((ref) {
  return LoginPromptNotifier();
});
