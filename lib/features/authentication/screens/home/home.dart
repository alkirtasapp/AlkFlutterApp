import 'editorial/editorial_department.dart';
import 'editorial/editorial_repository.dart';
import 'package:alkirtas/features/authentication/screens/home/widgets/top_sales_books.dart';
import 'package:alkirtas/features/audiobooks/audiobooks.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/custom_shapes/containers/searchContainer.dart';
import '../../../../common/widgets/layout/category_carousel_layout.dart'; // Import for the grid layout
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../../config/home_sections_config.dart';
import '../../../../common/widgets/layout/tabbed_category_carousel.dart';
import '../../../../models/home_section.dart';
import 'widgets/homeAppBar.dart';
import 'widgets/homeCategories.dart';
import 'widgets/bannerSlider.dart';
import 'widgets/home_authors.dart';
import 'widgets/trending_searches_widget.dart';
import 'widgets/home_search_overlay.dart';
import 'widgets/home_selling_feed.dart';
import 'widgets/home_for_you.dart';

/// Only changes the server-configured department blocks. Set false to restore them.
const bool useRedesignedSections = true;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Constants for Special Section ---
  static const String livresSectionTitle = "Alkirtas Books";
  static const String espaceBureauSectionTitle = "Alkirtas Office";
  // Category ID for the *content* of the "Livres les plus vendus" grid
  // !!! IMPORTANT: Replace '20' with the actual Prestashop Category ID for your top-selling books !!!
  //static const int topSellingBooksCategoryId = 763;

  final EditorialRepository _departmentRepository = EditorialRepository();
  List<HomeSection> sections = [];
  bool isLoadingSections = true;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    loadSections();
  }

  Future<void> loadSections() async {
    try {
      final loadedSections = await getHomeSections();
      setState(() {
        sections = loadedSections;
        isLoadingSections = false;
      });
    } catch (e) {
      print('Error loading sections: $e');
      setState(() {
        isLoadingSections = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Section ---
            AlkPrimaryHeaderContainer(
              child: Column(
                children: [
                  const AlkHomeAppBar(showCartIcon: true),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  if (_isSearchActive)
                    HomeSearchBar(
                      onClose: () => setState(() => _isSearchActive = false),
                    )
                  else
                    AlkSearchContainer(
                      text: 'Rechercher un produit...',
                      icon: Icons.search,
                      showQrButton: true,
                      onPressed: () => setState(() => _isSearchActive = true),
                    ),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                  const Padding(
                    padding: EdgeInsets.only(left: AlkSize.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AlkSectionHeading(
                          title: 'Nos Catégories : ',
                          textColor: AlkColors.white,
                          showActionButton: false,
                        ),
                        SizedBox(height: AlkSize.spaceBtwItems / 2),
                        AlkHomeCategories(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections * 1.2),
                ],
              ),
            ),

            // --- Body Content ---
            Padding(
              // Keep vertical padding minimal or remove if header provides enough space
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  // --- Selling Feed ---
                  const HomeSellingFeed(),
                  const SizedBox(height: AlkSize.spaceBtwItems),

                  // --- Banner Slider ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AlkSize.sm),
                    child: AlkBannerSlider(),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwItems),

                  // --- Pour vous (logged-in customers with history) ---
                  const HomeForYou(),

                  // --- Trending Searches Section ---
                  const TrendingSearchesWidget(),

                  // --- Product Sections (with conditional special section) ---
                  // Show loading indicator while sections are loading
                  if (isLoadingSections)
                    const Center(child: CircularProgressIndicator())
                  else
                    // Use map to potentially return multiple widgets per section
                    ...sections.asMap().entries.map((entry) {
                      final section = entry.value;
                      // 1. Create the standard TabbedCategoryCarousel widget
                      final standardCarousel = Padding(
                        padding: useRedesignedSections
                            ? const EdgeInsets.symmetric(horizontal: 16)
                            : const EdgeInsets.only(
                                bottom: AlkSize.spaceBtwItems / 2),
                        child: useRedesignedSections
                            ? EditorialDepartment(
                                key: ValueKey(
                                    'department_${entry.key}_${section.title}'),
                                section: section,
                                index: entry.key,
                                repository: _departmentRepository,
                                onCategory: (id, name) =>
                                    Get.find<NavigationController>()
                                        .navigateToStoreDrawer(
                                  categoryId: id,
                                  categoryName: name,
                                ),
                              )
                            : TabbedCategoryCarousel(
                                key: ValueKey('tabbed_${section.title}'),
                                section: section,
                                itemsPerCategory: 8,
                              ),
                      );
                      // 2. Check if this is the "Livres" section to add the special grid
                      if (section.title == livresSectionTitle) {
                        // Return a Column containing the standard carousel AND the special grid
                        return Column(
                          children: [
                            standardCarousel,
                            // --- Authors Section ---
                            const HomeAuthorsSection(),
                            BestSellersSection(
                              itemCount: 10,
                              categoryId: 901,
                              context: context,
                              title: '   Best Sellers ',
                              icon: Icon(Iconsax.ranking_1,
                                  color: AlkColors.white),
                              productsPerPage: 2,
                            ),
                            // Add the special section below
                          ],
                        );
                      } else if (section.title == espaceBureauSectionTitle) {
                        // Return a Column containing the standard carousel AND the special grid
                        return Column(
                          children: [
                            standardCarousel,
                            BestSellersSection(
                              itemCount: 6,
                              categoryId: 763,
                              context: context,
                              icon:
                                  Icon(Iconsax.star_1, color: AlkColors.white),
                              title: '   Déstockage ',
                              productsPerPage: 2,
                            ),
                            // Add the special section below
                          ],
                        );
                      } else {
                        // For all other sections, just return the standard carousel
                        return standardCarousel;
                      }
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
