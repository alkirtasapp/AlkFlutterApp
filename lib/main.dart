import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test/app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Open product cache box
  await Hive.openBox('productCache');
  
  // add widget Binding

  // initial local storage

  // initilize firebase

  // initilize authentication

  runApp(const App());
}
