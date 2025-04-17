// lib/features/authentication/screens/splash_wrapper.dart
import 'package:flutter/material.dart';
import 'package:alkirtas/app.dart';
import 'package:alkirtas/features/shop/screens/splashscreen.dart';
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
import 'package:alkirtas/config/home_sections_config.dart';

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

      // Clear the static cache
      CategoryProductController.clearCache();

      // Collect all category IDs from sections and prioritize them
      final List<int> priorityCategories = [13,14, 15,]; // Books categories (most important)
      final Set<int> remainingCategories = {};
      
      for (var section in homeSections) {
        for (var tab in section.tabs) {
          if (!priorityCategories.contains(tab.categoryId)) {
            remainingCategories.add(tab.categoryId);
          }
        }
      }

      print("⏳ Preloading priority categories first: $priorityCategories");
      
      // Load priority categories first
      List<Future<void>> priorityPreloadTasks = priorityCategories.map((catId) {
        final controller = CategoryProductController(categoryId: catId, limit: 8);
        return controller.fetchCategoryProducts();
      }).toList();

      // Wait only for priority categories
      await Future.wait(priorityPreloadTasks, eagerError: false);
      
      print("✅ Priority categories preloaded!");

      // Set app as ready after priority categories are loaded
      if (mounted) {
        setState(() => isReady = true);
      }

      // Load remaining categories in the background
      print("🔄 Loading remaining categories in background: $remainingCategories");
      for (var catId in remainingCategories) {
        final controller = CategoryProductController(categoryId: catId, limit: 8);
        controller.fetchCategoryProducts().then((_) {
          print("✅ Background loaded category: $catId");
        }).catchError((e) {
          print("⚠️ Error loading category $catId in background: $e");
        });
      }

    } catch (e, stackTrace) {
      print("❌ Error during app preload: $e");
      print("   StackTrace: $stackTrace");
      if (mounted) {
        setState(() => isReady = true);
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
          ? const App()
          : const MaterialApp(
              key: ValueKey('SplashScreen'),
              home: SplashScreen(),
              debugShowCheckedModeBanner: false,
            ),
    );
  }
}