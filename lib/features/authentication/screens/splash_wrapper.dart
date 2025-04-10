import 'package:alkirtas/features/shop/screens/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:alkirtas/app.dart';
import 'package:alkirtas/features/shop/controllers/product_card_controller.dart';
import 'package:alkirtas/features/shop/controllers/categories_store_controller.dart';
// Import the store product controller
import 'package:alkirtas/features/shop/controllers/product_controller_store.dart';
import 'package:hive/hive.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}


class _SplashWrapperState extends State<SplashWrapper> {
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    preloadAppData();
  }

  Future<void> preloadAppData() async {
    try {
      print("🚀 Starting App Preload...");
      // Note: Cache clearing is also done in main.dart, might be redundant here
      // but keeping it for explicitness during preload phase.
      final box = await Hive.openBox('productCache');
      // await box.clear(); // Consider if clearing here AND in main.dart is needed.
      // print("🧹 Product cache cleared during preload (if not already cleared in main).");

      // --- Preload Categories First (Needed for Store Controller) ---
      print("⏳ Preloading Categories...");
      final categoriesController = CategoriesStoreController();
      await categoriesController.fetchAllCategories();
      print("✅ Categories Preloaded.");

      // --- Preload Product Card Data (for Home Screen Carousels, if applicable) ---
      print("⏳ Preloading Product Card Data (Tax)...");
      final productControllerTax = ProductCardControllerTax();
      // Fetching index 0 is likely for the first item in a carousel or initial view
      await productControllerTax.fetchProductData(0);
      print("✅ Product Card Data Preloaded.");


      // --- Preload Initial Store Products (for StoreDrawer) ---
      print("⏳ Preloading Initial Store Products...");
      final storeProductController = ProductControllerStore();
      // Check if categories were loaded successfully and get the first main category ID
      if (categoriesController.mainCategories.isNotEmpty) {
        // Determine the default category ID StoreDrawer would use
        final int firstCategoryId = categoriesController.mainCategories.values.first;
        final int initialLimit = 10; // Match the limit used in StoreDrawer's initial fetch
        final int initialOffset = 0; // Match the offset used in StoreDrawer's initial fetch

        print("   -> Fetching initial products for Category ID: $firstCategoryId (Offset: $initialOffset, Limit: $initialLimit)");
        // Fetch the first 'page' of products for the default category
        await storeProductController.fetchProductDataStore(firstCategoryId, initialOffset, initialLimit);
        // The result is automatically cached by fetchProductDataStore if successful
        print("✅ Initial Store Products Preloaded (and cached) for Category ID: $firstCategoryId.");
      } else {
        print("⚠️ Could not preload store products: No categories found.");
      }

      // Optional: Add a small delay for splash screen visibility if desired
      // await Future.delayed(const Duration(milliseconds: 300));

      print("👍 Preload Complete. App is Ready!");
      if (mounted) { // Check if the widget is still in the tree before calling setState
         setState(() => isReady = true);
      }

    } catch (e, stackTrace) {
       print("❌ Error during app preload: $e");
       print("   StackTrace: $stackTrace");
       // Decide how to handle preload errors. Maybe still proceed?
       // Or show an error message on the splash screen.
       if (mounted) {
          // Potentially show an error state or just proceed
          setState(() => isReady = true);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedSwitcher for a smoother transition (optional)
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500), // Adjust duration as needed
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Example: Fade transition
        return FadeTransition(opacity: animation, child: child);
      },
      child: isReady
          ? const App() // Show the main app when ready
          : const MaterialApp( // Show the splash screen while loading
              // Use a key to ensure the SplashScreen widget itself doesn't persist
              // if you want animations within SplashScreen to reset if preload fails/retries.
              key: ValueKey('SplashScreen'),
              home: SplashScreen(),
              debugShowCheckedModeBanner: false,
            ),
    );
  }
}
