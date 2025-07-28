// functions/index.js
import { onSchedule } from "firebase-functions/v2/scheduler";
import admin from "firebase-admin";

admin.initializeApp();

// Fonction pour notifier les utilisateurs 24h avant un rendez-vous
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
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });


    const notification = {
      notification: {
        title: "⏰ Rappel de rendez-vous",
        body: `${rdv.participant} n'oubliez pas votre rendez-vous ${rdv.description} demain à ${dateFormatted} avec le Dr ${rdv.medecin}.`,
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

// Fonction pour notifier les utilisateurs 2h avant un rendez-vous
export const notifyUsers2hBeforeAppointment = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();

  const now = new Date();
  const in2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
  const in3h = new Date(now.getTime() + 3 * 60 * 60 * 1000);

  const snapshot = await db.collection("rendezvous")
    .where("datetime", ">=", in2h)
    .where("datetime", "<=", in3h)
    .where("notificationSent2h", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("✅ Aucun rendez-vous à rappeler 2h avant.");
    return;
  }

  for (const doc of snapshot.docs) {
    const rdv = doc.data();
    const tokens = rdv.tokens || [];

    if (!tokens.length) {
      console.warn(`⚠️ Aucun token FCM pour le rendez-vous ${doc.id}`);
      continue;
    }

    const hourFormatted = rdv.datetime.toDate().toLocaleTimeString("fr-FR", {
      timeZone: "Europe/Paris",
      hour: "2-digit",
      minute: "2-digit",
    });

    const body = `${rdv.participant}, tout est prêt pour votre rendez-vous à ${hourFormatted} avec le Dr ${rdv.medecin}.`;

    const notification = {
      notification: {
        title: "📌 Rendez-vous bientôt",
        body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "rdv_2h",
        screen: "/screens/agenda",
      },
    };

    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification 2h avant envoyée à ${token}`);
      } catch (err) {
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    // Marquer comme notifié pour 2h avant
    await db.collection("rendezvous").doc(doc.id).update({
      notificationSent2h: true,
    });
  }
});

export const notifyUsersForTasks = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();

  const now = new Date();
  const margin = 1 * 60 * 1000;
  const nowMinusMargin = new Date(now.getTime() - margin);
  const nowPlusMargin = new Date(now.getTime() + margin);

  // On récupère les tâches où :
  // reminder = true
  const snapshot = await db.collection("tasks")
    .where("reminder", "==", true)
    .where("reminderSent", "==", false)
    .where("reminderDateTime", ">=", nowMinusMargin)
    .where("reminderDateTime", "<=", nowPlusMargin)
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

    // Formatage de la date avec timezone Europe/Paris
    const dateFormatted = task.reminderDateTime.toDate().toLocaleString("fr-FR", {
      timeZone: "Europe/Paris",
      hour: "2-digit",
      minute: "2-digit",
    }) ?? "bientôt";

    const notification = {
      notification: {
        title: "📋 Rappel de tâche",
        body: `N'oubliez pas votre tâche : "${task.title}" prévue ajourd'hui à ${dateFormatted}.`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "task",
        screen: "tasks",
        docId: taskId,
      },
    };

    // Envoi des notifications
    for (const token of tokens) {
      try {
        await admin.messaging().send({ ...notification, token });
        console.log(`✅ Notification de tâche envoyée à ${token}`);
      } catch (err) {
        console.error(`❌ Erreur en envoyant à ${token}:`, err);
      }
    }

    // On marque la tâche comme notifiée pour ne pas renvoyer la notif
    await db.collection("tasks").doc(taskId).update({
      reminderSent: true,
    });
  }
});
