import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/features/authentication/screens/login/log_in.dart';
import 'package:test/features/authentication/screens/onBoarding/onboarding.dart';
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
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final hasSeenOnboarding = snapshot.data ?? false;
          return GetMaterialApp(
            debugShowCheckedModeBanner: true,
            themeMode: ThemeMode.light,
            theme: TAppTheme.lightTheme,
            darkTheme: TAppTheme.darkTheme,
            // redirect to login Screen 
            home: hasSeenOnboarding ? LoginScreen() : const OnBoardingScreen(),
          );
        }
      },
    );
  }
}