import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/user_profile.dart';

/// Current user profile.
///
/// This is a placeholder provider. In a concrete app, wire this up to a
/// UserProfileRepository backed by Drift, Firestore, or another store.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // TODO: replace with real repository lookup
  return null;
});

/// True if onboarding has been completed (profile exists).
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile != null;
});
