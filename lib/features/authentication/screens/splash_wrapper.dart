// lib/features/authentication/screens/splash_wrapper.dart
import 'package:flutter/material.dart';
import 'package:alkirtas/app.dart';
import 'package:alkirtas/features/shop/screens/splashscreen.dart';
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
import 'package:alkirtas/config/home_sections_config.dart';
import 'package:alkirtas/api/banner_api.dart';
import 'package:alkirtas/api/category_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  static List<String> preloadedBannerUrls = [];

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

      // Load sections and categories from server first (in parallel)
      print("⏳ Loading sections and categories from server...");
      final sectionsResult = getHomeSections();
      final categoriesResult = CategoryApi.fetchHomeCategories();

      final sections = await sectionsResult;
      await categoriesResult; // Just wait for it to cache

      print("✅ Sections loaded! Found ${sections.length} sections.");
      print("✅ Categories loaded!");

      // Collect all category IDs from sections and prioritize the FIRST section
      final List<int> priorityCategories = [];
      final Set<int> remainingCategories = {};

      // Get priority categories from the first section (if available)
      if (sections.isNotEmpty) {
        final firstSection = sections.first;
        for (var tab in firstSection.tabs) {
          priorityCategories.add(tab.categoryId);
        }
        print("🎯 Priority section: ${firstSection.title} with ${priorityCategories.length} categories");
      }

      // Collect remaining categories from other sections
      for (var i = 1; i < sections.length; i++) {
        for (var tab in sections[i].tabs) {
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

      // Prefetch banner images
      print("⏳ Fetching and prefetching banner images...");
      final bannerUrls = await BannerApi.fetchBannerUrls();
      await Future.wait(bannerUrls.map((url) => precacheImage(CachedNetworkImageProvider(url), context)));
      SplashWrapper.preloadedBannerUrls = bannerUrls;
      print("✅ Banner images prefetched!");

      // Set app as ready after priority categories and banners are loaded
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