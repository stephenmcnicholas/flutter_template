# Module: Notifications

**What it does:** Push notifications via Firebase Cloud Messaging (FCM) for remote notifications, and `flutter_local_notifications` for locally scheduled alerts. Handles FCM token registration, token refresh, notification channel setup (Android), and local notification scheduling.

**Files:**
- `lib/src/services/notification_service.dart`
- `lib/src/providers/notification_settings_provider.dart`
- `pubspec.yaml` dependencies: `firebase_messaging`, `flutter_local_notifications`, `timezone`

**Dependencies:** Firebase Core

**To remove this module:**
1. Delete `lib/src/services/notification_service.dart`
2. Delete `lib/src/providers/notification_settings_provider.dart`
3. Remove FCM token setup from `main.dart`
4. Remove from `pubspec.yaml`: `firebase_messaging`, `flutter_local_notifications`, `timezone`
5. Remove notification permission request from onboarding flow
