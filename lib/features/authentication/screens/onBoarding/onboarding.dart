import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:alkirtas/features/authentication/controller.onboarding/onboarding_constroller.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/constants/text_strings.dart';
import 'package:alkirtas/utils/device/device_utility.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});



  @override
  Widget build(BuildContext context) {

    final controller = Get.put(OnboardingConstroller());
    final dark=AlkHelperFunctions.isDarkMode(context);
    return Scaffold(
      body: Stack(
        children: [
          //Horizontal Scrollable page
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              onBoardingPage(
                image: AlkImages.onBoardingImage1,
                title: AlkTexts.onBoardingTitle1,
                subtitle: AlkTexts.onBoardingSsubtitle1,
              ),
              onBoardingPage(
                image: AlkImages.onBoardingImage2,
                title: AlkTexts.onBoardingTitle1,
                subtitle: AlkTexts.onBoardingSsubtitle1,
              ),
              onBoardingPage(
                image: AlkImages.onBoardingImage3,
                title: AlkTexts.onBoardingTitle1,
                subtitle: AlkTexts.onBoardingSsubtitle1,
              )
            ],
          ),
          //skip button
          onBoardingSkip(),
          // dot navigation smoothPageIndicator
          onBoardingIndicator(dark: dark),       
          //circular button
          onBoardingButtom()
        ],
      ),
    );
  }
}

// ignore: camel_case_types
class onBoardingButtom extends StatelessWidget {
  const onBoardingButtom({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AlkSize.defaultSpace,
      bottom: AlkDeviceUtils.getBottomNavigationBarHeight(),
    child: ElevatedButton(
      onPressed: ()=> OnboardingConstroller.instance.nextPage(),
      style: ElevatedButton.styleFrom(shape:  const CircleBorder()),
      child: const  Icon(Iconsax.arrow_right_3,color: Colors.white,),
    ));
  }
}

// ignore: camel_case_types
class onBoardingIndicator extends StatelessWidget {
  const onBoardingIndicator({
    super.key,
    required this.dark,
  });

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingConstroller.instance;
    return Positioned(
      bottom: AlkDeviceUtils.getBottomNavigationBarHeight()+25,
      left: AlkSize.defaultSpace ,
      
      child: SmoothPageIndicator(
      controller: controller.pageController,
      onDotClicked: controller.dotNavigationClick,
      count: 3, 
      effect : ExpandingDotsEffect(activeDotColor: dark ? AlkColors.light:  AlkColors.dark, dotHeight: 6),),
      );
  }
}

// ignore: camel_case_types
class onBoardingSkip extends StatelessWidget { 
  const onBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: AlkDeviceUtils.getAppBarHeight(),
        right: AlkSize.defaultSpace,
        child: TextButton(
          onPressed: () =>OnboardingConstroller.instance.skipPage(),
          child:const Text('Skip'),
        ));
  }
}

// ignore: camel_case_types
class onBoardingPage extends StatelessWidget {
  const onBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });
  final String image, title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AlkSize.defaultSpace),
      child: Column(
        children: [
          Image(
            width: AlkHelperFunctions.screenWidth() * 0.8,
            height: AlkHelperFunctions.screenHeight() * 0.6,
            image: AssetImage(image),
          ),
          Text(title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: AlkSize.spaceBtwItems),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
