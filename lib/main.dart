import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test/app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Open product cache box
  var box = await Hive.openBox('productCache');

  // fassa5 l cache every restart
  await box.clear();
  print(" Product cache cleared on app reload");

  runApp(const App());
}

