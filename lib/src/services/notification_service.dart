import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/services/notification_sync_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Channel ID used by the Cloud Function for workout reminders. Must match.
const String workoutRemindersChannelId = 'workout_reminders';

/// Channel for rest timer completion with custom assembled audio (audio coaching).
const String restCompleteChannelId = 'rest_complete';

/// Notification id for the single rest-end notification (reused each time).
const int restCompleteNotificationId = 9001;

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
      'Workout reminders',
      description: 'Daily reminder for scheduled program workouts',
      importance: Importance.defaultImportance,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      restCompleteChannelId,
      'Rest complete',
      description: 'Audio coaching when rest timer ends',
      importance: Importance.high,
      playSound: true,
    ));
  }
}

/// Schedules a local notification to fire at [scheduledAt] with optional [customSoundPath].
/// Used for rest timer completion (audio coaching). [customSoundPath] is a file path to the
/// assembled Template 5 audio; if null, platform default sound is used.
Future<void> scheduleRestEndNotification({
  required DateTime scheduledAt,
  String? customSoundPath,
}) async {
  if (kIsWeb) return;
  final plugin = _localNotificationsPlugin;
  if (plugin == null) return;
  final androidDetails = AndroidNotificationDetails(
    restCompleteChannelId,
    'Rest complete',
    channelDescription: 'Audio coaching when rest timer ends',
    playSound: true,
    sound: customSoundPath != null ? UriAndroidNotificationSound(customSoundPath) : null,
  );
  final darwinDetails = DarwinNotificationDetails(
    presentSound: true,
    sound: customSoundPath ?? 'default',
  );
  final details = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );
  await plugin.zonedSchedule(
    restCompleteNotificationId,
    'Rest over',
    'Ready for your next set.',
    tz.TZDateTime.from(scheduledAt.toUtc(), tz.UTC),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
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
Future<void> syncNotificationSchedule(WidgetRef ref) async {
  if (kIsWeb) return;
  if (Firebase.apps.isEmpty) return;

  final user = ref.read(authUserProvider).valueOrNull;
  if (user == null) return;

  final notifSettings = ref.read(notificationSettingsProvider);
  if (!notifSettings.notificationsEnabled) return;

  final token = await getFCMToken();
  final programRepo = ref.read(programRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);

  final programs = await programRepo.findAll();
  final workouts = await workoutRepo.findAll();
  final workoutIdToName = {for (final w in workouts) w.id: w.name};

  final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

  await syncDailyScheduleToFirestore(
    uid: user.uid,
    fcmToken: token,
    timezoneOffsetMinutes: offsetMinutes,
    programs: programs,
    workoutIdToName: workoutIdToName,
    reminderTimeMinutes: notifSettings.reminderTimeMinutes,
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
