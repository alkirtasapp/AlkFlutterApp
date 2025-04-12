import 'package:alkirtas/common/widgets/custom_shapes/containers/second_header_container.dart';
import 'package:alkirtas/common/widgets/layout/category_carousel_layout.dart';
import 'package:alkirtas/common/widgets/layout/category_product_grid_layout.dart';
import 'package:alkirtas/features/authentication/screens/home/widgets/top_sales_books.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/custom_shapes/containers/searchContainer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../navigation_menu.dart'; 
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

  // --- Define Category IDs ---
  // !!! IMPORTANT: Replace these with your actual Prestashop Category IDs !!!
  static const int livresCategoryId = 10; // Example ID for "Livres"
  static const int topSellingBooksCategoryId = 20; // Example ID for "Top Selling Books" (Content for Livres Grid)
  static const int topPromotionsCategoryId =  544 ; // ID for "Offres Spéciales" (Triggers the special grid/carousel)
  static const int bestOffersContentCategoryId = 545; // Example ID for "Best Offers" (Content for Promotions section)

  @override
  void initState() {
    super.initState();
    _fetchCategoriesForCarousels();
    // Consider preloading for topSellingBooksCategoryId, topPromotionsCategoryId, bestOffersContentCategoryId in SplashWrapper
  }

  // Fetch categories specifically for the carousels (level_depth=2)
  Future<void> _fetchCategoriesForCarousels() async {
    if (mounted) {
      setState(() { _isLoadingCategories = true; _categoryError = null; });
    }
    // Fetch categories sorted by ID ascending to maintain a consistent order
    const apiUrl =
        'https://www.alkirtas.com/api/categories?filter[level_depth]=2&filter[active]=1&display=[id,name]&sort=[id_ASC]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categoriesForCarousels = data['categories'] ?? [];
            _isLoadingCategories = false; _categoryError = null;
            print("Fetched ${_categoriesForCarousels.length} categories for carousels.");
          });
        }
      } else { throw Exception('Failed to load categories (Status Code: ${response.statusCode})'); }
    } catch (e) {
      print('Error fetching categories for carousels: $e');
      if (mounted) { setState(() { _isLoadingCategories = false; _categoryError = 'Could not load categories: $e'; }); }
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
                      onPressed: () => Get.offAll(() => const NavigationMenu(selectedMenu: 1))),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  Padding(
                    padding: const EdgeInsets.only(left: AlkSize.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AlkSectionHeading(title: 'Nos Catégories : ', textColor: Colors.white, showActionButton: false),
                        const SizedBox(height: AlkSize.spaceBtwItems / 2),
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
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  // --- Banner Slider ---
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm), 
                      child: const AlkBannerSlider()),
                  

                  // --- Dynamic Product Carousels/Grids ---
                  _buildProductCarousels(), // This builds all category sections


                  const SizedBox(height: AlkSize.spaceBtwSections), // Space at the very bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the dynamic carousels with exclusions and special sections
  Widget _buildProductCarousels() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_categoryError != null) {
      return Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Center(child: Text(_categoryError!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (_categoriesForCarousels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AlkSize.defaultSpace),
        child: Center(child: Text('No categories found to display products.')),
      );
    }

    final Set<int> excludedIds = {707, 711, 763, 638, 17}; // IDs to exclude (Added 638 from context)


    // Map each category to its corresponding widget section
    return Column(
      children: _categoriesForCarousels.map((category) {
        final categoryId = category['id'];
        final categoryName = category['name'] ?? 'Unnamed Category';

        // Skip excluded or invalid categories
        if (categoryId is! int || excludedIds.contains(categoryId)) {
          return const SizedBox.shrink();
        }

        // --- Build the list of widgets for this category section ---
        List<Widget> categorySectionWidgets = [
          // Section Heading for the Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
            child: AlkSectionHeading(
              title: '$categoryName :',
              showActionButton: true,
              buttonTitle: 'Voir tout',
              onPressed: () {
                final navCtrl = Get.find<NavigationController>();
                navCtrl.navigateToStoreDrawer(
                    categoryId: categoryId, categoryName: categoryName);
              },
            ),
          ),
          const SizedBox(height: AlkSize.spaceBtwItems),
          // Product Carousel for the Category
          AlkCategoryCarouselLayout(
            key: ValueKey(categoryId),
            categoryId: categoryId,
            itemCount: 8, // Fetch up to 8 products
            productsPerPage: 2, // Show 2 per page view for standard carousels
            horizontalPadding: 4.0, // Padding between items for standard carousels
            verticalPadding: 8.0,
            autoSwipeDuration: Duration(milliseconds: 5000 + (categoryId % 5 * 900)),
          ),
        ];

        //  Add Special Grid Section if it's the "Livres" category
        if (categoryId == livresCategoryId) {
          categorySectionWidgets.add(
            // Add spacing BEFORE the styled container
            const SizedBox(height: AlkSize.spaceBtwSections * 0.8),
          );
          categorySectionWidgets.add(
            // *** Styled Container for Top Selling Books with Purple Gradient ***
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AlkSize.sm), // Margin around the container
              padding: const EdgeInsets.only( // Adjusted padding
                top: AlkSize.md,
                left: AlkSize.md,
                right: AlkSize.md,
                bottom: AlkSize.lg,
              ),
              decoration: BoxDecoration(
                // *** Apply Purple Gradient ***
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.deepPurple.shade400], // Lighter purples for light mode
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.2, 0.8], // Adjusted stops for a smoother gradient
                ),
                borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg), // Keep rounded corners
                boxShadow: [ // Keep shadow for depth
                  BoxShadow(
                    color:  AlkColors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading for Top Selling Books (Inside the container)
                  AlkSectionHeading(
                    icon: const Icon(Iconsax.ranking_1, color: AlkColors.white), // Optional icon
                    title: '  Livres les plus vendus ',
                    textColor: AlkColors.white, // White contrasts well with purple
                    showActionButton: false, // No "Voir tout" for this specific grid
                  ),
                  Divider( // Divider
                    color: AlkColors.white.withOpacity(0.4), // White with opacity
                    height: AlkSize.spaceBtwSections * 0.8, // Controls space around divider
                    thickness: 0.5, // Make it thin
                  ),
                  // Use TopSalesLivres widget (which now only contains the grid)
                  TopSalesLivres(topSellingBooksCategoryId: topSellingBooksCategoryId),
                ],
              ),
            )
          );
        }
        // --- Add Special Carousel Section if it's the "Top Promotions" category ---
        else if (categoryId == topPromotionsCategoryId) { // Use else if to avoid adding to Livres
           categorySectionWidgets.add(
            // Add spacing BEFORE the styled container
            const SizedBox(height: AlkSize.spaceBtwSections * 0.8),
          );
          categorySectionWidgets.add(
            // *** Styled Container for Best Offers ***
            Container(
              // This container provides the outer padding
              margin: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
              padding: const EdgeInsets.only(top: AlkSize.md, left: AlkSize.md, right: AlkSize.md, bottom: AlkSize.lg), // <<< Outer padding
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:[Colors.purple.shade300, Colors.deepPurple.shade400],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color:  AlkColors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading for Best Offers (Inside the container)
                  AlkSectionHeading(
                    
                    title: '   Top Promotions ',
                    textColor: AlkColors.white,
                    showActionButton: false, // Keep the button to see all offers
                    icon: const Icon(Iconsax.star_1, color: AlkColors.white), // Optional icon
                    
                  ),
                  Divider( // Divider
                    color: AlkColors.white.withOpacity(0.4),
                    height: AlkSize.spaceBtwSections * 0.8,
                    thickness: 0.5,
                  ),
                  // *** Use AlkCategoryCarouselLayout ***
                  AlkCategoryCarouselLayout(
                     key: ValueKey(bestOffersContentCategoryId),
                     categoryId: 763,
                     itemCount: 8, // Fetch up to 8 best offers
                     productsPerPage: 1, // Show exactly 1 product per page view
                     horizontalPadding: 0,
                     verticalPadding: AlkSize.sm, // Keep vertical padding if needed for card spacing from top/bottom
                     autoSwipeDuration: const Duration(milliseconds: 6000), // Slower swipe
                  ),
                ],
              ),
            )
          );
        }

        // Return the full section wrapped in Padding for bottom spacing
        return Padding(
          padding: const EdgeInsets.only(bottom: AlkSize.spaceBtwSections / 2), // Reduced bottom padding slightly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categorySectionWidgets,
          ),
        );
      }).toList(), // Convert the mapped widgets to a list for the Column
    );
  }
}
