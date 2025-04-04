import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';

class OnboardingConstroller extends GetxController {
  static OnboardingConstroller get instance => Get.find();

  // Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  // Getter to check if the current page is the last page
  bool get isLastPage => currentPageIndex.value == 2;

  // Update Current Index When Page Scroll
  void updatePageIndicator(index) => currentPageIndex.value = index;

  // Jump to the specific dot selected page
  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Update Current Index & jump to next page
  void nextPage() async {
    if (isLastPage) {
      await completeOnboarding(); // Mark onboarding as complete
      Get.offAll(() => LoginScreen()); // Navigate to LoginScreen
    } else {
      pageController.nextPage(duration: 300.milliseconds, curve: Curves.ease);
    }
  }

  // Update Current Index & jump to last page
  void skipPage() async {
    await completeOnboarding(); // Mark onboarding as complete
    Get.offAll(() => LoginScreen()); // Navigate to LoginScreen
  }

  // Mark onboarding as complete in SharedPreferences
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }
}