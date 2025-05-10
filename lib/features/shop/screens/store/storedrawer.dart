import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:alkirtas/data/controllers/search_controller.dart';
import 'package:alkirtas/utils/constants/size.dart';
import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../controllers/categories_store_controller.dart';
import '../../controllers/product_controller_store.dart';

class StoreDrawer extends StatefulWidget {
  final int? initialCategoryId ;
  final String? initialCategoryName;
  const StoreDrawer({super.key, this.initialCategoryId, this.initialCategoryName});

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
  Set<int> fetchedProductIds = {};
  int offset = 0;
  final int limit = 10;
  TextEditingController searchTextController = TextEditingController();
  String currentSearchQuery = "";
  String selectedSortOption = "None"; // Track selected sorting option

  List<String> navigationStack = [];
  List<int> categoryIdStack = [];

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    await categoriesController.fetchAllCategories();
    if (categoriesController.mainCategories.isNotEmpty) {
      setState(() {
        // Use the initial category if provided, otherwise default to the first category
        selectedCategory = widget.initialCategoryName ??
            categoriesController.mainCategories.keys.first;
        selectedCategoryId = widget.initialCategoryId ??
            categoriesController.mainCategories.values.first;
      });

      _fetchProductsForCategory(selectedCategoryId);
    }
  }

  Future<void> _fetchProductsForCategory(int categoryId) async {
    setState(() {
      isLoading = true;
      products.clear();
      fetchedProductIds.clear();
      offset = 0;
      isSearching = false;
      selectedSortOption = "None"; // Reset the filter here
      isSearchVisible = false; // Hide search box
      searchTextController.clear(); // Clear search text
    });

    print("📡 Fetching products for Category ID: $categoryId, Offset: $offset");

    final List<Map<String, dynamic>> validProducts = await productController
            .fetchProductDataStore(categoryId, offset, limit) ??
        [];

    if (validProducts.isNotEmpty) {
      setState(() {
        for (var product in validProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += validProducts.length;
        _applySorting(); // Apply sorting after fetching
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
        _applySorting(); // Apply sorting after loading more products
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
      // Clear previous search results
      products.clear();
      fetchedProductIds.clear();
      isSearching = true;
      offset = 0;
      currentSearchQuery = query;
      selectedSortOption = "None"; // Reset the filter here
    });

    final List<int>? productIds =
        await searchController.searchProducts(query, offset: offset, limit: 100);

    if (productIds != null && productIds.isNotEmpty) {
      final List<Map<String, dynamic>>? searchedProducts =
          await productController.fetchProductsByIds(productIds);

      if (searchedProducts != null && searchedProducts.isNotEmpty) {
        setState(() {
          for (var product in searchedProducts) {
            // Prevent duplicates
            if (!fetchedProductIds.contains(product['id'])) {
              products.add(product);
              fetchedProductIds.add(product['id']);
            }
          }
          // Move offset forward correctly
          offset += searchedProducts.length;
          _applySorting(); // Apply sorting after loading more products
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

    print(
        "📡 Loading more search results for query: $currentSearchQuery, Offset: $offset");

    final List<int>? productIds = await searchController.searchProducts(
        currentSearchQuery,
        offset: offset,
        limit: 100);

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
          _applySorting(); // Apply sorting after loading more products
        });
        print(
            "✅ Loaded ${moreSearchedProducts.length} more products for query: $currentSearchQuery");
      } else {
        print("⚠️ No more products found for query: $currentSearchQuery");
      }
    } else {
      print("⚠️ No more product IDs found for query: $currentSearchQuery");
    }

    setState(() => isFetchingMore = false);
  }

  void _applySorting() {
    setState(() {
      if (selectedSortOption == "Price Asc") {
        products.sort(
            (a, b) => (a['price'] as num).compareTo(b['price'] as num));
      } else if (selectedSortOption == "Price Desc") {
        products.sort(
            (a, b) => (b['price'] as num).compareTo(a['price'] as num));
            
      } else if (selectedSortOption == "Name Asc") {
        products.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String));
      } else if (selectedSortOption == "Name Desc") {
        products.sort(
            (a, b) => (b['name'] as String).compareTo(a['name'] as String));
      } else if (selectedSortOption == "Référence Asc") {
        products.sort(
            (a, b) => (b['reference'] as String).compareTo(a['reference'] as String));
      } else if (selectedSortOption == "Référence Desc") {
        products.sort(
            (a, b) => (b['reference'] as String).compareTo(a['reference'] as String));
      } 
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: navigationStack.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    // Get the parent category before removing from stack
                    String parentCategory = navigationStack.last;
                    int parentCategoryId = categoryIdStack.last;
                    
                    // Remove current level from navigation stack
                    navigationStack.removeLast();
                    categoryIdStack.removeLast();
                    
                    // Set the selected category to parent
                    selectedCategory = parentCategory;
                    selectedCategoryId = parentCategoryId;
                  });
                  // Fetch products for the parent category
                  _fetchProductsForCategory(selectedCategoryId);
                },
              )
            : Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Iconsax.filter),
            onSelected: (String value) {
              setState(() {
                selectedSortOption = value;
                _applySorting(); // Apply sorting when an option is selected
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: "Price Asc", child: Text("Prix Croissant")),
              PopupMenuItem(value: "Price Desc", child: Text("Prix Décroissant")),
              PopupMenuItem(value: "Name Asc", child: Text("Nom A-Z")),
              PopupMenuItem(value: "Name Desc", child: Text("Nom Z-A")),
              PopupMenuItem(value: "Référence Adc", child: Text("Référence Z-A")),
              PopupMenuItem(value: "Référence Desc", child: Text("Réféence Z-A")),
            ],
          ),
        ],
        title: Text(isSearching
            ?  currentSearchQuery
            : selectedCategory.isNotEmpty
                ? selectedCategory
                : "Chargement..."),
      ),
      drawer: Drawer(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Breadcrumb navigation
                  if (navigationStack.isNotEmpty)
                    ListTile(
                      leading: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                      ),
                      title: Text(
                        'Retour vers ${navigationStack.last}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          navigationStack.removeLast();
                          categoryIdStack.removeLast();
                          if (categoryIdStack.isNotEmpty) {
                            selectedCategory = navigationStack.last;
                            selectedCategoryId = categoryIdStack.last;
                          } else {
                            selectedCategory = categoriesController.mainCategories.keys.first;
                            selectedCategoryId = categoriesController.mainCategories.values.first;
                          }
                        });
                        _fetchProductsForCategory(selectedCategoryId);
                        Navigator.pop(context);
                      },
                    ),
                  Expanded(
                    child: ListView(
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
                                  // Clear navigation stack when selecting main category
                                  navigationStack.clear();
                                  categoryIdStack.clear();
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
                                          
                                          // Clear previous navigation if any
                                          navigationStack.clear();
                                          categoryIdStack.clear();
                                          
                                          // Add the parent category to navigation stack
                                          navigationStack.add(category.key);
                                          categoryIdStack.add(category.value);
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
                                                
                                                // Clear previous navigation if any
                                                navigationStack.clear();
                                                categoryIdStack.clear();
                                                
                                                // Add both parent and current category to navigation stack
                                                navigationStack.add(category.key);
                                                categoryIdStack.add(category.value);
                                                navigationStack.add(subcategory['name']);
                                                categoryIdStack.add(subcategory['id']);
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
                      setState(() {
                        isSearchVisible = false; // Hide search bar after search
                      });
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? Center(
                          child: Text(
                            isSearching
                                ? "Aucun résultat trouvé pour votre recherche."
                                : "Aucun produit disponible.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
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
                                categoryId:
                                    isSearching ? -1 : selectedCategoryId,
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
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.purple),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
