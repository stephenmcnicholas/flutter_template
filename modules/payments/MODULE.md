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

## In-app review prompt (pre-launch)

Every consumer app on the App Store and Play Store should prompt for a review after the user has experienced core value.

**Package:** `in_app_review` (add to `pubspec.yaml`)

**Pattern:**
```dart
import 'package:in_app_review/in_app_review.dart';

Future<void> maybeRequestReview() async {
  final inAppReview = InAppReview.instance;
  if (await inAppReview.isAvailable()) {
    await inAppReview.requestReview();
  }
}
```

**When to trigger:** After the user completes their Nth meaningful action (e.g., third use of the app's core feature). Never prompt more than once — both platforms enforce a once-per-365-days limit but your code should also track and respect it.

**Note:** The native review dialog cannot be tested in debug mode — use `openStoreListing()` in debug instead.
