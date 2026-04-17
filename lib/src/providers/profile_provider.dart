import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class ProfileState {
  final String displayName;
  final String email;
  final bool isLoading;

  const ProfileState({
    required this.displayName,
    required this.email,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? displayName,
    String? email,
    bool? isLoading,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  static const _prefsKeyDisplayName = 'profileDisplayName';
  static const _prefsKeyEmail = 'profileEmail';

  ProfileNotifier()
      : super(const ProfileState(
          displayName: '',
          email: '',
          isLoading: true,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    state = state.copyWith(
      displayName: await prefs.getString(_prefsKeyDisplayName) ?? '',
      email: await prefs.getString(_prefsKeyEmail) ?? '',
      isLoading: false,
    );
  }

  Future<void> setProfile({
    required String displayName,
    required String email,
  }) async {
    state = state.copyWith(displayName: displayName, email: email, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyDisplayName, displayName);
    await SharedPrefs.instance.setString(_prefsKeyEmail, email);
  }

  Future<void> setDisplayName(String displayName) async {
    if (displayName == state.displayName && !state.isLoading) return;
    state = state.copyWith(displayName: displayName, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyDisplayName, displayName);
  }

  Future<void> setEmail(String email) async {
    if (email == state.email && !state.isLoading) return;
    state = state.copyWith(email: email, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyEmail, email);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
