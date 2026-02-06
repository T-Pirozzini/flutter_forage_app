import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing push notifications via Firebase Cloud Messaging.
///
/// Handles:
/// - FCM token retrieval and storage
/// - Token refresh
/// - Foreground notification display
/// - Notification tap handling
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback for when a notification is tapped
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Android notification channel for the app
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'forager_notifications',
    'Forager Notifications',
    description: 'Notifications from Flutter Forager app',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize the notification service.
  ///
  /// Call this after Firebase.initializeApp() in main.dart.
  Future<void> initialize() async {
    // Request permission (required for iOS and Android 13+)
    await _requestPermission();

    // Initialize local notifications for foreground display
    await _initializeLocalNotifications();

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Set up foreground message handler
    _setupForegroundHandler();

    // Set up notification tap handlers
    _setupNotificationTapHandlers();

    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions.
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications plugin.
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// Handle local notification tap.
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and handle tap
      // Payload format: "type:value,postId:value,..."
      final data = _parsePayload(response.payload!);
      onNotificationTap?.call(data);
    }
  }

  /// Parse notification payload string to map.
  Map<String, dynamic> _parsePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  /// Convert map to payload string.
  String _createPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Set up handler for foreground messages.
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');

      final notification = message.notification;
      if (notification != null) {
        // Show local notification when app is in foreground
        showLocalNotification(
          title: notification.title ?? 'Forager',
          body: notification.body ?? '',
          data: message.data,
        );
      }
    });
  }

  /// Set up handlers for notification taps.
  void _setupNotificationTapHandlers() {
    // Handle tap when app was terminated
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('App opened from terminated state via notification');
        // Delay to allow app to initialize
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap?.call(message.data);
        });
      }
    });

    // Handle tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('App opened from background via notification');
      onNotificationTap?.call(message.data);
    });
  }

  /// Show a local notification (for foreground messages).
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF4CAF50), // Green accent
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
      payload: data != null ? _createPayload(data) : null,
    );
  }

  /// Get and save FCM token for the current user.
  ///
  /// Stores the token in the user's notificationPreferences in Firestore.
  Future<String?> getAndSaveToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        debugPrint('Cannot save FCM token: no user logged in');
        return null;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('Failed to get FCM token');
        return null;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'notificationPreferences.fcmToken': token,
        'notificationPreferences.fcmTokenUpdatedAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved for ${user.email}');

      // Set up token refresh listener
      _setupTokenRefresh();

      return token;
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
      return null;
    }
  }

  /// Set up listener for token refresh.
  void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed');
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.email)
            .update({
          'notificationPreferences.fcmToken': newToken,
          'notificationPreferences.fcmTokenUpdatedAt':
              FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Delete FCM token (e.g., on logout).
  Future<void> deleteToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.email)
            .update({
          'notificationPreferences.fcmToken': FieldValue.delete(),
          'notificationPreferences.fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Subscribe to a topic (for broadcast notifications).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}
