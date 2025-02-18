import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../controllers/categories_store_controller.dart';
import '../../controllers/product_controller_store.dart';

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
  List<Map<String, dynamic>> products = []; // ✅ Store fetched products

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
      });

      _fetchProductsForCategory(selectedCategoryId); // ✅ Fetch products when category is set
    }
  }

  Future<void> _fetchProductsForCategory(int categoryId) async {
    setState(() => isLoading = true);

    final productController = ProductControllerStore();
    List<Map<String, dynamic>> fetchedProducts = [];

    // ✅ Fetch multiple products in parallel
    List<Future<Map<String, dynamic>?>> fetchTasks = List.generate(8, (index) {
      return productController.fetchProductDataStore(index, categoryId);
    });

    final results = await Future.wait(fetchTasks);

    for (var product in results) {
      if (product != null) {
        fetchedProducts.add(product);
      }
    }

    setState(() {
      products = fetchedProducts;
      isLoading = false;
    });

    print("✅ Preloaded ${products.length} products for Category ID: $categoryId");
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
              ? Center(child: CircularProgressIndicator( ))
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
                              products.clear();
                            });

                            print("✅ Main Category selected: $selectedCategory with ID: $selectedCategoryId");

                            _fetchProductsForCategory(selectedCategoryId);

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
                                      products.clear();
                                    });

                                    print("✅ Subcategory selected: $selectedCategory with ID: $selectedCategoryId");

                                    _fetchProductsForCategory(selectedCategoryId);

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
                                            products.clear();
                                          });

                                          print("✅ Level 4 Subcategory selected: $selectedCategory with ID: $selectedCategoryId");

                                          _fetchProductsForCategory(selectedCategoryId);

                                          Navigator.pop(context);
                                        },
                                      )
                                ],
                              )
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
                  child:
                   AlkSearchContainer(
                    text: 'Recherche',
                    icon: Iconsax.search_normal,
                    showBackground: true,
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(
                      
           
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),))
                    : AlkStoreGridDrawer(
                        key: productListKey,
                        itemCount:10 /*products.length*/,
                        categoryId: selectedCategoryId,
                        preloadedProducts: products, // ✅ Pass preloaded products
                      ),
              ),
            ],
          ),
        ));
  }
}
