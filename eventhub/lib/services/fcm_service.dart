import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown by FCM automatically on Android
  // No need to do anything here for basic push display
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android notification channel for high-priority notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'eventhub_high_importance',
    'EventHub Notifications',
    description: 'EventHub event reminders and alerts',
    importance: Importance.high,
  );

  /// Call this once from main() after Firebase.initializeApp()
  static Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 3. Setup local notifications for foreground display
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request Android 13+ permission specifically
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // 4. Foreground messages: show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 5. Get token and save to backend
    await refreshAndSaveToken();

    // 6. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenToBackend(newToken);
    });
  }

  /// Get the current FCM token and send it to the Laravel backend
  static Future<void> refreshAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      // FCM not available (emulator without Google Play, etc.)
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      // Only save if we have an auth token (user is logged in)
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) return;

      final api = ApiService();
      await api.post('/fcm-token', {'fcm_token': token});
    } catch (_) {
      // Ignore errors — will retry on next launch
    }
  }
}
