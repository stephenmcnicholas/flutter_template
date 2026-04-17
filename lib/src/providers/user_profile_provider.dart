import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/user_profile_repository.dart';
import 'package:fytter/src/domain/user_profile.dart';
import 'package:fytter/src/providers/data_providers.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserProfileRepository(db);
});

/// Current user profile (null if never saved).
final userProfileProvider =
    FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getProfile();
});

/// True if onboarding has been completed (profile exists and has completed timestamp).
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.hasCompletedOnboarding ?? false;
});
