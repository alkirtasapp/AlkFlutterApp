import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:test/data/controllers/search_controller.dart';
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
  final CategoriesStoreController categoriesController =
      CategoriesStoreController();
  final ProductControllerStore productController = ProductControllerStore();
  final AlkSearchController searchController = AlkSearchController();

  String selectedCategory = "";
  int selectedCategoryId = -1;
  Key productListKey = UniqueKey();
  bool isLoading = true;
  bool isFetchingMore = false;
  bool isSearchVisible = false;
  bool isSearching = false;
  List<Map<String, dynamic>> products = [];
  int offset = 0;
  final int limit = 10; // Ensuring fixed product fetch limit
  TextEditingController searchTextController = TextEditingController();

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
      isSearching = false;
    });

    print("📡 Fetching products for Category ID: $categoryId, Offset: $offset");

    final List<Map<String, dynamic>> validProducts = await productController
            .fetchProductDataStore(categoryId, offset, limit) ?? 
        [];

    if (validProducts.isNotEmpty) {
      setState(() {
        products.addAll(validProducts);
        offset += validProducts.length;
      });
      print("✅ Fetched ${validProducts.length} products for Category ID: $categoryId");
    } else {
      print("⚠️ No valid products found for Category ID: $categoryId");
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMoreProducts() async {
    if (isFetchingMore) return;

    setState(() => isFetchingMore = true);

    print("📡 Loading more products for Category ID: $selectedCategoryId, Offset: $offset");

    final List<Map<String, dynamic>>? moreProducts = await productController
        .fetchProductDataStore(selectedCategoryId, offset, limit);

    if (moreProducts != null && moreProducts.isNotEmpty) {
      setState(() {
        products.addAll(moreProducts);
        offset += moreProducts.length;
      });
      print("✅ Loaded ${moreProducts.length} more products for Category ID: $selectedCategoryId");
    } else {
      print("⚠️ No more products found for Category ID: $selectedCategoryId");
    }

    setState(() => isFetchingMore = false);
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      isLoading = true;
      products.clear();
      isSearching = true;
    });

    final List<Map<String, dynamic>>? searchedProducts = await searchController.searchProducts(query);

    if (searchedProducts != null && searchedProducts.isNotEmpty) {
      setState(() {
        products.addAll(searchedProducts);
      });
      print("✅ Found ${searchedProducts.length} products for query: $query");
    } else {
      print("⚠️ No products found for query: $query");
    }

    setState(() => isLoading = false);
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
        title: Text(
            selectedCategory.isNotEmpty ? selectedCategory : "Chargement..."),
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

                          _fetchProductsForCategory(selectedCategoryId);
                          Navigator.pop(context);
                        },
                        child: Text(category.key,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      children: [
                        if (categoriesController.categoryTree
                            .containsKey(category.value))
                          for (var subcategory in categoriesController
                              .categoryTree[category.value]!)
                            ExpansionTile(
                              title: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = subcategory['name'];
                                    selectedCategoryId = subcategory['id'];
                                    productListKey = UniqueKey();
                                    products.clear();
                                  });

                                  _fetchProductsForCategory(
                                      selectedCategoryId);
                                  Navigator.pop(context);
                                },
                                child: Text("• ${subcategory['name']}",
                                    style: TextStyle(fontSize: 14)),
                              ),
                              children: [
                                if (categoriesController.categoryTree
                                    .containsKey(subcategory['id']))
                                  for (var subSubcategory
                                      in categoriesController
                                          .categoryTree[subcategory['id']]!)
                                    ListTile(
                                      title:
                                          Text("→ ${subSubcategory['name']}"),
                                      onTap: () {
                                        setState(() {
                                          selectedCategory =
                                              subSubcategory['name'];
                                          selectedCategoryId =
                                              subSubcategory['id'];
                                          productListKey = UniqueKey();
                                          products.clear();
                                        });

                                        _fetchProductsForCategory(
                                            selectedCategoryId);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: searchTextController,
                    decoration: InputDecoration(
                      hintText: 'Recherche',
                      prefixIcon: Icon(Iconsax.search_normal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: (query) {
                      _searchProducts(query);
                    },
                  ),
                ),
              ),
            ),
            Flexible(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            !isFetchingMore && !isSearching) {
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
      ),
    );
  }
}