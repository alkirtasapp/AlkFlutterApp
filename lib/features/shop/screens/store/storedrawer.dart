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
  final Map<String, int> categoryMap = {
    "Livres": 10,
    "Papeterie": 11,
    "Bagagerie": 12,
    "Parascolaires": 17,
    "Fournitures": 486,
    "Cadeaux et Fêtes": 544,
    "Bureautique": 558,
    "Jeux et Jouets": 590,
    "Art et Loisirs": 743,
  };

  final CategoriesStoreController categoriesController =
      CategoriesStoreController();

  String selectedCategory = "Livres"; // Default category name
  int selectedCategoryId = 10; // Default category ID
  Key productListKey = UniqueKey(); // Declare the key at the class level

  @override
  void initState() {
    super.initState();
    categoriesController.fetchAllSubcategories().then((_) {
      setState(() {}); // Refresh UI after fetching subcategories
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(selectedCategory),
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
          child: ListView(
            children: [
              for (var category in categoryMap.entries)
                ExpansionTile(
                  title: Text(category.key),
                  children: [
                    if (categoriesController.subcategories
                        .containsKey(category.value))
                      for (var subcategory in categoriesController
                          .subcategories[category.value]!)
                        ListTile(
                          title: Text("• ${subcategory['name']}"),
                          onTap: () {
                            setState(() {
                              selectedCategory = subcategory['name'];

                              // ✅ Ensure the category ID is always an integer
                              selectedCategoryId = subcategory['id'] is int
                                  ? subcategory['id']
                                  : int.tryParse(
                                          subcategory['id'].toString()) ??
                                      0;

                              productListKey = UniqueKey(); // Force refresh
                            });

                            print(
                                '🔄 Changing category to: ${subcategory['name']} ${selectedCategoryId}'); // Debugging
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft, // Ensures proper positioning
                  child: AlkSearchContainer(
                    text: 'Recherche',
                    icon: Iconsax.search_normal,
                    showBackground: true,
                  ),
                ),
              ),

              // ✅ Product Grid updates with the selected subcategory's products
              Expanded(
                child: Column(
                  children: [
                    AlkStoreGridDrawer(
                      key: productListKey,
                      itemCount: 10,
                      categoryId:
                          selectedCategoryId, // ✅ Now uses subcategory ID!
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
