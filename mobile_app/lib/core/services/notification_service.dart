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
    // request*Permission must stay false so iOS does not show the system
    // prompt during cold start (before any UI). The prompt is raised from a
    // user-facing opt-in point via [requestPermission].
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // The OS permission prompt is intentionally NOT requested here: cold start
    // runs before any UI can explain why notifications are wanted. It is
    // requested from a user-facing opt-in point instead — see
    // [requestPermission] (onboarding completion and Settings).
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

  /// Asks the OS for push permission.
  ///
  /// This must only be called from a user-facing opt-in point (onboarding
  /// completion or the Settings screen) so the user sees a rationale first —
  /// never from [initialize] on cold start.
  ///
  /// Returns true when the user granted (or provisionally granted) permission.
  Future<bool> requestPermission() async {
    try {
      await _requestPermissions();
      final settings = await _messaging.getNotificationSettings();
      final status = settings.authorizationStatus;
      final granted = status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (granted) {
        await _getToken();
      }
      return granted;
    } catch (_) {
      // Firebase may be unavailable (e.g. missing google-services config).
      return false;
    }
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
