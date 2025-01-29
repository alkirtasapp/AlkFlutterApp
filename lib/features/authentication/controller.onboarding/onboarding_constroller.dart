import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/features/authentication/screens/login/log_in.dart';


class OnboardingConstroller extends GetxController {
  static OnboardingConstroller get instance => Get.find();

  //Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  //Update Current Index When Page Scroll 
  void updatePageIndicator  (index) => currentPageIndex.value= index;
   
   // jump to the specific dot selected page .
  void dotNavigationClick(index){
    currentPageIndex.value= index;
    pageController.jumpTo(index);

  }
   
  // Update Current Index & jump to next page
  void nextPage(){
    if (currentPageIndex.value == 2 ){
      //Get.to(LoginPage());
      Get.offAll( LoginScreen());
    }else{
      int page= currentPageIndex.value +1;
      pageController.jumpToPage(page);
    }
  }

  // Update Current Index & jump to last page.
  void skipPage(){
  Get.to(LoginScreen());
  }
  
}