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
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Whether Firebase push is usable on this device.
  ///
  /// False when the native Firebase config files are missing or invalid —
  /// `android/app/google-services.json` and
  /// `ios/Runner/GoogleService-Info.plist`. See `.env.example` for what is
  /// needed to turn push on.
  ///
  /// When false the service is a deliberate no-op: no crash, no FCM token,
  /// no remote messages. Local notifications still work.
  bool _pushAvailable = false;
  bool get pushAvailable => _pushAvailable;

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
    // Local notifications do not depend on Firebase and are always safe to
    // set up, so they are configured regardless of push availability.
    await _initializeLocalNotifications();

    // Firebase requires the native config files to be present. Without them
    // `Firebase.initializeApp()` throws. Degrade to a no-op rather than
    // crashing the app on cold start (or leaving `_messaging` in a
    // half-initialised `late` state that would throw on first use).
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _pushAvailable = true;
    } catch (_) {
      // Missing/invalid google-services.json or GoogleService-Info.plist.
      _pushAvailable = false;
      _messaging = null;
      _fcmToken = null;
      return;
    }

    // The OS permission prompt is intentionally NOT requested here: cold start
    // runs before any UI can explain why notifications are wanted. It is
    // requested from a user-facing opt-in point instead — see
    // [requestPermission] (onboarding completion and Settings).
    await _getToken();
    _setupForegroundHandler();
    _setupTapHandler();
    _setupTokenRefreshHandler();
  }

  Future<void> _initializeLocalNotifications() async {
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
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _navigationListeners.clear();
  }

  Future<void> _requestPermissions() async {
    final messaging = _messaging;
    if (messaging == null) return;
    await messaging.requestPermission(
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
  /// Returns false immediately when push is unavailable (see [pushAvailable]).
  Future<bool> requestPermission() async {
    if (!_pushAvailable) return false;
    try {
      await _requestPermissions();
      final messaging = _messaging;
      if (messaging == null) return false;
      final settings = await messaging.getNotificationSettings();
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
    if (!_pushAvailable) return;
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        await _registerToken(_fcmToken!);
      }
    } catch (_) {
      // Token fetch can fail transiently; push stays non-fatal.
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
    // `onMessage` is a static member of FirebaseMessaging; the null check on
    // _messaging is what gates on push being available.
    if (_messaging == null) return;
    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _setupTapHandler() {
    final messaging = _messaging;
    if (messaging == null) return;
    // `onMessageOpenedApp` is static; `getInitialMessage` is an instance call.
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    messaging.getInitialMessage().then(_handleNotificationTap);
  }

  void _setupTokenRefreshHandler() {
    final messaging = _messaging;
    if (messaging == null) return;
    _onTokenRefreshSub = messaging.onTokenRefresh.listen((token) {
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
    if (!_pushAvailable) return;
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      await messaging.deleteToken();
      _fcmToken = null;
    } catch (_) {
      // Best effort — never block sign-out on push teardown.
    }
  }
}
