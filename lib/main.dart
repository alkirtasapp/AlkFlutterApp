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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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