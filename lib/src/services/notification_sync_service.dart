import 'package:cloud_firestore/cloud_firestore.dart';

/// Builds a daily schedule map from arbitrary program data.
///
/// [programs] is an iterable of objects exposing notification/schedule info.
/// This is a template placeholder — concrete apps should provide typed data.
///
/// Returns map: dateKey -> (minuteKey -> list of item names).
Map<String, Map<String, List<String>>> buildDailyScheduleMap({
  required DateTime today,
  int days = 14,
}) {
  final Map<String, Map<String, List<String>>> dailySchedule = {};

  for (var d = 0; d < days; d++) {
    final date = today.add(Duration(days: d));
    final dateKey = _dateKey(date);
    dailySchedule[dateKey] = {};
  }

  return dailySchedule;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Writes the daily schedule for [uid] to Firestore.
Future<void> syncDailyScheduleToFirestore({
  required String uid,
  required String? fcmToken,
  required int timezoneOffsetMinutes,
  int days = 14,
}) async {
  final firestore = FirebaseFirestore.instance;
  final userRef = firestore.collection('users').doc(uid);

  final localNow = DateTime.now();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final dailySchedule = buildDailyScheduleMap(
    today: today,
    days: days,
  );

  final batch = firestore.batch();

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
