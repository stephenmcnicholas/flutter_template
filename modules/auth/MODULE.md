# Module: Authentication

**What it does:** Firebase Auth with email/password and Google Sign-in. Handles signup, login, email verification, sign-out, and auth state propagation via Riverpod.

**Files:**
- `lib/src/domain/auth_repository.dart` — abstract interface
- `lib/src/data/firebase_auth_repository.dart` — native implementation
- `lib/src/data/web_auth_repository.dart` — web implementation
- `lib/src/data/auth_repository_factory.dart` — platform selector
- `lib/src/providers/auth_providers.dart` — Riverpod providers
- `lib/src/presentation/auth/` — login, signup, email verification screens
- `pubspec.yaml` dependencies: `firebase_auth`, `google_sign_in`

**Dependencies:** Firebase Core (always present)

**To remove this module:**
1. Delete `lib/src/domain/auth_repository.dart`
2. Delete `lib/src/data/firebase_auth_repository.dart`, `web_auth_repository.dart`, `auth_repository_factory.dart`
3. Delete `lib/src/providers/auth_providers.dart`
4. Delete `lib/src/presentation/auth/`
5. Remove auth redirect logic from `app_router.dart`
6. Remove from `pubspec.yaml`: `firebase_auth`, `google_sign_in`
7. Remove `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) if Firebase is also being removed
