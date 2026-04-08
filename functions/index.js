const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// ======================================================
// Helper: get enabled tokens for a specific alert field
// ======================================================
async function getEnabledTokens(alertFieldName) {
  const snap = await admin
    .firestore()
    .collection("user_notification_settings")
    .where(alertFieldName, "==", true)
    .get();

  if (snap.empty) return [];

  const tokens = snap.docs
    .map((doc) => doc.data().token)
    .filter((token) => typeof token === "string" && token.trim().length > 0);

  return [...new Set(tokens)];
}

// ======================================================
// Helper: remove invalid tokens from Firestore
// ======================================================
async function removeInvalidTokens(invalidTokens) {
  if (!invalidTokens.length) return;

  const settingsSnap = await admin
    .firestore()
    .collection("user_notification_settings")
    .get();

  const batch = admin.firestore().batch();

  settingsSnap.docs.forEach((doc) => {
    const token = doc.data().token;
    if (invalidTokens.includes(token)) {
      batch.update(doc.ref, {
        token: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  await batch.commit();
  console.log("Invalid tokens removed from user_notification_settings.");
}

// ======================================================
// Helper: send push notification
// ======================================================
async function sendToTokens({ tokens, title, body, data = {} }) {
  if (!tokens || !tokens.length) {
    console.log("No valid tokens to send.");
    return;
  }

  const message = {
    tokens,
    notification: {
      title,
      body,
    },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "unibus_channel",
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          contentAvailable: true,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  console.log("Notification sent.");
  console.log("Success count:", response.successCount);
  console.log("Failure count:", response.failureCount);

  const invalidTokens = [];

  response.responses.forEach((resp, index) => {
    if (!resp.success && resp.error) {
      const code = resp.error.code || "";

      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  await removeInvalidTokens(invalidTokens);
}

// ======================================================
// Test notification function
// افتحي رابط هذه الفنكشن بالمتصفح لتجربة الإشعار
// ======================================================
exports.sendTestNotification = onRequest(async (req, res) => {
  try {
    const tokens = await getEnabledTokens("newBusTrackingAlert");

    await sendToTokens({
      tokens,
      title: "UniBus Test",
      body: "Test push notification is working.",
      data: {
        type: "test",
      },
    });

    res.status(200).send("Test notification sent successfully.");
  } catch (error) {
    console.error("sendTestNotification error:", error);
    res.status(500).send("Failed to send test notification.");
  }
});

// ======================================================
// Main unified function for all notification events
// ======================================================
exports.sendNotificationFromEvent = onDocumentCreated(
  {
    document: "notification_events/{eventId}",
    region: "us-central1",
  },
  async (event) => {
    try {
      const snapshot = event.data;

      if (!snapshot) {
        console.log("No event snapshot found.");
        return;
      }

      const eventData = snapshot.data();

      if (!eventData) {
        console.log("Event data is empty.");
        return;
      }

      const type = eventData.type || "";
      const busName = eventData.busName || "Bus";
      const routeName = eventData.routeName || "Route";
      const stopName = eventData.stopName || "Stop";
      const etaMinutes = eventData.etaMinutes || "1";
      const sessionId = eventData.sessionId || "";

      let alertFieldName = "";
      let title = "";
      let body = "";
      let data = {};

      if (type === "new_bus_tracking") {
        alertFieldName = "newBusTrackingAlert";
        title = "New Bus Started Tracking";
        body = `${busName} has started tracking on ${routeName}`;
        data = {
          type,
          busName,
          routeName,
          sessionId,
        };
      } else if (type === "next_stop_arrival") {
        alertFieldName = "nextStopArrivalAlert";
        title = "Next Stop Reached";
        body = `${busName} has arrived at ${stopName}`;
        data = {
          type,
          busName,
          routeName,
          stopName,
          sessionId,
        };
      } else if (type === "bus_approaching") {
        alertFieldName = "busApproachingAlert";
        title = "Bus Approaching";
        body = `${busName} will arrive at ${stopName} in about ${etaMinutes} minute`;
        data = {
          type,
          busName,
          routeName,
          stopName,
          etaMinutes,
          sessionId,
        };
      } else {
        console.log("Unknown event type:", type);
        return;
      }

      const tokens = await getEnabledTokens(alertFieldName);

      if (!tokens.length) {
        console.log(`No users enabled ${alertFieldName}`);
        return;
      }

      await sendToTokens({
        tokens,
        title,
        body,
        data,
      });

      console.log(`Notification sent successfully for type: ${type}`);
      return;
    } catch (error) {
      console.error("sendNotificationFromEvent error:", error);
      return;
    }
  }
);