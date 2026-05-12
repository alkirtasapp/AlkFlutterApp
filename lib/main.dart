// import 'package:alkirtas/api/firebase_api.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/features/authentication/screens/splash_wrapper.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/features/shop/controllers/product_card_controller.dart';
import 'package:alkirtas/features/shop/models/saved_cart_model.dart';
import 'package:alkirtas/features/audiobooks/audiobooks.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alkirtas/app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alkirtas/providers/coupon_provider.dart';
import 'package:alkirtas/providers/loyalty_provider.dart';
import 'package:alkirtas/providers/odoo_account_provider.dart';
import 'package:alkirtas/providers/app_config_provider.dart';
import 'package:alkirtas/providers/wishlist_provider.dart';
import 'package:alkirtas/utils/logging/logger.dart';

Future<void> main() async {
  // Wrap everything in error handling to prevent white screens
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Firebase disabled for iOS build compatibility
    // await Firebase.initializeApp(
    //   options: FirebaseOptions(
    //     apiKey: AppConfig.firebaseApiKey,
    //     appId: AppConfig.firebaseAppId,
    //     projectId: AppConfig.firebaseProjectId,
    //     messagingSenderId: AppConfig.firebaseMessagingSenderId,
    //     storageBucket: AppConfig.firebaseStorageBucket,
    //   ),
    // );
    // await FirebaseApi().initNotifications();
    // final analytics = FirebaseAnalytics.instance;

    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(CouponAdapter());
    Hive.registerAdapter(SavedCartAdapter());
    await Hive.openBox<Coupon>('couponsBox');
    await Hive.openBox<SavedCart>('savedCartsBox');
    await Hive.openBox('priceAlertsBox');

    // Clear caches on app restart (will be re-cached when screens load)
    var productBox = await Hive.openBox('productCache');
    await productBox.clear();
    var bannerBox = await Hive.openBox('bannerBox');
    await bannerBox.clear();
    var sectionsBox = await Hive.openBox('sectionsBox');
    await sectionsBox.clear();

    // Initialize CartProvider and load saved cart (cart persists across restarts)
    final cartProvider = CartProvider();
    await cartProvider.initialize();

    // Initialize AppConfigProvider and load remote colors
    final appConfigProvider = AppConfigProvider();
    await appConfigProvider.loadConfig();

    // Initialize WishlistProvider (loads Hive + inits local notifications)
    final wishlistProvider = WishlistProvider();
    await wishlistProvider.init();

    AlkLoggerHelper.info("App initialized: env, hive, cart, appConfig | caches cleared (firebase disabled)");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cartProvider),
          ChangeNotifierProvider.value(value: appConfigProvider),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CouponProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
          ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
          ChangeNotifierProvider(create: (_) => OdooAccountProvider()),
          ChangeNotifierProvider.value(value: wishlistProvider),
        ],
        child: const SplashWrapper(),
      ),
    );
  } catch (e, stackTrace) {
    AlkLoggerHelper.error("CRITICAL: App initialization failed: $e", stackTrace);

    // Still try to run the app even if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur d\'initialisation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Une erreur est survenue lors du démarrage de l\'application.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Détails: $e',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}