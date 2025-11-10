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

class NavigationMenu extends StatefulWidget {
  /// the index of the selected tab
  final int selectedMenu;
  const NavigationMenu({super.key, this.selectedMenu = 0});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure ProductProvider is available globally for GetX navigation
    if (!Get.isRegistered<ProductProvider>()) {
      Get.put(ProductProvider(), permanent: true);
    }
    // Initialize NavigationController with selectedMenu
    final controller = Get.put(NavigationController(widget.selectedMenu));
    final darkMode = AlkHelperFunctions.isDarkMode(context);

    // Use WillPopScope to handle back button press
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: WillPopScope(
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

  // Using a getter instead of final field to ensure proper initialization
  List<Widget> get screens => [
     HomeScreen(),
    Obx(() => ChangeNotifierProvider(
          create: (_) => StoreController(),
          child: StoreDrawer(
            initialCategoryId: initialCategoryId.value,
            initialCategoryName: initialCategoryName.value,
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
