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
  Set<int> fetchedProductIds = {}; // Track fetched product IDs
  int offset = 0;
  final int limit = 12; // Ensuring fixed product fetch limit
  TextEditingController searchTextController = TextEditingController();
  String currentSearchQuery = "";

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
      fetchedProductIds.clear(); // Clear fetched product IDs
      offset = 0;
      isSearching = false;
    });

    print("📡 Fetching products for Category ID: $categoryId, Offset: $offset");

    final List<Map<String, dynamic>> validProducts = await productController
            .fetchProductDataStore(categoryId, offset, limit) ?? [];

    if (validProducts.isNotEmpty) {
      setState(() {
        for (var product in validProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += validProducts.length;
      });
      print(
          "✅ Fetched ${validProducts.length} products for Category ID: $categoryId");
    } else {
      print("⚠️ No valid products found for Category ID: $categoryId");
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMoreProducts() async {
    if (isFetchingMore) return;

    setState(() => isFetchingMore = true);

    print(
        "📡 Loading more products for Category ID: $selectedCategoryId, Offset: $offset");

    final List<Map<String, dynamic>>? moreProducts = await productController
        .fetchProductDataStore(selectedCategoryId, offset, limit);

    if (moreProducts != null && moreProducts.isNotEmpty) {
      setState(() {
        for (var product in moreProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += moreProducts.length;
      });
      print(
          "✅ Loaded ${moreProducts.length} more products for Category ID: $selectedCategoryId");
    } else {
      print("⚠️ No more products found for Category ID: $selectedCategoryId");
    }

    setState(() => isFetchingMore = false);
  }

 Future<void> _searchProducts(String query) async {
  setState(() {
    isLoading = true;
    products.clear(); // Clear previous search results
    fetchedProductIds.clear();
    isSearching = true;
    offset = 0;
    currentSearchQuery = query;
  });

  final List<int>? productIds = await searchController.searchProducts(query, offset: offset, limit: 10);

  if (productIds != null && productIds.isNotEmpty) {
    final List<Map<String, dynamic>>? searchedProducts = await productController.fetchProductsByIds(productIds);

    if (searchedProducts != null && searchedProducts.isNotEmpty) {
      setState(() {
        for (var product in searchedProducts) {
          if (!fetchedProductIds.contains(product['id'])) {  // Prevent duplicates
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += searchedProducts.length; // Move offset forward correctly
      });
      print("✅ Displaying first ${searchedProducts.length} search results.");
    } else {
      print("⚠️ No valid product details found.");
    }
  } else {
    print("⚠️ No product IDs returned from search.");
  }

  setState(() => isLoading = false);
}

 Future<void> _loadMoreSearchResults() async {
  if (isFetchingMore) return;

  setState(() => isFetchingMore = true);

  print("📡 Loading more search results for query: $currentSearchQuery, Offset: $offset");

  final List<int>? productIds = await searchController.searchProducts(currentSearchQuery, offset: offset, limit: 10);

  if (productIds != null && productIds.isNotEmpty) {
    final List<Map<String, dynamic>>? moreSearchedProducts =
        await productController.fetchProductsByIds(productIds);

    if (moreSearchedProducts != null && moreSearchedProducts.isNotEmpty) {
      setState(() {
        for (var product in moreSearchedProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += productIds.length;
      });
      print("✅ Loaded ${moreSearchedProducts.length} more products for query: $currentSearchQuery");
    } else {
      print("⚠️ No more products found for query: $currentSearchQuery");
    }
  } else {
    print("⚠️ No more product IDs found for query: $currentSearchQuery");
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
            ? Center(child:CircularProgressIndicator())
            : ListView(
                children: [
                  for (var category
                      in categoriesController.mainCategories.entries)
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

                                  _fetchProductsForCategory(selectedCategoryId);
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
                      _searchProducts(query); // Call _searchProducts on search submission
                    },
                  ),
                ),
              ),
            ),
           Flexible(
  child: isLoading
      ? Center(child: CircularProgressIndicator())
      : NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                !isFetchingMore) {
              if (isSearching) {
                _loadMoreSearchResults();
              } else {
                _loadMoreProducts();
              }
            }
            return false;
          },
          child: Stack(
            children: [
              AlkStoreGridDrawer(
                key: productListKey,
                itemCount: products.length,
                categoryId: isSearching ? -1 : selectedCategoryId,
                preloadedProducts: products,
              ),
              if (isFetchingMore)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 10,
                        child: LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 10,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
)

          ],
        ),
      ),
    );
  }
}