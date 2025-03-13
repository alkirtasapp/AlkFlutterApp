import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test/app.dart';
import 'package:flutter/material.dart';


Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive 
  await Hive.initFlutter();
  
  // Open product cache box
  var box = await Hive.openBox('productCache');

  // clear  l cache every restart
  await box.clear();
  print(" Product cache cleared on app reload");

  // Run the app
  runApp(const App());

}

 /// 1.  Import the required packages
 /// 2.  Initialize Hive  
 /// 3.  Open the product cache box
 /// 4.  Clear the cache on app reload
 /// 5.  Run the app
 /// 6.  The cache is now cleared every time the app is restarted

