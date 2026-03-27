const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

async function getAllTokens() {
  const snap = await admin.firestore().collection("device_tokens").get();
  return snap.docs
    .map((doc) => doc.data().token)
    .filter((token) => typeof token === "string" && token.length > 0);
}

async function notificationsEnabled(fieldName) {
  const doc = await admin
    .firestore()
    .collection("app_settings")
    .doc("student_notifications")
    .get();

  const data = doc.data() || {};
  return data[fieldName] !== false;
}

async function sendToAllTokens({ title, body, data = {} }) {
  const tokens = await getAllTokens();
  if (!tokens.length) return;

  const message = {
    tokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "unibus_channel",
      },
    },
  };

  await admin.messaging().sendEachForMulticast(message);
}

// 1) إشعار تجريبي سريع
exports.sendTestNotification = onRequest(async (req, res) => {
  await sendToAllTokens({
    title: "UniBus Test",
    body: "Test notification is working.",
    data: { type: "test" },
  });

  res.status(200).send("Test notification sent.");
});

// 2) Schedule Change Alert
exports.sendScheduleChangeNotification = onDocumentUpdated(
  "routes/{routeId}",
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const enabled = await notificationsEnabled("scheduleChange");
    if (!enabled) return;

    const beforeVersion = before.scheduleVersion || 0;
    const afterVersion = after.scheduleVersion || 0;
    const beforeDelay = before.delayMinutes || 0;
    const afterDelay = after.delayMinutes || 0;

    if (beforeVersion === afterVersion && beforeDelay === afterDelay) return;

    await sendToAllTokens({
      title: "Schedule Change",
      body: "There is an update in the bus schedule or delay information.",
      data: {
        type: "schedule_change",
        routeId: event.params.routeId,
      },
    });
  }
);

// 3) Next Stop Arrival + Bus Approaching
exports.sendDrivingSessionNotifications = onDocumentUpdated(
  "driving_sessions/{sessionId}",
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    if ((after.status || "") !== "active") return;

    const beforeStop = before.currentStopOrder || 0;
    const afterStop = after.currentStopOrder || 0;

    // Next Stop Arrival
    if (afterStop > beforeStop) {
      const enabledArrival = await notificationsEnabled("nextStopArrival");
      if (enabledArrival) {
        await sendToAllTokens({
          title: "Next Stop Reached",
          body: `The bus has reached stop ${afterStop}.`,
          data: {
            type: "next_stop_arrival",
            sessionId: event.params.sessionId,
            stopOrder: afterStop,
          },
        });
      }

      const enabledApproaching = await notificationsEnabled("busApproaching");
      if (enabledApproaching) {
        await sendToAllTokens({
          title: "Bus Approaching",
          body: `The bus is now approaching stop ${afterStop + 1}.`,
          data: {
            type: "bus_approaching",
            sessionId: event.params.sessionId,
            nextStopOrder: afterStop + 1,
          },
        });
      }
    }
  }
);