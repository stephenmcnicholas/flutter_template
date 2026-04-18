# Module: In-App Purchases / Payments

**What it does:** In-app purchase scaffold for subscription and one-time purchase products via the `in_app_purchase` Flutter package. Handles purchase flow, receipt validation, and subscription state.

**Files:**
- `lib/src/providers/premium_provider.dart` (or equivalent)
- `pubspec.yaml` dependencies: `in_app_purchase`

**Dependencies:** None (standalone, though typically paired with auth to tie purchases to user accounts)

**To remove this module:**
1. Delete the premium/payments provider file
2. Remove `in_app_purchase` from `pubspec.yaml`
3. Remove any paywall screens or premium-gating logic from the app

**Note:** App Store and Play Store product IDs are app-specific and must be configured per project. The scaffold provides the pattern; the product IDs and entitlement logic are your responsibility.
