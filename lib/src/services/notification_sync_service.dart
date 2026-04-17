import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/utils/program_utils.dart';

/// Builds the next [days] days of workout reminders from [programs].
/// Returns map: dateKey -> (minuteKey -> list of workout names).
/// Only programs with [Program.notificationEnabled] are included.
/// [reminderTimeMinutes] is a global user-level reminder time.
/// Used by [syncDailyScheduleToFirestore] and by unit tests.
Map<String, Map<String, List<String>>> buildDailyScheduleMap({
  required DateTime today,
  required List<Program> programs,
  required Map<String, String> workoutIdToName,
  required int reminderTimeMinutes,
  int days = 14,
}) {
  final Map<String, Map<String, List<String>>> dailySchedule = {};

  for (var d = 0; d < days; d++) {
    final date = today.add(Duration(days: d));
    final dateKey = _dateKey(date);
    dailySchedule[dateKey] = {};
  }

  final minuteKey = reminderTimeMinutes.toString();
  for (final program in programs) {
    if (!program.notificationEnabled) continue;

    for (final pw in program.schedule) {
      final workoutDate = normalizeProgramDate(pw.scheduledDate);
      final dateKey = _dateKey(workoutDate);
      final map = dailySchedule[dateKey];
      if (map == null) continue; // past or beyond window
      final name = workoutIdToName[pw.workoutId] ?? pw.workoutId;
      map.putIfAbsent(minuteKey, () => []).add(name);
    }
  }

  return dailySchedule;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Builds the next [days] days of workout reminders from [programs] and writes
/// to Firestore for the given [uid], with [fcmToken] and [timezoneOffsetMinutes].
/// [workoutIdToName] maps workout ID to display name.
/// Only programs with [Program.notificationEnabled] are included.
/// [reminderTimeMinutes] is a global user-level reminder time.
Future<void> syncDailyScheduleToFirestore({
  required String uid,
  required String? fcmToken,
  required int timezoneOffsetMinutes,
  required List<Program> programs,
  required Map<String, String> workoutIdToName,
  required int reminderTimeMinutes,
  int days = 14,
}) async {
  final firestore = FirebaseFirestore.instance;
  final userRef = firestore.collection('users').doc(uid);

  final localNow = DateTime.now();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final dailySchedule = buildDailyScheduleMap(
    today: today,
    programs: programs,
    workoutIdToName: workoutIdToName,
    reminderTimeMinutes: reminderTimeMinutes,
    days: days,
  );

  final batch = firestore.batch();

  // User doc: token and timezone
  batch.set(userRef, {
    'fcmToken': fcmToken,
    'timezoneOffsetMinutes': timezoneOffsetMinutes,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final scheduleRef = userRef.collection('dailySchedule');

  for (final entry in dailySchedule.entries) {
    final dateKey = entry.key;
    final slots = entry.value;
    final docData = <String, dynamic>{};
    for (final slotEntry in slots.entries) {
      docData[slotEntry.key] = slotEntry.value;
    }
    batch.set(scheduleRef.doc(dateKey), docData);
  }

  await batch.commit();
}

/// Updates only the FCM token and timezone for the user in Firestore.
/// Use when the token is refreshed (e.g. onTokenRefresh) to avoid recomputing schedule.
Future<void> updateFCMTokenInFirestore({
  required String uid,
  required String? fcmToken,
  required int timezoneOffsetMinutes,
}) async {
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('users').doc(uid).set({
    'fcmToken': fcmToken,
    'timezoneOffsetMinutes': timezoneOffsetMinutes,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
