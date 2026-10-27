import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/config/firebase_options.dart';
import 'package:alkirtas/services/notification_inbox_service.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Background/terminated messages with a `notification` block are shown by
/// the OS itself — nothing to do here, but FCM requires a top-level handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging: permission, topic subscription, foreground
/// display and tap handling.
///
/// Every device subscribes to the [broadcastTopic] topic so the back office
/// can send to all users without storing device tokens.
class PushNotificationService {
  static const String broadcastTopic = 'all';
  static const String _channelId = 'push_channel';
  static const String _channelName = 'Actualités et promotions';

  static bool _ready = false;

  /// Last Firebase/FCM error, shown on the notifications status screen.
  static String? lastError;

  /// Whether Firebase initialized and push can be received.
  static bool get isFirebaseReady => _ready;

  /// Called on tap with the message data (e.g. `product_id`).
  static void Function(Map<String, dynamic> data)? onTap;

  /// Asks the OS for notification permission. Independent of Firebase so the
  /// wishlist's local alerts work even when push is unavailable.
  static Future<void> requestPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      if (Platform.isAndroid) {
        await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      AlkLoggerHelper.error('Notification permission request failed', e);
    }
  }

  /// True when the OS currently allows this app to show notifications.
  static Future<bool> areNotificationsEnabled() async {
    final plugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      final perms = await plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return perms?.isEnabled ?? false;
    }
    return false;
  }

  /// Initializes Firebase. Safe to call when no config exists for the
  /// current platform — push is then simply disabled.
  static Future<void> initFirebase() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      lastError = 'Firebase non configuré pour cette plateforme';
      AlkLoggerHelper.info(lastError!);
      return;
    }
    try {
      await Firebase.initializeApp(options: options);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _ready = true;
    } catch (e) {
      lastError = 'Init Firebase: $e';
      AlkLoggerHelper.error('Firebase init failed', e);
    }
  }

  /// Asks for notification permission (iOS + Android 13+), subscribes to the
  /// broadcast topic and wires up message listeners. Call once the user is
  /// past splash/onboarding.
  static Future<void> start() async {
    await requestPermission();
    if (!_ready) return;
    final messaging = FirebaseMessaging.instance;

    try {
      // iOS: also goes through FCM so it registers for remote notifications.
      if (Platform.isIOS) {
        await messaging
            .requestPermission(alert: true, badge: true, sound: true)
            .timeout(const Duration(seconds: 30));
      }

      // iOS: show pushes as banners while the app is open.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ));

      FirebaseMessaging.onMessage.listen((m) {
        _showForeground(m);
        NotificationInboxService.refresh();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onTap?.call(m.data));
      // A new FCM token (e.g. APNs arriving late) is a good moment to retry.
      messaging.onTokenRefresh.listen((_) => ensureSubscribed());
    } catch (e) {
      lastError = 'FCM: $e';
      AlkLoggerHelper.error('Push notification setup failed', e);
    }

    // Subscribe independently so a slow step above can't block it.
    ensureSubscribed();

    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) onTap?.call(initial.data);
    } catch (e) {
      AlkLoggerHelper.error('getInitialMessage failed', e);
    }
  }

  /// What iOS answered to the push registration, recorded by AppDelegate.
  static Future<String> _apnsResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getString('apns_result') ?? 'aucune réponse';
    } catch (_) {
      return 'inconnu';
    }
  }

  static Future<void>? _subscribing;

  /// Joins the [broadcastTopic] topic if not done yet. Safe to call often;
  /// concurrent calls share the same attempt.
  static Future<void> ensureSubscribed() {
    if (!_ready || subscribed) return Future.value();
    return _subscribing ??= _subscribe().whenComplete(() => _subscribing = null);
  }

  /// Each step has a timeout: the iOS SDK can wait forever on a missing
  /// APNs/FCM token, which used to leave the status red with no error.
  static Future<void> _subscribe() async {
    final messaging = FirebaseMessaging.instance;
    try {
      // iOS needs the APNs token before any FCM call; it can lag on launch.
      if (Platform.isIOS) {
        lastError = 'En attente du jeton APNs…';
        String? apns;
        for (var i = 0; i < 10 && apns == null; i++) {
          apns = await messaging
              .getAPNSToken()
              .timeout(const Duration(seconds: 5), onTimeout: () => null);
          if (apns == null) await Future.delayed(const Duration(seconds: 2));
        }
        if (apns == null) {
          lastError = 'Jeton APNs indisponible — Apple: ${await _apnsResult()}';
          AlkLoggerHelper.info('APNs token unavailable, skipping topic subscribe');
          return;
        }
      }

      lastError = 'En attente du jeton Firebase…';
      final token =
          await messaging.getToken().timeout(const Duration(seconds: 20));
      if (token == null) {
        lastError = 'Jeton Firebase vide';
        return;
      }
      AlkLoggerHelper.info('FCM token: $token');

      lastError = 'Inscription au sujet "$broadcastTopic"…';
      await messaging
          .subscribeToTopic(broadcastTopic)
          .timeout(const Duration(seconds: 20));
      subscribed = true;
      lastError = null;
    } on TimeoutException {
      lastError = '$lastError (délai dépassé)';
      AlkLoggerHelper.info('Push subscribe timed out: $lastError');
    } catch (e) {
      lastError = 'FCM: $e';
      AlkLoggerHelper.error('Push topic subscribe failed', e);
    }
  }

  /// Whether this device joined the [broadcastTopic] topic.
  static bool subscribed = false;

  static const String _payloadPrefix = 'push:';

  /// Returns the push data stored in a local notification payload, or null
  /// when the payload is something else (a wishlist product id).
  static Map<String, dynamic>? decodePayload(String payload) {
    if (!payload.startsWith(_payloadPrefix)) return null;
    try {
      return Map<String, dynamic>.from(
          jsonDecode(payload.substring(_payloadPrefix.length)) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Android doesn't display pushes while the app is in the foreground, so
  /// mirror them as a local notification carrying the push data; taps come
  /// back through WishlistProvider's handler and [decodePayload].
  static Future<void> _showForeground(RemoteMessage message) async {
    if (!Platform.isAndroid) return;
    final notification = message.notification;
    if (notification == null) return;

    await FlutterLocalNotificationsPlugin().show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      ),
      payload: message.data.isEmpty
          ? null
          : _payloadPrefix + jsonEncode(message.data),
    );
  }
}
