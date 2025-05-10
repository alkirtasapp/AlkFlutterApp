import 'package:alkirtas/api/firebase_api.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/features/authentication/screens/splash_wrapper.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/features/shop/controllers/product_card_controller.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alkirtas/app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC4SAK_0VrCxV9lAXDShgUu1cR-gn8F3Zo",
      appId: "1:807654268134:android:76749e2db7d4b7d02e6f27",
      projectId: "app-tracking-4a895",
      messagingSenderId: "807654268134",
      storageBucket: "app-tracking-4a895.firebasestorage.app",
    ),
  );
  await FirebaseApi().initNotifications();

  // Initialize Firebase Analytics
  final analytics = FirebaseAnalytics.instance;

  // Initialize Hive
  await Hive.initFlutter();
  var box = await Hive.openBox('productCache');
  await box.clear();
  print("Product cache cleared on app reload");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const SplashWrapper(),
    ),
  );
}