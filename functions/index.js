// functions/index.js
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifyUsersForAppointments = onSchedule("every 1 minutes", async (event) => {
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
    const tokens = rdv.tokens || [];

    if (!tokens.length) {
      console.warn(`⚠️ Aucun token FCM pour le rendez-vous ${doc.id}`);
      continue;
    }

    const dateFormatted = rdv.datetime.toDate().toLocaleString("fr-FR", {
      timeZone: "Europe/Paris",
    });

    const notification = {
      notification: {
        title: "⏰ Rappel de rendez-vous",
        body: `${rdv.participant} n'oubliez pas votre rendez-vous ${rdv.description} demain le ${dateFormatted} avec le Dr ${rdv.medecin}.`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "rdv",
        screen: "/screens/agenda",
      },
    };

    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification envoyée à ${token}`);
      } catch (err) {
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    // ✅ Marquer comme notifié
    await db.collection("rendezvous").doc(doc.id).update({
      notificationSent24h: true,
    });
  }
});

export const notifyUsersForTasks = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();

  const now = new Date();
  const margin = 1 * 60 * 1000;
  const nowPlusMargin = new Date(now.getTime() + margin);

  const snapshot = await db.collection("tasks")
    .where("reminder", "==", true)
    .where("reminderDateTime", ">=", new Date(now.getTime() - margin))
    .where("reminderDateTime", "<=", nowPlusMargin)
    .where("reminderSent", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("✅ Aucune tâche à rappeler maintenant.");
    return;
  }

  for (const doc of snapshot.docs) {
    const task = doc.data();
    const taskId = doc.id;
    const tokens = task.tokens || [];

    if (!tokens.length) {
      console.warn(`⚠️ Aucun token FCM pour la tâche ${taskId}`);
      continue;
    }

    const dateFormatted = task.date?.toDate?.().toLocaleString("fr-FR", {
      timeZone: "Europe/Paris",
    }) ?? "bientôt";

    const notification = {
      notification: {
        title: "📋 Rappel de tâche",
        body: `N'oubliez pas votre tâche : ${task.title} prévue pour le ${dateFormatted}.`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "task",
        screen: "tasks",
        docId: taskId,
      },
    };

    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification de tâche envoyée à ${token}`);
      } catch (err) {
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    // ✅ Marquer la tâche comme notifiée
    await db.collection("tasks").doc(taskId).update({
      reminderSent: true,
    });
  }
});
