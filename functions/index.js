// functions/index.js
import { onSchedule } from "firebase-functions/v2/scheduler";
import admin from "firebase-admin";

admin.initializeApp();

const REGION = "europe-west1";
const TIMEZONE = "Europe/Paris";

// --- 24h avant RDV -----------------------------
export const notifyUsersForAppointments = onSchedule(
  { schedule: "every 1 minutes", timeZone: TIMEZONE, region: REGION, concurrency: 1 },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const snapshot = await db.collection("rendezvous")
      .where("datetime", ">=", now)
      .where("datetime", "<=", in24h)
      .where("notificationSent24h", "==", false)
      .get();

    if (snapshot.empty) {
      console.log("✅ Aucun rendez-vous à notifier.");
      return;
    }

    for (const doc of snapshot.docs) {
      const rdv = doc.data();
      const tokens = Array.isArray(rdv.tokens) ? rdv.tokens.filter(Boolean) : [];
      if (!tokens.length) {
        console.warn(`⚠️ Aucun token FCM pour le rendez-vous ${doc.id}`);
        continue;
      }

      const dateFormatted = rdv.datetime.toDate().toLocaleString("fr-FR", {
        timeZone: TIMEZONE,
        day: "2-digit",
        month: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
      });

      const ttlMs = 3 * 24 * 60 * 60 * 1000;
      const payload = {
        notification: {
          title: "⏰ Rappel de rendez-vous",
          body: `${rdv.participant} n'oubliez pas votre rendez-vous ${rdv.description} le ${dateFormatted} avec le Dr ${rdv.medecin}.`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "rdv",
          screen: "/screens/agenda",
          rdvId: String(doc.id),
        },
        android: { priority: "high", ttl: ttlMs, collapseKey: `rdv-${doc.id}` },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-expiration": String(Math.floor((Date.now() + ttlMs) / 1000)),
            "apns-push-type": "alert",
          },
        },
      };

      const res = await admin.messaging().sendEachForMulticast({ ...payload, tokens });
      res.responses.forEach((r, i) =>
        r.success
          ? console.log(`✅ Notification envoyée à ${tokens[i]}`)
          : console.error(`❌ Erreur vers ${tokens[i]}:`, r.error)
      );

      await admin.firestore().collection("rendezvous").doc(doc.id).update({
        notificationSent24h: true,
        notificationSent24hAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// --- 2h avant RDV + TTL/collapse -----------
export const notifyUsers2hBeforeAppointment = onSchedule(
  { schedule: "every 1 minutes", timeZone: TIMEZONE, region: REGION, concurrency: 1 },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const in2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const in2hWindow = new Date(now.getTime() + 2 * 60 * 60 * 1000 + 60 * 1000);
    const in2hWindowMin = new Date(in2h.getTime() - 60 * 1000);

    const snapshot = await db.collection("rendezvous")
      .where("datetime", ">=", in2hWindowMin)
      .where("datetime", "<=", in2hWindow)
      .where("notificationSent2h", "==", false)
      .get();

    if (snapshot.empty) {
      console.log("✅ Aucun rendez-vous à rappeler 2h avant.");
      return;
    }

    for (const doc of snapshot.docs) {
      const rdv = doc.data();
      const tokens = Array.isArray(rdv.tokens) ? rdv.tokens.filter(Boolean) : [];
      if (!tokens.length) {
        console.warn(`⚠️ Aucun token FCM pour le rendez-vous ${doc.id}`);
        continue;
      }

      const hourFormatted = rdv.datetime.toDate().toLocaleTimeString("fr-FR", {
        timeZone: TIMEZONE,
        hour: "2-digit",
        minute: "2-digit",
      });

      const ttlMs = 3 * 24 * 60 * 60 * 1000;
      const payload = {
        notification: { title: "📌 Rendez-vous bientôt", body: `${rdv.participant}, tout est prêt pour votre rendez-vous à ${hourFormatted} avec le Dr ${rdv.medecin}.` },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "rdv_2h",
          screen: "/screens/agenda",
          rdvId: String(doc.id),
        },
        android: { priority: "high", ttl: ttlMs, collapseKey: `rdv2h-${doc.id}` },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-expiration": String(Math.floor((Date.now() + ttlMs) / 1000)),
            "apns-push-type": "alert",
          },
        },
      };

      const res = await admin.messaging().sendEachForMulticast({ ...payload, tokens });
      res.responses.forEach((r, i) =>
        r.success
          ? console.log(`✅ Notification 2h avant envoyée à ${tokens[i]}`)
          : console.error(`❌ Erreur vers ${tokens[i]}:`, r.error)
      );

      await db.collection("rendezvous").doc(doc.id).update({
        notificationSent2h: true,
        notificationSent2hAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// --- TÂCHES : 2h avant via notificationAt ---------------------------------
export const notifyUsersForTasks = onSchedule(
  { schedule: "every 1 minutes", timeZone: "Europe/Paris", region: "europe-west1", concurrency: 1 },
  async () => {
    const db = admin.firestore();

    const ADVANCE_HOURS = 3; 
    const MARGIN_MS = 60_000; // ±1 minute
    const TTL_MS = 3 * 24 * 60 * 60 * 1000; // conserve le message 3 jours

    const nowMs = Date.now();
    const advanceMs = ADVANCE_HOURS * 60 * 60 * 1000;

    const windowMin = admin.firestore.Timestamp.fromMillis(nowMs + advanceMs - MARGIN_MS);
    const windowMax = admin.firestore.Timestamp.fromMillis(nowMs + advanceMs + MARGIN_MS);

    const snapshot = await db.collection("tasks")
      .where("reminder", "==", true)
      .where("reminderSent", "==", false) 
      .where("reminderDateTime", ">=", windowMin)
      .where("reminderDateTime", "<=", windowMax)
      .get();

    if (snapshot.empty) {
      console.log("✅ Aucune tâche à rappeler maintenant.");
      return;
    }

    for (const doc of snapshot.docs) {
      const task = doc.data();
      const taskId = doc.id;

      const tokens = Array.isArray(task.tokens) ? task.tokens.filter(Boolean) : [];
      if (tokens.length === 0) {
        console.warn(`⚠️ Aucun token FCM pour la tâche ${taskId}`);
        continue;
      }

      const reminderDate = task.reminderDateTime?.toDate?.();
      const dateFormatted = reminderDate
        ? reminderDate.toLocaleString("fr-FR", {
            timeZone: "Europe/Paris",
            day: "2-digit",
            month: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
          })
        : "bientôt";

      const payload = {
        notification: {
          title: "📋 Rappel de tâche",
          body: `N'oubliez pas votre tâche : "${task.title ?? "Sans titre"}" prévue le ${dateFormatted}.`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "task",
          screen: "tasks",
          docId: String(taskId),
        },
        android: { priority: "high", ttl: TTL_MS, collapseKey: `task-${taskId}` },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-expiration": String(Math.floor((Date.now() + TTL_MS) / 1000)),
            "apns-push-type": "alert",
          },
        },
      };

      const res = await admin.messaging().sendEachForMulticast({ ...payload, tokens });
      res.responses.forEach((r, i) =>
        r.success
          ? console.log(`✅ Notification de tâche envoyée à ${tokens[i]}`)
          : console.error(`❌ Erreur en envoyant à ${tokens[i]}:`, r.error)
      );

      // Marque la tâche comme notifiée (idempotent si la fonction se chevauche)
      await db.runTransaction(async (tx) => {
        const ref = db.collection("tasks").doc(taskId);
        const snap = await tx.get(ref);
        if (!snap.exists) return;
        if (snap.get("reminderSent") === true) return;
        tx.update(ref, {
          reminderSent: true,
          reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    }
  }
);
