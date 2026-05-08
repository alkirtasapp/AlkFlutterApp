// Firebase disabled for iOS build compatibility.
// Original implementation preserved below as comments.
// Do not import this file from anywhere until Firebase is re-enabled in pubspec.yaml.

// import 'dart:convert';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../navigation_menu.dart'; // Adjusted path to NavigationMenu
//
// class FirebaseApi {
//   final _firebaseMessaging = FirebaseMessaging.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _localNotifications = FlutterLocalNotificationsPlugin();
//   Future<void> initNotifications() async {
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Initialize local notifications
//     const androidSettings =
//         AndroidInitializationSettings('@drawable/ic_notification');
//     const iosSettings = DarwinInitializationSettings();
//     const initializationSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//     await _localNotifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse:
//           (NotificationResponse notificationResponse) async {
//         final String? payload = notificationResponse.payload;
//         if (payload != null) {
//           print('Notification Tapped (Local) - Payload: $payload');
//           try {
//             final data = jsonDecode(payload);
//             _handleMessageNavigation(Map<String, dynamic>.from(data));
//           } catch (e) {
//             print('Error decoding notification payload or navigating: $e');
//           }
//         }
//       },
//     );
//
//     // Create notification channel for Android
//     await _createNotificationChannel();
//
//     final fCMToken = await _firebaseMessaging.getToken();
//     print(' FCM Token: $fCMToken');
//
//     if (fCMToken != null) {
//       await saveTokenToFirestore(fCMToken);
//     }
//
//     FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToFirestore);
//
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Foreground Message data: ${message.data}');
//       _showNotification(message);
//     });
//
//     // Handle notification tap when app is in background (not terminated)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('Message clicked (App in Background)! Data: ${message.data}');
//       _handleMessageNavigation(message.data);
//     });
//
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   }
//
//   // Method to be called from SplashWrapper or main.dart for terminated state
//   Future<bool> handleInitialMessage() async {
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null && initialMessage.data.isNotEmpty) {
//       print('Initial Message data (App Terminated): ${initialMessage.data}');
//       _handleMessageNavigation(initialMessage.data);
//       return true; // Indicated that navigation was handled
//     }
//     return false; // No navigation from initial message
//   }
//
//   Future<void> _createNotificationChannel() async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'This channel is used for important notifications.',
//       importance: Importance.max,
//     );
//
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   Future<void> _showNotification(RemoteMessage message) async {
//     final notification = message.notification;
//
//     if (notification != null) {
//       // Encode the data payload to pass to local notification
//       String? payloadData;
//       if (message.data.isNotEmpty) {
//         payloadData = jsonEncode(message.data);
//       }
//
//       await _localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription:
//                 'This channel is used for important notifications.',
//             importance: Importance.max,
//             priority: Priority.high,
//             icon: '@drawable/ic_notification',
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         payload: payloadData, // Pass the FCM data payload here
//       );
//     }
//   }
//
//   Future<void> saveTokenToFirestore(String token) async {
//     await _firestore.collection('deviceTokens').doc('tokens').set({
//       'tokens': [token], // Store as single-item array
//       'lastUpdated': FieldValue.serverTimestamp(),
//     });
//   }
//
//   // Handles navigation based on message data
//   Future<void> _handleMessageNavigation(Map<String, dynamic> data) async {
//     print('Handling navigation for data: $data');
//     final String? navigateTo = data['navigateTo'] as String?;
//
//     if (navigateTo != null) {
//       final prefs = await SharedPreferences.getInstance();
//
//       // 🔐 Example check: is user logged in (customize this check)
//       final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//       if (isLoggedIn) {
//         // User is logged in → navigate now
//         _navigateToScreen(navigateTo);
//       } else {
//         // Not logged in → save it for later
//         await prefs.remove('pendingNavigation'); // Ensure it's clean
//         await prefs.setString('pendingNavigation', navigateTo); // Save latest
//
//         print('Saved navigation "$navigateTo" for after login.');
//       }
//     }
//   }
//
//   void _navigateToScreen(String screen) {
//     if (screen == 'promos') {
//       Get.offAll(() => const NavigationMenu(selectedMenu: 1));
//     }
//
//     // Add more cases here if needed
//   }
// }
//
// // This needs to be a top-level function
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling a background message: ${message.messageId}");
// }
