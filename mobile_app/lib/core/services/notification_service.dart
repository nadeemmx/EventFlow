import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  final ApiClient _apiClient;
  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  final List<void Function(String route)> _navigationListeners = [];

  void addNavigationListener(void Function(String route) listener) {
    _navigationListeners.add(listener);
  }

  void removeNavigationListener(void Function(String route) listener) {
    _navigationListeners.remove(listener);
  }

  NotificationService({
    required this._apiClient,
  });

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermissions();
    await _getToken();
    _setupForegroundHandler();
    _setupTapHandler();
    _setupTokenRefreshHandler();
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _navigationListeners.clear();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _getToken() async {
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      await _registerToken(_fcmToken!);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.post(
        ApiEndpoints.notificationRegisterDevice,
        data: {
          'fcm_token': token,
          'device_type': 'mobile',
        },
      );
    } catch (_) {}
  }

  void _setupForegroundHandler() {
    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _setupTapHandler() {
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _messaging.getInitialMessage().then(_handleNotificationTap);
  }

  void _setupTokenRefreshHandler() {
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _registerToken(token);
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'eventflow_channel',
      'EventFlow Notifications',
      channelDescription: 'EventFlow push notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  void _handleNotificationTap(RemoteMessage? message) {
    if (message == null) return;
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      for (final listener in _navigationListeners) {
        listener(route);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      for (final listener in _navigationListeners) {
        listener(payload);
      }
    }
  }

  Future<void> updateBadgeCount(int count) async {
    // Badge count is managed by the server-side FCM notification payload
    // On iOS, the badge is set via the FCM notification data
    // On Android, badges are handled by the launcher
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
  }
}
