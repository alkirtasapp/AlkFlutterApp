import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
    final controller =Get.put(NavigationController()); 
    final darkMode = AlkHelperFunctions.isDarkMode(context);

    return Scaffold(
        bottomNavigationBar: Obx(
          ()=> NavigationBar(
              height: 80,
              elevation: 0, 
              selectedIndex: controller.selectedIndex.value ,
              onDestinationSelected: (index) =>controller.selectedIndex.value = index,
              backgroundColor: darkMode ?AlkColors.black : Colors.white ,
              indicatorColor: darkMode ?AlkColors.white.withOpacity(0.1): AlkColors.black.withOpacity(0.1),
          
              destinations: [
                  const NavigationDestination(icon: Icon(Iconsax.home), label: 'Acceuil'),
                  const NavigationDestination(icon: Icon(Iconsax.shop), label: 'Boutique'),
                  const NavigationDestination(icon: Icon(Iconsax.shopping_cart), label: 'Panier'),
                  const NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
              ],
          ),
        ),
        body: Obx(()=> controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
    final Rx<int> selectedIndex  = 0.obs;
    final screens =[ const HomeScreen(),const StoreDrawer(),const CartScreen(),SettingScreen(),];
}
