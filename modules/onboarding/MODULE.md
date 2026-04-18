# Module: Onboarding

**What it does:** A reusable multi-step onboarding flow pattern. Screens guide new users through app setup before reaching the home screen. Typically includes: welcome, key value proposition, permission requests (notifications), and account creation prompt.

**Files:**
- `lib/src/presentation/features/onboarding/` — onboarding screens
- Wired via `app_router.dart` — redirects unauthenticated/new users here

**Dependencies:** Auth module (for sign-up step), Notifications module (for permission request step)

**To remove this module:**
1. Delete `lib/src/presentation/features/onboarding/`
2. Remove the `/onboarding` route from `app_router.dart`
3. Remove the onboarding redirect logic from the router's `redirect` callback

**To customise:**
Add, remove, or reorder onboarding steps by editing the step list in the onboarding coordinator. Each step is a separate screen widget — add new ones as needed.
