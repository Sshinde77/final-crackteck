import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../constants/api_constants.dart';
import '../core/navigation_service.dart';
import '../core/secure_storage_service.dart';

const AndroidNotificationChannel _defaultNotificationChannel =
    AndroidNotificationChannel(
      'crackteck_field_alerts',
      'Crackteck Field Alerts',
      description: 'Used for service and backend push notifications.',
      importance: Importance.max,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _listenersAttached = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_initialized) return;

    await _ensureFirebaseReady();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _configureForegroundPresentation();
    await _logAndPersistCurrentToken();
    _attachMessageListeners();
    await _handleInitialMessage();

    _initialized = true;
  }

  Future<void> _ensureFirebaseReady() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(jsonDecode(payload) as Map);
          _handleNotificationTapData(data);
        } catch (error) {
          debugPrint('Failed to parse local notification payload: $error');
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_defaultNotificationChannel);
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM notification authorization: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        debugPrint('Android notification permission: $result');
      }
    }
  }

  Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _attachMessageListeners() {
    if (_listenersAttached) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM foreground message: ${message.messageId}');
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM notification opened app: ${message.messageId}');
      _handleNotificationTapData(message.data);
    });

    _messaging.onTokenRefresh.listen((String token) async {
      await SecureStorageService.saveFcmToken(token);
      print('FCM token refreshed: $token');
      await syncTokenWithBackendIfPossible();
    });

    _listenersAttached = true;
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    debugPrint('FCM app launch message: ${initialMessage.messageId}');
    _handleNotificationTapData(initialMessage.data);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final String? title = notification?.title ?? message.data['title']?.toString();
    final String? body = notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultNotificationChannel.id,
          _defaultNotificationChannel.name,
          channelDescription: _defaultNotificationChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showLocalTestNotification() async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Crackteck Test Notification',
      'Local notification is working on this device.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultNotificationChannel.id,
          _defaultNotificationChannel.name,
          channelDescription: _defaultNotificationChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(<String, dynamic>{'type': 'notification'}),
    );
  }

  Future<String?> _logAndPersistCurrentToken() async {
    await _ensureFirebaseReady();
    final String? token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token is not available yet.');
      return null;
    }

    await SecureStorageService.saveFcmToken(token);
    print('FCM token: $token');
    return token;
  }

  Future<String?> refreshAndGetToken() async {
    return _logAndPersistCurrentToken();
  }

  Future<NotificationSettings> getPermissionSettings() async {
    return _messaging.getNotificationSettings();
  }

  Future<void> syncTokenWithBackendIfPossible({bool forceRefresh = false}) async {
    try {
      final String? token = forceRefresh
          ? await _logAndPersistCurrentToken()
          : (await SecureStorageService.getFcmToken()) ??
              await _logAndPersistCurrentToken();
      if (token == null || token.isEmpty) return;

      final int? userId = await SecureStorageService.getUserId();
      final int? roleId = await SecureStorageService.getRoleId();
      final String? accessToken = await SecureStorageService.getAccessToken();
      final String deviceId = await SecureStorageService.getOrCreateDeviceId();
      final String deviceType = Platform.isIOS ? 'ios' : 'android';

      if (userId == null ||
          roleId == null ||
          accessToken == null ||
          accessToken.isEmpty) {
        debugPrint(
          'FCM token sync postponed until authenticated user context exists.',
        );
        return;
      }

      final String syncSignature = '$userId|$roleId|$deviceId|$token';
      final String? lastSynced =
          await SecureStorageService.getLastSyncedFcmToken();
      if (!forceRefresh &&
          (lastSynced == syncSignature || lastSynced == token)) {
        debugPrint('FCM token already synced with backend.');
        return;
      }

      final Uri uri = Uri.parse(
        ApiConstants.FCMtoken,
      ).replace(
        queryParameters: <String, String>{
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
          'fcm_token': token,
          'device_type': deviceType,
          'device_id': deviceId,
        },
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await SecureStorageService.saveLastSyncedFcmToken(syncSignature);
        debugPrint('FCM token synced to backend successfully.');
      } else {
        debugPrint(
          'FCM token sync failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('FCM token sync error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleNotificationTapData(Map<String, dynamic> rawData) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
    final String? routeName =
        data['route']?.toString() ?? data['screen']?.toString();

    if (routeName != null && routeName.isNotEmpty && routeName.startsWith('/')) {
      navigator.pushNamed(routeName, arguments: data);
      return;
    }

    final dynamic type = data['type'] ?? data['notification_type'];
    final String? normalizedType = type?.toString().trim().toLowerCase();
    if (normalizedType == 'notification' || normalizedType == 'notifications') {
      navigator.pushNamed('/field_executive_notification');
    }
  }
}
