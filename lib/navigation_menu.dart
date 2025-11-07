import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/features/authentication/screens/home/home.dart';
import 'package:alkirtas/features/personalization/screens/settings/settings.dart';
import 'package:alkirtas/features/shop/screens/cart/cart.dart';
import 'package:alkirtas/features/shop/screens/store/storedrawer.dart';
import 'package:alkirtas/features/shop/screens/store/controllers/store_controller.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  /// the index of the selected tab
  final int selectedMenu;
  const NavigationMenu({super.key, this.selectedMenu = 0});

  @override
  Widget build(BuildContext context) {
    // Ensure ProductProvider is available globally for GetX navigation
    if (!Get.isRegistered<ProductProvider>()) {
      Get.put(ProductProvider(), permanent: true);
    }
    // Initialize NavigationController with selectedMenu
    final controller = Get.put(NavigationController(selectedMenu));
    final darkMode = AlkHelperFunctions.isDarkMode(context);

    // Use WillPopScope to handle back button press
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Quitter l\'application'),
              content: const Text('Voulez-vous vraiment quitter l\'application?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Oui'),
                ),
              ],
            );
          },
        );
        return shouldPop ?? false;
      },
      // Scaffold with NavigationBar and screens
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => NavigationBar(
            height: 80,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) {
              controller.pageController.jumpToPage(index); // Navigate to the selected page
              controller.selectedIndex.value = index;
            },
            backgroundColor: darkMode ? AlkColors.black : Colors.white,
            indicatorColor: darkMode
                ? AlkColors.white.withOpacity(0.1)
                : AlkColors.black.withOpacity(0.1),
            destinations: const [
              NavigationDestination(icon: Icon(Iconsax.home), label: 'Acceuil'),
              NavigationDestination(icon: Icon(Iconsax.shop), label: 'Boutique'),
              NavigationDestination(icon: Icon(Iconsax.shopping_cart), label: 'Panier'),
              NavigationDestination(icon: Icon(Iconsax.user), label: 'Profil'),
            //  NavigationDestination(icon: Icon(Iconsax.star_1), label: 'PROMOS'),
            ],
          ),
        ),
        body: PageView(
          controller: controller.pageController,
          onPageChanged: (index) {
            controller.selectedIndex.value = index; // Update the selected index
          },
          children: controller.screens,
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex;
  final PageController pageController;

  // StoreDrawer parameters
  final Rx<int?> initialCategoryId = Rx<int?>(null);
  final Rx<String?> initialCategoryName = Rx<String?>(null);

  NavigationController(int initialIndex)
      : selectedIndex = initialIndex.obs,
        pageController = PageController(initialPage: initialIndex);

  final screens = [
     HomeScreen(),
    Obx(() => ChangeNotifierProvider(
          create: (_) => StoreController(),
          child: StoreDrawer(
            initialCategoryId: Get.find<NavigationController>().initialCategoryId.value,
            initialCategoryName: Get.find<NavigationController>().initialCategoryName.value,
          ),
        )),
    const CartScreen(),
    const SettingScreen(),
  ];

  void navigateToStoreDrawer({int? categoryId, String? categoryName}) {
    initialCategoryId.value = categoryId;
    initialCategoryName.value = categoryName;
    selectedIndex.value = 1; // Switch to the StoreDrawer tab
    pageController.jumpToPage(1);
  }

  /// Navigate to store tab without specific category (for product search)
  void navigateToStore() {
    selectedIndex.value = 1; // Switch to the StoreDrawer tab
    pageController.jumpToPage(1);
    // Clear any existing category filter
    initialCategoryId.value = null;
    initialCategoryName.value = null;
  }

  /// Navigate to home tab
  void navigateToHome() {
    selectedIndex.value = 0;
    pageController.jumpToPage(0);
  }

  /// Navigate to cart tab
  void navigateToCart() {
    selectedIndex.value = 2;
    pageController.jumpToPage(2);
  }

  /// Navigate to settings tab
  void navigateToSettings() {
    selectedIndex.value = 3;
    pageController.jumpToPage(3);
  }

  /// Get current tab name in French
  String getCurrentTabName() {
    switch (selectedIndex.value) {
      case 0:
        return 'Accueil';
      case 1:
        return 'Boutique';
      case 2:
        return 'Panier';
      case 3:
        return 'Profil';
      default:
        return 'Inconnu';
    }
  }

  /// Check if currently on store tab
  bool isOnStoreTab() {
    return selectedIndex.value == 1;
  }

  /// Get current category info
  Map<String, dynamic> getCurrentCategoryInfo() {
    return {
      'id': initialCategoryId.value,
      'name': initialCategoryName.value,
      'isSet': initialCategoryId.value != null,
    };
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
