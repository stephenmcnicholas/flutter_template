import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/services/notification_sync_service.dart';

/// Channel ID used by the Cloud Function for scheduled reminders. Must match.
const String workoutRemindersChannelId = 'workout_reminders';

FlutterLocalNotificationsPlugin? _localNotificationsPlugin;

/// Ensures the Android notification channel for workout reminders exists so FCM
/// messages display correctly. No-op on web. Call once at app startup.
Future<void> initNotificationChannels() async {
  if (kIsWeb) return;
  _localNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotificationsPlugin!.initialize(
    const InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    ),
  );
  final android = _localNotificationsPlugin!
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    await android.createNotificationChannel(const AndroidNotificationChannel(
      workoutRemindersChannelId,
      'Scheduled reminders',
      description: 'Scheduled alerts',
      importance: Importance.defaultImportance,
    ));
  }
}

/// Request notification permission (platform). Returns true if granted or already granted.
Future<bool> requestNotificationPermission() async {
  if (kIsWeb) return false;
  if (Firebase.apps.isEmpty) return false;
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  final status = settings.authorizationStatus;
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

/// Get current FCM token, or null if not available (e.g. permission denied, web,
/// or APNS token not yet received on iOS).
Future<String?> getFCMToken() async {
  if (kIsWeb) return null;
  if (Firebase.apps.isEmpty) return null;
  try {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    return token;
  } catch (_) {
    // On iOS, getToken() can throw before APNS token is ready (e.g. simulator
    // or cold start). Return null so callers can skip sync and retry later.
    return null;
  }
}

/// Trigger sync of daily schedule to Firestore for the current user.
/// No-op if user is not signed in or notifications are disabled.
///
/// In a concrete app, override this to supply program/schedule data to
/// [syncDailyScheduleToFirestore].
Future<void> syncNotificationSchedule(WidgetRef ref) async {
  if (kIsWeb) return;
  if (Firebase.apps.isEmpty) return;

  final user = ref.read(authUserProvider).valueOrNull;
  if (user == null) return;

  final notifSettings = ref.read(notificationSettingsProvider);
  if (!notifSettings.notificationsEnabled) return;

  final token = await getFCMToken();
  final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

  // Template: no schedule data. Concrete apps should supply program/schedule
  // data here and call syncDailyScheduleToFirestore.
  await updateFCMTokenInFirestore(
    uid: user.uid,
    fcmToken: token,
    timezoneOffsetMinutes: offsetMinutes,
  );
}

StreamSubscription<String>? _tokenRefreshSubscription;

/// Registers a listener for FCM token refresh and invokes [onTokenRefresh] when
/// the token changes. Use from a widget that has [WidgetRef] so the callback can
/// update Firestore with the new token. No-op on web or when Firebase is not
/// initialized (e.g. integration tests with skipFirebase: true).
void setupFCMTokenRefresh(Future<void> Function() onTokenRefresh) {
  if (kIsWeb) return;
  if (Firebase.apps.isEmpty) return;
  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription =
      FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
    await onTokenRefresh();
  });
}
