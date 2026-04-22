import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin structured event logger.
///
/// Debug builds: prints to console. Release non-web builds: sends to Firebase Analytics.
/// PII rule: NEVER pass user IDs, email, names, or any data that identifies an individual.
class AppLogger {
  AppLogger._();

  static void event(String name, [Map<String, Object?> data = const {}]) {
    if (kDebugMode) {
      final suffix = data.isEmpty
          ? ''
          : ' | ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
      debugPrint('[AppLog] $name$suffix');
    } else if (!kIsWeb) {
      FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: data.isEmpty ? null : data.cast<String, Object>(),
      ).catchError((_) {});
    }
  }
}

/// Canonical event name constants — keeps call sites typo-free.
/// Add app-specific events in the project that uses this template.
abstract class AppEvent {
  // App lifecycle
  static const String appLaunch = 'app_launch';

  // Auth
  static const String authSignedIn = 'auth_signed_in';
  static const String authSignedOut = 'auth_signed_out';

  // Onboarding
  static const String onboardingCompleted = 'onboarding_completed';

  // Subscription
  static const String subscriptionViewOpened = 'subscription_view_opened';
}
