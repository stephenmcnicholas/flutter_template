import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/premium_service.dart';

/// Provides the app's premium entitlement service. Replace [StubPremiumService]
/// with store-backed billing before v1.0 launch (`docs/ROADMAP.md` Phase 5 §5.0).
/// [aiProgrammePremiumProvider] and audio/logger features read entitlement via this layer.
final premiumServiceProvider = Provider<PremiumService>((ref) {
  return StubPremiumService();
});

/// Cached premium status for UI (e.g. show speaker icon when true).
/// Use when you need a sync-ish bool; for one-off checks use [PremiumService.isPremium].
final premiumStatusProvider = FutureProvider<bool>((ref) {
  return ref.watch(premiumServiceProvider).isPremium();
});
