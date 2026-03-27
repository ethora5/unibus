import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'local_student_id_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'UniBus',
    body: message.notification?.body ?? 'You have a new notification',
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _newBusTrackingSubscription;

  static final DateTime _appStartTime = DateTime.now();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'unibus_channel',
    'UniBus Notifications',
    description: 'Important UniBus notifications',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification payload: ${details.payload}');
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showLocalNotification(
        title: message.notification?.title ?? 'UniBus',
        body: message.notification?.body ?? 'You have a new notification',
        payload: jsonEncode(message.data),
      );
    });

    await saveTokenToFirestore();
    await _listenForNewBusTrackingEvents();

    _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
      await _updateUserNotificationSettingsToken(token);
    });
  }

  static Future<void> saveTokenToFirestore() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
      await _updateUserNotificationSettingsToken(token);
    }
  }

  static Future<void> _saveToken(String token) async {
    await _firestore.collection('device_tokens').doc(token).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'role': 'student',
    }, SetOptions(merge: true));
  }

  static Future<void> _updateUserNotificationSettingsToken(String token) async {
    final localStudentId = await LocalStudentIdService.getOrCreateId();

    await _firestore
        .collection('user_notification_settings')
        .doc(localStudentId)
        .set({
          'studentLocalId': localStudentId,
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<void> _listenForNewBusTrackingEvents() async {
    final localStudentId = await LocalStudentIdService.getOrCreateId();

    await _newBusTrackingSubscription?.cancel();

    _newBusTrackingSubscription = _firestore
        .collection('notification_events')
        .where('type', isEqualTo: 'new_bus_tracking')
        .snapshots()
        .listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            if (change.type != DocumentChangeType.added) continue;

            final eventData = change.doc.data();
            if (eventData == null) continue;

            final createdAt = eventData['createdAt'];
            if (createdAt is Timestamp) {
              final createdAtDate = createdAt.toDate();
              if (createdAtDate.isBefore(_appStartTime)) {
                continue;
              }
            }

            final settingsDoc = await _firestore
                .collection('user_notification_settings')
                .doc(localStudentId)
                .get();

            final settings = settingsDoc.data();
            final enabled = settings?['newBusTrackingAlert'] ?? true;

            if (!enabled) continue;

            final busName = eventData['busName']?.toString() ?? 'Unknown Bus';
            final routeName =
                eventData['routeName']?.toString() ?? 'Unknown Route';

            await showLocalNotification(
              title: 'New Bus Started Tracking',
              body: '$busName has started tracking on $routeName',
              payload: jsonEncode({
                'type': 'new_bus_tracking',
                'sessionId': eventData['sessionId'],
                'busName': busName,
                'routeName': routeName,
              }),
            );
          }
        });
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static Future<void> dispose() async {
    await _newBusTrackingSubscription?.cancel();
  }
}
