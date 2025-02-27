import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/features/authentication/screens/login/log_in.dart';

class OnboardingConstroller extends GetxController {
  static OnboardingConstroller get instance => Get.find();

  // Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  // Update Current Index When Page Scroll 
  void updatePageIndicator(index) => currentPageIndex.value = index;
   
  // Jump to the specific dot selected page
  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }
   
  // Update Current Index & jump to next page
  void nextPage() async {
    if (currentPageIndex.value == 2) {
      // Set onboarding completion flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      // Navigate to LoginScreen and clear the navigation stack
      Get.offAll(() => LoginScreen());
    } else {
      pageController.nextPage(duration: 300.milliseconds, curve: Curves.ease);
    }
  }

  // Update Current Index & jump to last page
  void skipPage() async {
    // Set onboarding completion flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    // Navigate to LoginScreen and clear the navigation stack
    Get.offAll(() => LoginScreen());
  }
}