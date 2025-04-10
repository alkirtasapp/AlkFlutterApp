// d:\flutter\test\lib\features\authentication\screens\splash_wrapper.dart (Modified for Preloading)
import 'package:alkirtas/features/shop/screens/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:alkirtas/app.dart';
// Removed: import 'package:alkirtas/features/shop/controllers/product_card_controller.dart'; // No longer preloading this
import 'package:alkirtas/features/shop/controllers/categories_store_controller.dart';
// Import the category product controller for static cache and preloading
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
// Import http and convert for fetching categories directly
import 'package:http/http.dart' as http;
import 'dart:convert';
// Removed: import 'package:alkirtas/features/shop/controllers/product_controller_store.dart'; // Not preloading store products here anymore unless needed
// Removed: import 'package:hive/hive.dart'; // Not using Hive cache for this preload

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

      // Clear the static cache in CategoryProductController on each app start
      CategoryProductController.clearCache();

      // --- Preload Categories for HomeScreen Carousels (level_depth=2) ---
      print("⏳ Preloading HomeScreen Categories (level_depth=2)...");
      List<dynamic> categoriesForCarousels = [];
      try {
        // API URL from HomeScreen
        const categoriesApiUrl =
            'https://www.alkirtas.com/api/categories?filter[level_depth]=2&filter[active]=1&display=[id,name]&sort=[id_ASC]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
        final response = await http.get(Uri.parse(categoriesApiUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          categoriesForCarousels = data['categories'] ?? [];
          print(
              "✅ HomeScreen Categories Preloaded (${categoriesForCarousels.length}).");
        } else {
          // Log error but continue preloading other things if possible
          print(
              "⚠️ Failed to preload HomeScreen categories (Status: ${response.statusCode})");
        }
      } catch (e) {
        // Log error but continue
        print("❌ Error preloading HomeScreen categories: $e");
      }

      // --- Preload Products for Fetched Categories + Promotions ---
      print("⏳ Preloading Products for Categories...");
      List<Future<void>> productPreloadTasks = [];
      final Set<int> categoryIdsToPreload = {};

      // Add IDs from fetched categories (excluding specified ones)
      final Set<int> excludedIds = {707, 711, 763}; // From HomeScreen
      for (var category in categoriesForCarousels) {
        if (category['id'] is int &&
            !excludedIds.contains(category['id'] as int)) {
          categoryIdsToPreload.add(category['id'] as int);
        }
      }

      // Add the Promotions category ID (hardcoded in HomeScreen)
      categoryIdsToPreload.add(15);

      print("   -> Will attempt to preload products for Category IDs: $categoryIdsToPreload");

      // Create tasks to fetch products for each category ID
      for (int catId in categoryIdsToPreload) {
        // Create a temporary controller instance just to trigger the static fetch
        // Use the limit defined in HomeScreen's AlkCategoryCarouselLayout (itemCount: 8)
        final controller = CategoryProductController(categoryId: catId, limit: 8);
        // Add the fetch future to the list of tasks
        productPreloadTasks.add(controller.fetchCategoryProducts());
      }

      // Wait for all product fetching tasks to complete (or fail individually)
      // Use Future.wait with eagerError: false to allow successful preloads even if some fail
      await Future.wait(productPreloadTasks, eagerError: false);
      print(
          "✅ Product Preloading Tasks Initiated/Completed (check logs for individual results).");


      // --- Preload AlkHomeCategories Data (Optional - if needed/possible) ---
      // This depends on how AlkHomeCategories fetches its data. If it uses a
      // controller with a static cache similar to CategoryProductController,
      // you could trigger its preload here. Otherwise, it might load on demand.
      // print("⏳ Preloading AlkHomeCategories Data (if applicable)...");
      // Example:
      // final homeCategoriesController = AlkHomeCategoriesController(); // Assuming it exists
      // await homeCategoriesController.fetchData();
      // print("✅ AlkHomeCategories Data Preloaded (if applicable).");


      // --- Preload Categories for StoreDrawer (if needed) ---
      // This was previously done, keep it if StoreDrawer relies on it being ready.
      print("⏳ Preloading Categories for StoreDrawer...");
      final categoriesController = CategoriesStoreController();
      await categoriesController.fetchAllCategories();
      print("✅ StoreDrawer Categories Preloaded.");


      // Optional delay for splash screen visibility
      // await Future.delayed(const Duration(milliseconds: 300));

      print("👍 Preload Complete. App is Ready!");
      if (mounted) {
        setState(() => isReady = true);
      }
    } catch (e, stackTrace) {
      print("❌❌ FATAL Error during app preload: $e");
      print("   StackTrace: $stackTrace");
      // Handle fatal preload errors - maybe show an error screen or retry?
      // For now, we still proceed to the app.
      if (mounted) {
        setState(() => isReady = true); // Proceed even on error for now
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isReady
          ? const App() // Show the main app
          : const MaterialApp( // Show splash screen
              key: ValueKey('SplashScreen'),
              home: SplashScreen(),
              debugShowCheckedModeBanner: false,
            ),
    );
  }
}
