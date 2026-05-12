import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/common/widgets/global_floating_home_button.dart';
import 'package:alkirtas/features/authentication/screens/home/home.dart';
import 'package:alkirtas/features/personalization/screens/settings/settings.dart';
import 'package:alkirtas/features/shop/screens/cart/cart.dart';
import 'package:alkirtas/features/shop/screens/store/storedrawer.dart';
import 'package:alkirtas/features/shop/screens/store/controllers/store_controller.dart';
import 'package:alkirtas/features/shop/screens/categories/categories_menu_screen.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alkirtas/services/app_update_service.dart';
import 'package:alkirtas/providers/wishlist_provider.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/features/scratch_card/scratch_card_screen.dart';
import 'package:alkirtas/services/device_uuid_service.dart';

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

    // Check for app updates from Google Play
    AppUpdateService.checkForUpdate();

    // Initialize GlobalFabService
    Get.put(GlobalFabService());

    // Set up notification tap → navigate to product
    WishlistProvider.onNotificationTap = (productId) => _navigateToProduct(productId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check price drops + stock comebacks silently on every app open
      Provider.of<WishlistProvider>(context, listen: false).checkUpdates();

      // Handle tap when app was fully terminated
      final launchDetails = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _navigateToProduct(payload);
        }
      }

      // Show scratch card dialog on first install (once per device)
      _checkAndShowScratchCard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToProduct(String productId) async {
    final id = int.tryParse(productId) ?? 0;
    if (id <= 0) return;

    final enrichedMap = await ProductEnrichedService.fetchEnrichedByIds([id]);
    final enriched = enrichedMap[id];
    if (enriched == null) return;

    final product = ProductEnrichedService.buildProductFromEnriched(enriched);

    final taxGroup = (product['id_tax_rules_group'] as int?) ?? 0;
    final basePrice = taxGroup == 0
        ? (product['price'] as double? ?? 0.0)
        : (product['ttc_price'] as double? ?? 0.0);
    final discount = (product['discount'] as double? ?? 0.0);
    final discountText = discount > 0 ? '${discount.toStringAsFixed(0)}%' : '';
    final newPrice = discount > 0
        ? (basePrice * (1 - discount / 100)).toStringAsFixed(2)
        : basePrice.toStringAsFixed(2);
    final oldPrice = discount > 0 ? basePrice.toStringAsFixed(2) : '';

    final imageUrls = (product['image_urls'] as List<String>?) ?? [];
    final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

    Get.to(() => ProductDetails(
          productId: productId,
          productName: (product['name'] as String?) ?? '',
          productReference: (product['reference'] as String?) ?? '',
          productDiscount: discountText,
          productBrand: (product['manufacturer_name'] as String?) ?? '',
          productBrandId: ((product['id_manufacturer'] as int?) ?? 0).toString(),
          productOldPrice: oldPrice,
          productNewPrice: newPrice,
          productDescription: (product['description_short'] as String?) ?? '',
          productImage: imageUrl,
          productImageList: imageUrls,
          productStock: ((product['quantity'] as int?) ?? 0).toString(),
        ));
  }

  Future<void> _checkAndShowScratchCard() async {
    try {
      // Guests can't claim — wait until they log in (the login flow Get.offAll's
      // back to NavigationMenu, which re-runs initState and re-triggers this).
      if (UserData.id.isEmpty) return;

      final uuid = await DeviceUuidService.getOrCreate();
      final alreadyClaimed = await ProductEnrichedService.checkScratchClaim(
        uuid,
        email: UserData.email,
      );
      if (alreadyClaimed) return;

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      await showScratchCardDialog(
        context,
        uuid: uuid,
        onClaim: (rewardLabel) => ProductEnrichedService.claimScratch(
          uuid: uuid,
          reward: rewardLabel,
          email: UserData.email,
        ),
      );
    } catch (_) {
      // Non-critical — never crash the app over a scratch card
    }
  }

  void _onNavDestinationSelected(int navIdx) {
    if (navIdx == 2 || navIdx == 3) {
      if (UserData.id.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Connexion requise'),
            content: const Text('Vous devez être connecté pour accéder à cette fonctionnalité.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                
                style: ElevatedButton.styleFrom(backgroundColor: AlkColors.AppFirstColor , padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Get.to(() => LoginScreen());
                },
                child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }
    }
    Get.find<NavigationController>().onNavDestinationSelected(navIdx);
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
          child: ResponsiveGlobalFab(
            forceShow: true, // Show on main navigation screens
            child: Scaffold(
              bottomNavigationBar: Obx(
                () => NavigationBar(
                  height: 80,
                  elevation: 0,
                  selectedIndex: controller.navIndex.value,
                  onDestinationSelected: _onNavDestinationSelected,
                  backgroundColor: darkMode ? AlkColors.black : Colors.white,
                  indicatorColor: darkMode
                      ? AlkColors.white.withOpacity(0.1)
                      : AlkColors.black.withOpacity(0.1),
                  // 4 visible tabs - Home is hidden (accessed via FAB)
                  destinations: const [
                    NavigationDestination(icon: Icon(Iconsax.menu_1), label: 'Menu'),
                    NavigationDestination(icon: Icon(Iconsax.shop), label: 'Boutique'),
                    NavigationDestination(icon: Icon(Iconsax.shopping_cart), label: 'Panier'),
                    NavigationDestination(icon: Icon(Iconsax.user), label: 'Profil'),
                  ],
                ),
              ),
              body: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: controller.screens,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  // Nav bar index (0-3): Menu, Boutique, Cart, Profile
  final Rx<int> navIndex;
  // Page index (0-4): Home, Menu, Boutique, Cart, Profile
  final Rx<int> pageIndex;
  final PageController pageController;
  // Track if we're on Home screen
  final Rx<bool> isOnHome = false.obs;

  // StoreDrawer parameters
  final Rx<int?> initialCategoryId = Rx<int?>(null);
  final Rx<String?> initialCategoryName = Rx<String?>(null);
  final RxList<String> initialBreadcrumb = <String>[].obs;
  final Rx<String?> initialSearchQuery = Rx<String?>(null);

  NavigationController(int initialPageIndex)
      : pageIndex = initialPageIndex.obs,
        // If starting on Home (0), nav shows Menu (0). Otherwise nav = page - 1
        navIndex = (initialPageIndex == 0 ? 0 : initialPageIndex - 1).obs,
        pageController = PageController(initialPage: initialPageIndex) {
    isOnHome.value = initialPageIndex == 0;
  }

  // For backward compatibility
  Rx<int> get selectedIndex => navIndex;

  // Screens: Page 0 = Home, Pages 1-4 = Nav tabs
  List<Widget> get screens => [
    const HomeScreen(),           // Page 0 (hidden from nav, accessed via FAB)
    const CategoriesMenuScreen(), // Page 1 = Nav 0 (Menu)
    Obx(() => ChangeNotifierProvider(
          create: (_) => StoreController(),
          child: StoreDrawer(
            initialCategoryId: initialCategoryId.value,
            initialCategoryName: initialCategoryName.value,
            initialBreadcrumb: initialBreadcrumb.toList(),
            initialSearchQuery: initialSearchQuery.value,
          ),
        )),                        // Page 2 = Nav 1 (Boutique)
    const CartScreen(),           // Page 3 = Nav 2 (Cart)
    const SettingScreen(),        // Page 4 = Nav 3 (Profile)
  ];

  /// Called when nav destination is tapped (index 0-3)
  void onNavDestinationSelected(int navIdx) {
    navIndex.value = navIdx;
    pageIndex.value = navIdx + 1; // Nav 0 = Page 1, Nav 1 = Page 2, etc.
    pageController.jumpToPage(navIdx + 1);
    isOnHome.value = false;
  }

  /// Called when page changes via swipe
  void onPageChanged(int newPageIndex) {
    pageIndex.value = newPageIndex;
    if (newPageIndex == 0) {
      isOnHome.value = true;
      // Keep last nav selection when on Home
    } else {
      isOnHome.value = false;
      navIndex.value = newPageIndex - 1;
    }
  }

  /// Navigate to Home (page 0) via FAB
  void navigateToHome() {
    pageIndex.value = 0;
    pageController.jumpToPage(0);
    isOnHome.value = true;
  }

  void navigateToStoreDrawer({int? categoryId, String? categoryName, List<String>? breadcrumb, String? searchQuery}) {
    initialCategoryId.value = categoryId;
    initialCategoryName.value = categoryName;
    initialBreadcrumb.value = breadcrumb ?? [];
    initialSearchQuery.value = searchQuery;
    navIndex.value = 1; // Boutique in nav
    pageIndex.value = 2; // Page 2
    pageController.jumpToPage(2);
    isOnHome.value = false;
  }

  /// Navigate to store tab without specific category
  void navigateToStore() {
    navIndex.value = 1;
    pageIndex.value = 2;
    pageController.jumpToPage(2);
    isOnHome.value = false;
    initialCategoryId.value = null;
    initialCategoryName.value = null;
  }

  /// Navigate to menu tab (categories)
  void navigateToMenu() {
    navIndex.value = 0;
    pageIndex.value = 1;
    pageController.jumpToPage(1);
    isOnHome.value = false;
  }

  /// Navigate to cart tab
  void navigateToCart() {
    navIndex.value = 2;
    pageIndex.value = 3;
    pageController.jumpToPage(3);
    isOnHome.value = false;
  }

  /// Navigate to settings tab
  void navigateToSettings() {
    navIndex.value = 3;
    pageIndex.value = 4;
    pageController.jumpToPage(4);
    isOnHome.value = false;
  }

  /// Get current tab name in French
  String getCurrentTabName() {
    if (isOnHome.value) return 'Accueil';
    switch (navIndex.value) {
      case 0:
        return 'Menu';
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

  bool isOnMenuTab() => navIndex.value == 0 && !isOnHome.value;
  bool isOnStoreTab() => navIndex.value == 1 && !isOnHome.value;
  bool isOnHomeScreen() => isOnHome.value;

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
