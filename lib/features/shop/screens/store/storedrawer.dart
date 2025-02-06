import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../controllers/categories_store_controller.dart';

class StoreDrawer extends StatefulWidget {
  const StoreDrawer({super.key});

  @override
  State<StoreDrawer> createState() => _StorePageState();
}

class _StorePageState extends State<StoreDrawer> {
  final CategoriesStoreController categoriesController = CategoriesStoreController();
  
  String selectedCategory = ""; // Default category name
  int selectedCategoryId = -1; // Default category ID
  Key productListKey = UniqueKey(); // Declare the key at the class level
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    await categoriesController.fetchMainCategories();
    await categoriesController.fetchAllSubcategories();
    
    if (categoriesController.categoryMap.isNotEmpty) {
      setState(() {
        selectedCategory = categoriesController.categoryMap.keys.first;
        selectedCategoryId = categoriesController.categoryMap.values.first;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(selectedCategory.isNotEmpty ? selectedCategory : "Chargement..."),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
        ),
        drawer: Drawer(
          child: isLoading
              ? Center(child: CircularProgressIndicator()) // Show loading spinner
              : ListView(
                  children: [
                    for (var category in categoriesController.categoryMap.entries)
                      ExpansionTile(
                        title: Text(category.key),
                        children: [
                          if (categoriesController.subcategories.containsKey(category.value))
                            for (var subcategory in categoriesController.subcategories[category.value]!)
                              ListTile(
                                title: Text("• ${subcategory['name']}"),
                                onTap: () {
                                  print("🔍 Subcategory selected: ${subcategory['name']} - Raw ID: ${subcategory['id']} (${subcategory['id'].runtimeType})");

                                  setState(() {
                                    selectedCategory = subcategory['name'];
                                    selectedCategoryId = subcategory['id'] is int
                                        ? subcategory['id']
                                        : int.tryParse(subcategory['id'].toString()) ?? -1;
                                    productListKey = UniqueKey(); // Force refresh
                                  });

                                  print("✅ Changing category to: $selectedCategory with ID: $selectedCategoryId (${selectedCategoryId.runtimeType})");
                                  Navigator.pop(context);
                                },
                              )
                          else
                            ListTile(
                              title: Text("Chargement..."),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AlkSearchContainer(
                    text: 'Recherche',
                    icon: Iconsax.search_normal,
                    showBackground: true,
                  ),
                ),
              ),

              // ✅ Product Grid updates with the selected subcategory's products
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator()) // Show loading if categories are not loaded yet
                    : Column(
                        children: [
                          AlkStoreGridDrawer(
                            key: productListKey,
                            itemCount: 10,
                            categoryId: selectedCategoryId, // ✅ Uses dynamically fetched category ID
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ));
  }
}
