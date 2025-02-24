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
  final ProductControllerStore productController = ProductControllerStore();

  String selectedCategory = "";
  int selectedCategoryId = -1;
  Key productListKey = UniqueKey();
  bool isLoading = true;
  bool isFetchingMore = false;
  bool isSearchVisible = false;
  List<Map<String, dynamic>> products = [];
  int offset = 0;
  final int limit = 8;

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

      _fetchProductsForCategory(selectedCategoryId);
    }
  }

  Future<void> _fetchProductsForCategory(int categoryId) async {
    setState(() {
      isLoading = true;
      products.clear();
      offset = 0;
    });

    final List<Map<String, dynamic>>? newProducts =
        await productController.fetchProductDataStore(categoryId, offset, limit);

    if (newProducts != null && newProducts.isNotEmpty) {
      setState(() {
        products.addAll(newProducts);
        offset += newProducts.length;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMoreProducts() async {
    if (isFetchingMore) return;

    setState(() => isFetchingMore = true);

    final List<Map<String, dynamic>>? moreProducts =
        await productController.fetchProductDataStore(selectedCategoryId, offset, limit);

    if (moreProducts != null && moreProducts.isNotEmpty) {
      setState(() {
        products.addAll(moreProducts);
        offset += moreProducts.length;
      });
    }

    setState(() => isFetchingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Iconsax.search_favorite),
              onPressed: () {
                setState(() {
                  isSearchVisible = !isSearchVisible;
                });
              },
            ),
          ],
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
              Visibility(
                visible: isSearchVisible,
                child: Padding(
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
              ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !isFetchingMore) {
                            _loadMoreProducts();
                          }
                          return false;
                        },
                        child: AlkStoreGridDrawer(
                          key: productListKey,
                          itemCount: products.length,
                          categoryId: selectedCategoryId,
                          preloadedProducts: products,
                        ),
                      ),
              ),
            ],
          ),
        ));
  }
}
