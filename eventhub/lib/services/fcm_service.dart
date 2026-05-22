import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Top-level background handler — must stay top-level for FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  await Firebase.initializeApp();
  await FCMService.showNotificationFromMessage(message, isBackground: true);
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotificationsReady = false;

  static final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  static final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'eventhub_high_importance',
    'EventHub Notifications',
    description: 'EventHub event reminders and assistance requests',
    importance: Importance.high,
  );

  static Future<Map<String, dynamic>?> getInitialNotification() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message?.data;
    } catch (e) {
      debugPrint('Error getting initial FCM message: $e');
      return null;
    }
  }

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _ensureLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showNotificationFromMessage(message, isBackground: false);
      _foregroundMessageController.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM background message tapped: ${message.data}');
      _notificationTapController.add(message.data);
    });

    await refreshAndSaveToken();
    _messaging.onTokenRefresh.listen(_saveTokenToBackend);
  }

  static Future<void> _ensureLocalNotifications() async {
    if (_localNotificationsReady) return;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;
        try {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;
          _notificationTapController.add(data);
        } catch (e) {
          debugPrint('Error parsing notification payload: $e');
        }
      },
    );

    _localNotificationsReady = true;
  }

  /// Shows a system notification from FCM (foreground + background/killed).
  static Future<void> showNotificationFromMessage(
    RemoteMessage message, {
    bool isBackground = false,
  }) async {
    await _ensureLocalNotifications();

    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title == null || body == null) return;

    // Android shows notification-payload messages automatically when app is not in foreground.
    if (isBackground &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        message.notification != null) {
      return;
    }

    final data = Map<String, dynamic>.from(message.data);
    final notificationId = _notificationId(message);

    await _localNotifications.show(
      notificationId,
      title,
      body,
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
          presentBadge: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static String? _resolveTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title'] ??
        _defaultTitleForType(message.data['type']);
  }

  static String? _resolveBody(RemoteMessage message) {
    return message.notification?.body ??
        message.data['body'] ??
        message.data['message'];
  }

  static String? _defaultTitleForType(String? type) {
    switch (type) {
      case 'assistant_request':
        return 'طلب مساعدة جديد';
      case 'event':
        return 'إشعار فعالية';
      case 'ticket':
        return 'تذكرة';
      default:
        return type != null ? 'EventHub' : null;
    }
  }

  static int _notificationId(RemoteMessage message) {
    final raw = message.data['request_id'] ??
        message.data['related_id'] ??
        message.messageId;
    if (raw != null) return raw.hashCode;
    return message.hashCode;
  }

  static Future<void> refreshAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      }
    } catch (_) {}
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) return;

      final api = ApiService();
      await api.post('/fcm-token', {'fcm_token': token});
    } catch (_) {}
  }
}
