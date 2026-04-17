/**
 * Fytter Cloud Functions: workout reminders (scheduled), AI programme generation,
 * pre-workout session adjustment (callable), Type C TTS (callable).
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { generateProgram } from "./generate-program";
import { adjustWorkout } from "./adjust-workout";
import { synthesizeTypeCTts } from "./synthesize-type-c-tts";

admin.initializeApp();

/**
 * Runs every 15 minutes. For each user in Firestore with fcmToken and
 * timezoneOffsetMinutes, computes current local time and checks
 * users/{uid}/dailySchedule/{yyyy-MM-dd} for any minute-of-day in the
 * last 15 minutes. If there are workout names in that window, sends one FCM.
 */
export const sendWorkoutReminders = functions.pubsub
  .schedule("every 15 minutes")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    const usersSnap = await db.collection("users").get();
    let usersWithToken = 0;
    let scheduleDocsFound = 0;
    let sendsAttempted = 0;
    let sendsSucceeded = 0;
    let sendsFailed = 0;

    for (const doc of usersSnap.docs) {
      const uid = doc.id;
      const data = doc.data();
      const fcmToken = data.fcmToken as string | undefined;
      const offsetMinutes = (data.timezoneOffsetMinutes as number | undefined) ?? 0;

      if (!fcmToken) {
        continue;
      }
      usersWithToken++;

      const localTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);
      const localMinutesOfDay =
        localTime.getUTCHours() * 60 + localTime.getUTCMinutes();
      const dateKey = `${localTime.getUTCFullYear()}-${String(localTime.getUTCMonth() + 1).padStart(2, "0")}-${String(localTime.getUTCDate()).padStart(2, "0")}`;

      const scheduleRef = db
        .collection("users")
        .doc(uid)
        .collection("dailySchedule")
        .doc(dateKey);
      const scheduleSnap = await scheduleRef.get();
      if (!scheduleSnap.exists) {
        continue;
      }
      scheduleDocsFound++;

      const schedule = scheduleSnap.data() ?? {};
      const windowStart = Math.max(0, localMinutesOfDay - 14);
      const allNames: string[] = [];
      for (let m = windowStart; m <= localMinutesOfDay; m++) {
        const arr = schedule[String(m)];
        if (Array.isArray(arr)) {
          allNames.push(...(arr as string[]));
        }
      }
      if (allNames.length === 0) {
        continue;
      }

      const body =
        allNames.length === 1
          ? `${allNames[0]} today`
          : `You have ${allNames.join(", ")} today`;

      try {
        sendsAttempted++;
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
        const err = e as { name?: string; message?: string; code?: string; stack?: string };
        functions.logger.warn(
          `[sendWorkoutReminders] FCM send failed for user ${uid}`,
          {
            name: err?.name,
            message: err?.message,
            code: err?.code,
          }
        );
      }
    }

    functions.logger.log(
      `[sendWorkoutReminders] usersWithToken=${usersWithToken} scheduleDocsFound=${scheduleDocsFound} sendsAttempted=${sendsAttempted} sendsSucceeded=${sendsSucceeded} sendsFailed=${sendsFailed}`
    );
  });

export { generateProgram, adjustWorkout, synthesizeTypeCTts };
