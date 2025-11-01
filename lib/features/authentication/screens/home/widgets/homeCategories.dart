import 'package:alkirtas/features/shop/screens/store/storedrawer.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/image_text_widgets/vertical_image_text.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../config/home_sections_config.dart';
import '../../../../../common/widgets/shimmer/shimmer_category_horizontal.dart';
import '../../../../../api/category_api.dart';

class AlkHomeCategories extends StatefulWidget {
  const AlkHomeCategories({Key? key}) : super(key: key);

  @override
  _AlkHomeCategoriesState createState() => _AlkHomeCategoriesState();
}

class _AlkHomeCategoriesState extends State<AlkHomeCategories> {
  List<dynamic> categories = []; // Holds the categories data
  bool isLoading = true; // Loading state

  // Map category names (lowercase) to appropriate icons
  IconData getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('livre') || name.contains('book')) {
      return Iconsax.book_1;
    } else if (name.contains('scolaire') || name.contains('école') || name.contains('school')) {
      return Iconsax.teacher;
    } else if (name.contains('bureau') ) {
      return Iconsax.monitor_mobbile;
    } else if (name.contains('jeux') || name.contains('jouet') ) {
      return Iconsax.game;
    } else if (name.contains('cadeau') ) {
      return Iconsax.gift;
    } else if (name.contains('art') || name.contains('créatif')) {
      return Iconsax.brush_1;
    } else if (name.contains('papeterie') ) {
      return Iconsax.note_1;
    } else if (name.contains('bagagerie') || name.contains('bag')) {
      return Iconsax.bag_2;
    } else if (name.contains('tech') ) {
      return Iconsax.mobile;
    } else if (name.contains('beauté') ) {
      return Iconsax.mirror;
    } else if (name.contains('fête') ) {
      return Iconsax.cake;
    }
    else if (name.contains('Fourniture') || name.contains('fourniture')) {
      return Iconsax.rulerpen;
    }
    return Iconsax.category; // Default icon
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      // Fetch categories from server (with caching)
      final fetchedCategories = await CategoryApi.fetchHomeCategories();

      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlkShimmerCategoryHorizontal();
    }

    if (categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: categories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = categories[index];
          final categoryId = category['id'] as int;
          final categoryName = category['name'] as String;
          return AlkVerticalImageText(
            title: categoryName,
            textColor: AlkColors.white,
            icon: getIconForCategory(categoryName),
            onTap: () {
              // Use NavigationController to navigate to StoreDrawer
              final navigationController = Get.find<NavigationController>();
              navigationController.navigateToStoreDrawer(
                categoryId: categoryId,
                categoryName: categoryName,
              );
            },
            backgroundColor: Colors.white,
          );
        },
      ),
    );
  }
}
