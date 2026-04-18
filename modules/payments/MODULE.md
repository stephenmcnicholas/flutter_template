# Module: In-App Purchases / Payments

**What it does:** Premium/subscription state stub. Provides a `premiumServiceProvider` and `premiumStatusProvider` Riverpod providers backed by a `StubPremiumService` that returns a hardcoded placeholder. Replace with a real `in_app_purchase` implementation when building a paid app.

**Files:**
- `lib/src/providers/premium_provider.dart` — stub premium provider

**Dependencies:** None (standalone)

**To implement payments:**
1. Add `in_app_purchase` to `pubspec.yaml`
2. Replace the stub in `premium_provider.dart` with real purchase logic
3. Configure App Store / Play Store product IDs

**To remove this module:**
1. Delete `lib/src/providers/premium_provider.dart`
2. Remove any paywall screens or premium-gating logic from the app
