import { onSchedule } from "firebase-functions/v2/scheduler";
import admin from "firebase-admin";

admin.initializeApp();

export const notifyUsersForAppointments = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();

  const now = new Date();

  const targetStart = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const targetEnd = new Date(targetStart.getTime() + 60 * 1000);

  const snapshot = await db.collection("rendezvous")
    .where("datetime", ">=", targetStart)
    .where("datetime", "<=", targetEnd)
    .where("notificationSent24h", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("✅ Aucun rendez-vous à rappeler maintenant.");
    return;
  }

  for (const doc of snapshot.docs) {
    const rdv = doc.data();

    const tokens = rdv.tokens || [];
    if (!tokens.length) {
      console.warn(`⚠️ Aucun token FCM pour le rendez-vous ${doc.id}`);
      continue;
    }

    const notification = {
      notification: {
        title: "⏰ Rappel de rendez-vous",
        body: `${rdv.participant}, n'oubliez pas votre rendez-vous "${rdv.description}" demain à ${rdv.datetime.toDate().toLocaleTimeString("fr-FR", { hour: '2-digit', minute: '2-digit' })} avec le Dr ${rdv.medecin}.`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "rdv",
        screen: "/screens/agenda",
      },
    };

    let allSent = true;
    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification envoyée à ${token}`);
      } catch (err) {
        allSent = false;
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    if (allSent) {
      await doc.ref.update({ notificationSent24h: true });
    }
  }
});

export const notifyUsersForTasks = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();

  const now = new Date();

  const targetStart = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const targetEnd = new Date(targetStart.getTime() + 60 * 1000);

  const snapshot = await db.collection("tasks")
    .where("reminder", "==", true)
    .where("reminderDateTime", ">=", targetStart)
    .where("reminderDateTime", "<=", targetEnd)
    .where("notificationSent24h", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("✅ Aucune tâche à rappeler maintenant.");
    return;
  }

  for (const doc of snapshot.docs) {
    const task = doc.data();

    const tokens = task.tokens || [];
    if (!tokens.length) {
      console.warn(`⚠️ Aucun token FCM pour la tâche ${doc.id}`);
      continue;
    }

    const notification = {
      notification: {
        title: "⏰ Rappel de tâche",
          body: `N'oubliez pas votre tâche : "${task.title}" demain à ${task.reminderDateTime.toDate().toLocaleTimeString("fr-FR", { hour: '2-digit', minute: '2-digit' })}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "task",
        screen: "/screens/tasks",
      },
    };

    let allSent = true;
    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification envoyée à ${token}`);
      } catch (err) {
        allSent = false;
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    if (allSent) {
      await doc.ref.update({ notificationSent24h: true });
    }
  }
});