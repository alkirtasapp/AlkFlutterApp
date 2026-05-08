import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/features/authentication/screens/onBoarding/onboarding.dart';
import 'package:alkirtas/features/authentication/screens/onBoarding/animated_onboarding.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});
  // function to check if onboarding screen has been seen
  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp must be the single, stable root so GetX's overlay/navigator
    // keys stay valid for the lifetime of the app. The onboarding-flag check
    // runs inside `home` instead of swapping the app shell.
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AlkAppTheme.lightTheme,
      darkTheme: AlkAppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: _hasSeenOnboarding(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final hasSeenOnboarding = snapshot.data ?? false;
          return hasSeenOnboarding
              ? const NavigationMenu(selectedMenu: 0)
              : const AnimatedOnboardingScreen();
        },
      ),
    );
  }
}

/// 1.  Import the required packages
/// 2.  Create a function to check if the onboarding screen has been seen
/// 3.  Build the app
/// 4.  Get the value of the onboarding screen
/// 5.  Show the login screen if the onboarding screen has been seen