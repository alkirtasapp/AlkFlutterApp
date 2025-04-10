import 'package:alkirtas/common/widgets/custom_shapes/containers/second_header_container.dart';
import 'package:alkirtas/common/widgets/layout/carousel_layout.dart';
import 'package:alkirtas/features/shop/controllers/brand_controller.dart';
import 'package:alkirtas/features/shop/screens/store/widgets/home_brands.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/size.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/custom_shapes/containers/searchContainer.dart';
import '../../../../common/widgets/layout/grid_layout.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../navigation_menu.dart';
import 'widgets/bannerSlider.dart';
import 'widgets/homeAppBar.dart';
import 'widgets/homeCategories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header --
            AlkPrimaryHeaderContainer(
              child: Column(
                children: [
                  // APP BAR
                  const AlkHomeAppBar(showCartIcon: true),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // SEARCH BAR
                  AlkSearchContainer(
                    text: 'Découvrir ma boutique',
                    icon: Iconsax.search_normal,
                    onPressed: () {
                      // Navigate to NavigationMenu, setting the store as the active tab
                      Get.offAll(() => const NavigationMenu(selectedMenu: 1));
                    },
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // CATEGORIES
                  Padding(
                    padding: const EdgeInsets.only(left: AlkSize.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Heading
                        const AlkSectionHeading(
                          title: 'Nos Catégories : ',
                          textColor: Colors.white,
                          showActionButton: false,
                        ),
                        const SizedBox(height: AlkSize.spaceBtwItems / 2),

                        /// Categories
                        const AlkHomeCategories(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections * 1.2),
                ],
              ),
            ),

            /// Body
            Padding(
              padding: const EdgeInsets.all(AlkSize.sm),
              child: Column(
                children: [
                  // Banner Slider
                  const AlkBannerSlider(),
                  const SizedBox(height: AlkSize.spaceBtwSections / 1.5),

                  // Popular Products Section
                  const AlkSectionHeading(
                    title: 'Produits populaires :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections / 1.5),

                  // Products Grid
                  AlkCarouselLayout(
                    autoSwipeDuration: const Duration(milliseconds: 4000), // Duration for auto swipe in millisecond
                    itemCount: 8, // Number of products to display
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    productsPerPage: 2, 
                    verticalPadding: 16.0,
                    
                  ),

                  
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // New Products Section
                  const AlkSectionHeading(
                    title: 'Nouveaux produits :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  AlkCarouselLayout(
                    productsPerPage: 2,
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    verticalPadding: 8.0,
                    itemCount: 8, // Number of products to display
                    autoSwipeDuration: const Duration(milliseconds: 5000), // Duration for auto swipe in millisecond
                  ),

                  const SizedBox(height: AlkSize.spaceBtwSections),
                  // Brands Section
                  AlkSecondHeaderContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AlkSize.defaultSpace),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AlkSectionHeading(
                            title: 'Promotions : ',
                            textColor: Colors.white,
                            showActionButton: false,

                          ),
                          const SizedBox(height: AlkSize.spaceBtwItems / 1.5),

                          // Brands Grid
                          AlkCarouselLayout(
                            itemCount: 8, // Number of products to display
                            productsPerPage: 1, // Single product per page
                            horizontalPadding:12.0, // Adjust horizontal padding
                            verticalPadding: 16.0, // Adjust vertical padding
                            autoSwipeDuration: const Duration(milliseconds: 4000), // Duration for auto swipe in millisecond
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),
                 

                  // New Products Section
                  const AlkSectionHeading(
                    title: 'Nouveaux produits :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  AlkCarouselLayout(
                    productsPerPage: 2 ,
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    verticalPadding: 8.0,
                    itemCount: 8, // Number of products to display
                    autoSwipeDuration: const Duration(milliseconds: 5000), // Duration for auto swipe in millisecond
                  ),

                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // New Products Section
                  const AlkSectionHeading(
                    title: 'Nouveaux produits :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  AlkCarouselLayout(
                    productsPerPage: 2,
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    verticalPadding: 8.0,
                    itemCount: 8, // Number of products to display
                    autoSwipeDuration: const Duration(milliseconds: 4000), // Duration for auto swipe in millisecond
                  ),

                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // New Products Section
                  const AlkSectionHeading(
                    title: 'Nouveaux produits :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  AlkCarouselLayout(
                    productsPerPage: 2,
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    verticalPadding: 8.0,
                    itemCount: 8, // Number of products to display
                    autoSwipeDuration: const Duration(milliseconds: 5000), // Duration for auto swipe in millisecond
                  ),

                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // New Products Section
                  const AlkSectionHeading(
                    title: 'Nouveaux produits :',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  AlkCarouselLayout(
                    productsPerPage: 2,
                    horizontalPadding: 12.0, // Adjust horizontal padding
                    verticalPadding: 8.0,
                    itemCount: 8, // Number of products to display
                    autoSwipeDuration: const Duration(milliseconds: 4000), // Duration for auto swipe in millisecond
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
