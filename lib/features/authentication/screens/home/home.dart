// d:\flutter\test\lib\features\authentication\screens\home\home.dart (Updated with Navigation)
import 'package:alkirtas/common/widgets/custom_shapes/containers/second_header_container.dart';
import 'package:alkirtas/common/widgets/layout/category_carousel_layout.dart'; // Import NEW layout
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/size.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/custom_shapes/containers/searchContainer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../navigation_menu.dart'; // Import NavigationMenu to access NavigationController
import 'widgets/bannerSlider.dart';
import 'widgets/homeAppBar.dart';
import 'widgets/homeCategories.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _categoriesForCarousels = [];
  bool _isLoadingCategories = true;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesForCarousels();
  }

  // Fetch categories specifically for the carousels (level_depth=2)
  Future<void> _fetchCategoriesForCarousels() async {
    // Using the API URL provided in the last snippet for home.dart
    const apiUrl =
        'https://www.alkirtas.com/api/categories?filter[level_depth]=2&filter[active]=1&display=[id,name]&sort=[id_ASC]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categoriesForCarousels = data['categories'] ?? [];
            _isLoadingCategories = false;
            _categoryError = null;
            print(
                "Fetched ${_categoriesForCarousels.length} categories for carousels.");
          });
        }
      } else {
        throw Exception(
            'Failed to load categories (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching categories for carousels: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _categoryError = 'Could not load categories: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header ---
            AlkPrimaryHeaderContainer(
              child: Column(
                children: [
                  const AlkHomeAppBar(showCartIcon: true),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  AlkSearchContainer(
                      text: 'Découvrir ma boutique',
                      icon: Iconsax.search_normal,
                      onPressed: () =>
                          Get.offAll(() => const NavigationMenu(selectedMenu: 1))),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  Padding(
                    padding: const EdgeInsets.only(left: AlkSize.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AlkSectionHeading(
                            title: 'Nos Catégories : ',
                            textColor: Colors.white,
                            showActionButton: false),
                        const SizedBox(height: AlkSize.spaceBtwItems / 2),
                        // This AlkHomeCategories fetches its own list for the horizontal scroll
                        const AlkHomeCategories(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections * 1.2),
                ],
              ),
            ),

            // --- Body ---
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 0), // Vertical padding for body sections
              child: Column(
                children: [
                  // --- Banner Slider ---
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm), // Add horizontal padding
                      child: const AlkBannerSlider()),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // --- Dynamic Product Carousels based on Categories ---
                  _buildProductCarousels(), // Build carousels dynamically

                  // --- Example: Static Section (like Promotions in a container) ---
                  // You might want a specific category ID for promotions
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  AlkSecondHeaderContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AlkSize.defaultSpace),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AlkSectionHeading(
                              title: 'Promotions : ', // Example Title
                              textColor: Colors.white,
                              // Keep false or implement specific navigation for promotions
                              showActionButton: false
                          ),
                          const SizedBox(height: AlkSize.spaceBtwItems / 1.5),
                          // Use the NEW AlkCategoryCarouselLayout here as well
                          AlkCategoryCarouselLayout(
                            categoryId: 15, 
                            itemCount: 8,
                            productsPerPage: 0, // Show 1 product per page for promotions
                            horizontalPadding: 12.0,
                            verticalPadding: 10.0,
                            autoSwipeDuration: const Duration(milliseconds: 4500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections * 2), // Add more space at the end
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the dynamic carousels with exclusions and navigation
  Widget _buildProductCarousels() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoryError != null) {
      return Center(
          child: Text(_categoryError!, style: const TextStyle(color: Colors.red)));
    }

    if (_categoriesForCarousels.isEmpty) {
      return const Center(child: Text('No categories found to display products.'));
    }

    // Define the set of category IDs to exclude
    final Set<int> excludedIds = {707, 711, 763}; // IDs to exclude

    // Build a list of Widgets (Section Heading + Carousel) for each category
    return Column(
      children: _categoriesForCarousels.map((category) {
        final categoryId = category['id'];
        final categoryName = category['name'] ?? 'Unnamed Category';

        // Basic validation for category ID type
        if (categoryId is! int) {
          print("Skipping category due to invalid ID type: $category");
          return const SizedBox.shrink(); // Skip if ID is not valid
        }

        // *** Check if the current category ID is in the exclusion list ***
        if (excludedIds.contains(categoryId)) {
          print("Skipping excluded category ID: $categoryId ($categoryName)");
          return const SizedBox.shrink(); // Return an empty widget to exclude it
        }

        // If not excluded, build the category section
        return Padding(
          // Add padding around each category section
          padding: const EdgeInsets.only(bottom: AlkSize.spaceBtwSections ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Heading for the Category
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AlkSize.sm), // Padding for heading
                child: AlkSectionHeading(
                  title: '$categoryName :', // Use category name
                  showActionButton: true, // *** Enable the action button ***
                  buttonTitle: 'Voir tout', // Text for the button
                  // *** Add the onPressed callback for navigation ***
                  onPressed: () {
                    // Find the NavigationController instance using GetX
                    final navCtrl = Get.find<NavigationController>();
                    // Call the navigation method with the current category's details
                    navCtrl.navigateToStoreDrawer(
                      categoryId: categoryId,
                      categoryName: categoryName,
                    );
                  },
                ),
              ),
              const SizedBox(height: AlkSize.spaceBtwItems), // Space between heading and carousel

              // Product Carousel for the Category
              AlkCategoryCarouselLayout(
                key: ValueKey(categoryId), // Add key for state preservation if needed
                categoryId: categoryId,
                itemCount: 8, // Max products to fetch/show per category
                productsPerPage: 2, // Show 2 products per page
                horizontalPadding: 12.0,
                verticalPadding: 8.0,
                autoSwipeDuration: Duration(
                    milliseconds: 5000 +
                        (categoryId % 5 * 900)), // Vary swipe duration slightly
              ),
            ],
          ),
        );
      }).toList(), // Convert map result to a list of widgets
    );
  }
}
