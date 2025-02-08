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

  String selectedCategory = "";
  int selectedCategoryId = -1;
  Key productListKey = UniqueKey();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    await categoriesController.fetchAllCategories();
    if (categoriesController.mainCategories.isNotEmpty) {
      setState(() {
        selectedCategory = categoriesController.mainCategories.keys.first;
        selectedCategoryId = categoriesController.mainCategories.values.first;
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
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    for (var category in categoriesController.mainCategories.entries)
                      ExpansionTile(
                        title: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category.key;
                              selectedCategoryId = category.value;
                              productListKey = UniqueKey();
                            });

                            print("✅ Main Category selected: $selectedCategory with ID: $selectedCategoryId");
                            Navigator.pop(context);
                          },
                          child: Text(category.key, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        children: [
                          if (categoriesController.categoryTree.containsKey(category.value))
                            for (var subcategory in categoriesController.categoryTree[category.value]!)
                              ExpansionTile(
                                title: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = subcategory['name'];
                                      selectedCategoryId = subcategory['id'];
                                      productListKey = UniqueKey();
                                    });

                                    print("✅ Subcategory selected: $selectedCategory with ID: $selectedCategoryId");
                                    Navigator.pop(context);
                                  },
                                  child: Text("• ${subcategory['name']}", style: TextStyle(fontSize: 14)),
                                ),
                                children: [
                                  if (categoriesController.categoryTree.containsKey(subcategory['id']))
                                    for (var subSubcategory in categoriesController.categoryTree[subcategory['id']]!)
                                      ListTile(
                                        title: Text("→ ${subSubcategory['name']}"),
                                        onTap: () {
                                          setState(() {
                                            selectedCategory = subSubcategory['name'];
                                            selectedCategoryId = subSubcategory['id'];
                                            productListKey = UniqueKey();
                                          });

                                          print("✅ Level 4 Subcategory selected: $selectedCategory with ID: $selectedCategoryId");
                                          Navigator.pop(context);
                                        },
                                      )
                                  else
                                    ListTile(title: Text("Chargement...")),
                                ],
                              )
                          else
                            ListTile(title: Text("Chargement...")),
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
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : AlkStoreGridDrawer(
                        key: productListKey,
                        itemCount: 10,
                        categoryId: selectedCategoryId,
                      ),
              ),
            ],
          ),
        ));
  }
}