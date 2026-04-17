const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Runs every 15 minutes. For each user in Firestore with fcmToken and
 * timezoneOffsetMinutes, computes current local time and checks
 * users/{uid}/dailySchedule/{yyyy-MM-dd} for any minute-of-day in the
 * last 15 minutes. If there are workout names in that window, sends one FCM.
 * (Reminders can be set to any minute; we send on the next run after that time.)
 */
exports.sendWorkoutReminders = functions.pubsub
  .schedule("every 15 minutes")
  .timeZone("UTC")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    const usersSnap = await db.collection("users").get();
    let usersTotal = usersSnap.size;
    let usersWithToken = 0;
    let scheduleDocsFound = 0;
    let sendsAttempted = 0;
    let sendsSucceeded = 0;
    let sendsFailed = 0;

    for (const doc of usersSnap.docs) {
      const uid = doc.id;
      const data = doc.data();
      const fcmToken = data.fcmToken;
      const offsetMinutes = data.timezoneOffsetMinutes ?? 0;

      if (!fcmToken) continue;
      usersWithToken++;

      // Local time: UTC + offsetMinutes (Flutter TimeZoneOffset: positive east of UTC)
      const localTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);
      const localMinutesOfDay = localTime.getUTCHours() * 60 + localTime.getUTCMinutes();
      const dateKey = `${localTime.getUTCFullYear()}-${String(localTime.getUTCMonth() + 1).padStart(2, "0")}-${String(localTime.getUTCDate()).padStart(2, "0")}`;

      const scheduleRef = db.collection("users").doc(uid).collection("dailySchedule").doc(dateKey);
      const scheduleSnap = await scheduleRef.get();
      if (!scheduleSnap.exists) continue;
      scheduleDocsFound++;

      const schedule = scheduleSnap.data();
      // Check any slot in the last 15 minutes so reminders at e.g. 8:07 fire on the 8:15 run
      const windowStart = Math.max(0, localMinutesOfDay - 14);
      const allNames = [];
      for (let m = windowStart; m <= localMinutesOfDay; m++) {
        const arr = schedule[String(m)];
        if (Array.isArray(arr)) allNames.push(...arr);
      }
      if (allNames.length === 0) continue;

      const body = allNames.length === 1
        ? `${allNames[0]} today`
        : `You have ${allNames.join(", ")} today`;

      try {
        sendsAttempted++;
        console.log(
          `[sendWorkoutReminders] uid=${uid} date=${dateKey} localMinute=${localMinutesOfDay} windowStart=${windowStart} workouts=${JSON.stringify(allNames)}`
        );
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Workout reminder",
            body,
          },
          android: {
            priority: "high",
            notification: { channelId: "workout_reminders" },
          },
          apns: {
            payload: { aps: { sound: "default" } },
            fcmOptions: {},
          },
        });
        sendsSucceeded++;
      } catch (e) {
        sendsFailed++;
        console.warn(`[sendWorkoutReminders] FCM send failed for user ${uid}`, {
          name: e?.name,
          message: e?.message,
          code: e?.code,
          stack: e?.stack,
          errorInfo: e?.errorInfo,
          status: e?.status,
        });
      }
    }

    console.log(
      `[sendWorkoutReminders] summary usersTotal=${usersTotal} usersWithToken=${usersWithToken} scheduleDocsFound=${scheduleDocsFound} sendsAttempted=${sendsAttempted} sendsSucceeded=${sendsSucceeded} sendsFailed=${sendsFailed}`
    );
  });
