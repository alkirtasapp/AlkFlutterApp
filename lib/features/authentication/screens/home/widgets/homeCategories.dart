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

class AlkHomeCategories extends StatefulWidget {
  const AlkHomeCategories({Key? key}) : super(key: key);

  @override
  _AlkHomeCategoriesState createState() => _AlkHomeCategoriesState();
}

class _AlkHomeCategoriesState extends State<AlkHomeCategories> {
  List<dynamic> categories = []; // Holds the categories data
  bool isLoading = true; // Loading state

  // List of category IDs to exclude
  final List<int> excludedCategoryIds = [711, 707, 763,901];

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
    const apiUrl =
        'https://www.alkirtas.com/api/categories?filter[level_depth]=2&display=[id,name]&limit=20&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    // Predefined order of categories
    const List<String> categoryOrder = [
      "Livres",
      "Parascolaires",
      "Livres Scolaires",
      "Fournitures",
      "Papeterie",
      "Bagagerie",
      "Bureautique",
      "Art et Loisirs",
      "Jeux et jouets",
      "Cadeaux et fetes",
    ];

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Filter out excluded categories
          categories = (data['categories'] as List?)?.where(
            (category) => !excludedCategoryIds.contains(category['id'])
          ).toList() ?? [];

          // Sort categories based on the predefined order
          categories.sort((a, b) {
            final nameA = a['name'] as String;
            final nameB = b['name'] as String;
            final indexA = categoryOrder.indexOf(nameA);
            final indexB = categoryOrder.indexOf(nameB);
            return indexA.compareTo(indexB);
          });

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
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
      return const Center(child: CircularProgressIndicator());
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
