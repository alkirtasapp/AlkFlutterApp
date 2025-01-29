 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/features/authentication/screens/onBoarding/onboarding.dart';

import 'utils/theme/theme.dart';
 class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: true,
      themeMode: ThemeMode.light,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: const OnBoardingScreen(),
    );
  }
}