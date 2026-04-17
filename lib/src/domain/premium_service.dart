/// Single source of truth for premium/entitlement checks across the app.
///
/// Use this for: audio coaching, AI programme generation, and any future
/// premium features. When monetisation is implemented (Phase 5 per roadmap), replace the
/// stub with a real implementation that checks subscription status (e.g. via
/// in-app purchase or backend). Feature code should depend only on this
/// interface so the swap requires no changes to UI or audio logic.
abstract class PremiumService {
  /// Returns true if the user has access to premium features.
  ///
  /// TODO(Phase 5): Replace stub with real subscription check — e.g. query
  /// RevenueCat / in-app purchase / backend entitlement. Cache result and
  /// refresh on app resume or purchase event to avoid blocking UI.
  Future<bool> isPremium();
}

/// Stub implementation: always returns true. Replace with a real implementation
/// (e.g. in data layer) when monetisation is implemented in Phase 5.
class StubPremiumService implements PremiumService {
  @override
  Future<bool> isPremium() async => true;
}
