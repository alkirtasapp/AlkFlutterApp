import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/providers/product_provider.dart'; 
import 'package:test/features/authentication/screens/home/home.dart';
import 'package:test/features/personalization/screens/settings/settings.dart';
import 'package:test/features/shop/screens/cart/cart.dart';
import 'package:test/features/shop/screens/store/storedrawer.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    //  Ensure ProductProvider is available globally for GetX navigation
    if (!Get.isRegistered<ProductProvider>()) {
      Get.put(ProductProvider(), permanent: true);
    }
    //  Initialize NavigationController
    final controller = Get.put(NavigationController());
    final darkMode = AlkHelperFunctions.isDarkMode(context);
    //  Use WillPopScope to handle back button press
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Quitter l\'application'),
              content: Text('Voulez-vous vraiment quitter l\'application?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Non'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Oui'),
                ),
              ],
            );
          },
        );
        return shouldPop ?? false;
      },
      //  Scaffold with NavigationBar and screens
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => NavigationBar(
            height: 80,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) => controller.selectedIndex.value = index,
            backgroundColor: darkMode ? AlkColors.black : Colors.white,
            indicatorColor: darkMode ? AlkColors.white.withOpacity(0.1) : AlkColors.black.withOpacity(0.1),
            destinations: [
              const NavigationDestination(icon: Icon(Iconsax.home), label: 'Acceuil'),
              const NavigationDestination(icon: Icon(Iconsax.shop), label: 'Boutique'),
              const NavigationDestination(icon: Icon(Iconsax.shopping_cart), label: 'Panier'),
              const NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
            ],
          ),
        ),
        body: Obx(() => controller.screens[controller.selectedIndex.value]),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    const HomeScreen(),
    const StoreDrawer(),
    //  Cart now has access to ProductProvider
    const CartScreen(), 
    const SettingScreen(),
  ];
}

/// 1.  Import the required packages
/// 2.  This widget is used to create the navigation menu with a bottom navigation bar with 4 Main screens (Acceuil, Boutique, Panier, Profile)
      /// these 4 section are the main sections of the app
/// 3.  Initialize the ProductProvider globally for GetX navigation
/// 4.  Initialize the NavigationController
/// 5.  Use WillPopScope to handle back button press
/// 6.  Scaffold with NavigationBar and screens
