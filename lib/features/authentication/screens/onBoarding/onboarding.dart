import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _showTermsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTerms = prefs.getBool('hasSeenTerms') ?? false;

    if (!hasSeenTerms) {
      // Show the terms dialog
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing without accepting
        builder: (context) {
          return AlertDialog(
            title: const Text('Conditions d\'utilisation'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Bienvenue sur Alkirtas! Voici les termes et conditions d'utilisation de notre plateforme. "
                    "En utilisant notre application, vous acceptez les règles suivantes :",
                  ),
                  SizedBox(height: 16),
                  Text(
                    "1. Utilisation de la plateforme",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Vous devez utiliser la plateforme de manière responsable et respecter les lois en vigueur.",
                  ),
                  SizedBox(height: 16),
                  Text(
                    "2. Protection des données",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Nous respectons votre vie privée et protégeons vos données personnelles conformément à notre politique de confidentialité.",
                  ),
                  SizedBox(height: 16),
                  Text(
                    "3. Responsabilité",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Nous ne sommes pas responsables des dommages causés par une mauvaise utilisation de la plateforme.",
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Pour plus d'informations, veuillez consulter notre site web www.alkirtas.com ou nous contacter via notre tél 72 413 913.", 
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Save that the user has seen the terms
                  await prefs.setBool('hasSeenTerms', true);
                  Navigator.of(context).pop();
                },
                child: const Text('Accepter'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingConstroller());
    final dark = AlkHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Stack(
        children: [
          // Horizontal Scrollable page
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
                subtitle: AlkTexts.onBoardingSsubtitle2,
              ),
              onBoardingPage(
                image: AlkImages.onBoardingImage3,
                title: AlkTexts.onBoardingTitle1,
                subtitle: AlkTexts.onBoardingSsubtitle3,
              )
            ],
          ),
          // Skip button
          onBoardingSkip(),
          // Dot navigation smoothPageIndicator
          onBoardingIndicator(dark: dark),
          // Circular button
          onBoardingButtom(
            onComplete: () async {
              await controller.completeOnboarding(); // Mark onboarding as complete
              _showTermsDialog(context); // Show terms dialog after onboarding
            },
          ),
        ],
      ),
    );
  }
}

// ignore: camel_case_types
class onBoardingButtom extends StatelessWidget {
  final VoidCallback onComplete;

  const onBoardingButtom({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AlkSize.defaultSpace,
      bottom: AlkDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () {
          OnboardingConstroller.instance.nextPage();
          if (OnboardingConstroller.instance.isLastPage) {
            onComplete(); // Trigger the terms dialog when onboarding is complete
          }
        },
        style: ElevatedButton.styleFrom(shape: const CircleBorder()),
        child: const Icon(
          Iconsax.arrow_right_3,
          color: Colors.white,
        ),
      ),
    );
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
      bottom: AlkDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: AlkSize.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        count: 3,
        effect: ExpandingDotsEffect(
          activeDotColor: dark ? AlkColors.light : AlkColors.dark,
          dotHeight: 6,
        ),
      ),
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
        onPressed: () => OnboardingConstroller.instance.skipPage(),
        child: const Text('Skip'),
      ),
    );
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
