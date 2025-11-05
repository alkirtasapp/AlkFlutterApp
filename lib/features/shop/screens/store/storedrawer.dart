import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:alkirtas/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:alkirtas/data/controllers/search_controller.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../controllers/categories_store_controller.dart';
import '../../controllers/product_controller_store.dart';
import '../../../../common/widgets/qr_scanner/qr_scanner_widget.dart';
import '../../../../controllers/qr_navigation_controller.dart';
import '../../../../navigation_menu.dart';
import '../../../../common/widgets/shimmer/shimmer_product_grid.dart';
import '../../../../common/widgets/shimmer/shimmer_list_tile.dart';

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

  // Autocomplete and debouncing
  Timer? _debounceTimer;
  List<String> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    // Listen to search text changes for autocomplete
    searchTextController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchTextController.removeListener(_onSearchTextChanged);
    searchTextController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (searchTextController.text.isEmpty) {
      _removeOverlay();
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchSearchSuggestions(searchTextController.text);
    });
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    final List<int>? productIds = await searchController.searchProducts(
      query,
      offset: 0,
      limit: 10, // Limit suggestions to 10 items
    );

    if (productIds != null && productIds.isNotEmpty) {
      final List<Map<String, dynamic>>? suggestedProducts =
          await productController.fetchProductsByIds(productIds);

      if (suggestedProducts != null && suggestedProducts.isNotEmpty) {
        setState(() {
          _searchSuggestions = suggestedProducts
              .map((p) => p['name'].toString())
              .toSet()
              .toList();
          _isLoadingSuggestions = false;
        });
        _showSuggestionsOverlay();
      } else {
        setState(() {
          _searchSuggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    } else {
      setState(() {
        _searchSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    if (_searchSuggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 70,
        left: 12,
        right: 12,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchSuggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: Icon(Iconsax.search_normal, size: 18, color: Colors.grey),
                  title: Text(
                    _searchSuggestions[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    final selectedText = _searchSuggestions[index];
                    // Remove listener temporarily to avoid triggering new suggestions
                    searchTextController.removeListener(_onSearchTextChanged);
                    searchTextController.text = selectedText;
                    // Re-add listener
                    searchTextController.addListener(_onSearchTextChanged);

                    _removeOverlay();
                    _searchProducts(selectedText);
                    setState(() {
                      isSearchVisible = false;
                      _searchSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _clearSearch() {
    searchTextController.clear();
    _removeOverlay();
    setState(() {
      isSearching = false;
      currentSearchQuery = "";
      products.clear();
      fetchedProductIds.clear();
      offset = 0;
    });
    // Reload the current category
    _fetchProductsForCategory(selectedCategoryId);
  }

  String _getSortOptionLabel(String option) {
    switch (option) {
      case "Price Asc":
        return "Prix Croissant";
      case "Price Desc":
        return "Prix Décroissant";
      case "Name Asc":
        return "Nom A-Z";
      case "Name Desc":
        return "Nom Z-A";
      case "Référence Asc":
        return "Référence A-Z";
      case "Référence Desc":
        return "Référence Z-A";
      default:
        return "Aucun";
    }
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

  final List<int> allProductIds = await productController.productListCategory.fetchProductIdsFromCategory(selectedCategoryId);

  int remaining = allProductIds.length - offset;
  print("🔎 Found $remaining products remaining on category ID $selectedCategoryId");

  // Get the next batch of product IDs
  final List<int> nextBatchIds = allProductIds.skip(offset).take(limit * 5).toList(); // Fetch a bigger batch to filter more

  if (nextBatchIds.isEmpty) {
    print("⚠️ No more products to load for Category ID: $selectedCategoryId");
    setState(() => isFetchingMore = false);
    return;
  }

  final List<Map<String, dynamic>>? moreProducts = await productController.fetchProductsByIds(nextBatchIds);

  // Only add active products
  final activeProducts = moreProducts?.where((p) => p['active'].toString() == '1').toList() ?? [];

  if (activeProducts.isNotEmpty) {
    setState(() {
      for (var product in activeProducts) {
        if (!fetchedProductIds.contains(product['id'])) {
          products.add(product);
          fetchedProductIds.add(product['id']);
        }
      }
      offset += nextBatchIds.length; // Move offset by batch size, not just limit
      _applySorting();
    });
    print("✅ Displayed ${activeProducts.length} products, ${allProductIds.length - offset} remaining on category ID $selectedCategoryId");
  } else {
    print("⚠️ No more active products found for Category ID: $selectedCategoryId");
    offset += nextBatchIds.length; // Still move offset forward
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
      _searchSuggestions = []; // Clear suggestions
    });
    _removeOverlay(); // Ensure overlay is removed

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
            (a, b) => (a['reference'] as String).compareTo(b['reference'] as String));
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
            icon: Icon(isSearching ? Icons.search_off : Icons.search),
            tooltip: isSearching ? 'Effacer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                if (isSearching) {
                  // If there's an active search, clear it
                  _clearSearch();
                  isSearchVisible = false;
                } else {
                  // Toggle search bar visibility
                  isSearchVisible = !isSearchVisible;
                  if (!isSearchVisible) {
                    // If closing search bar, clear any unsaved text
                    searchTextController.clear();
                    _searchSuggestions = [];
                    _removeOverlay();
                  } else {
                    // If opening search bar, clear old suggestions
                    _searchSuggestions = [];
                  }
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Iconsax.scan),
            onPressed: () => _showQrScanner(context),
            tooltip: 'Scanner QR Code',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Iconsax.filter,
              color: selectedSortOption != "None" ? Colors.purple : null,
            ),
            tooltip: selectedSortOption != "None"
                ? 'Filtre actif: ${_getSortOptionLabel(selectedSortOption)}'
                : 'Filtrer',
            onSelected: (String value) {
              setState(() {
                selectedSortOption = value;
                _applySorting(); // Apply sorting when an option is selected
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: "None",
                child: Row(
                  children: [
                    Icon(
                      selectedSortOption == "None" ? Iconsax.tick_circle5 : Iconsax.close_circle,
                      size: 18,
                      color: selectedSortOption == "None" ? Colors.purple : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text("Aucun filtre", style: TextStyle(
                      fontWeight: selectedSortOption == "None" ? FontWeight.bold : FontWeight.normal,
                      color: selectedSortOption == "None" ? Colors.purple : null,
                    )),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: "Price Asc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Price Asc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Prix Croissant", style: TextStyle(
                      fontWeight: selectedSortOption == "Price Asc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "Price Desc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Price Desc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Prix Décroissant", style: TextStyle(
                      fontWeight: selectedSortOption == "Price Desc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "Name Asc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Name Asc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Nom A-Z", style: TextStyle(
                      fontWeight: selectedSortOption == "Name Asc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "Name Desc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Name Desc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Nom Z-A", style: TextStyle(
                      fontWeight: selectedSortOption == "Name Desc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "Référence Asc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Référence Asc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Référence A-Z", style: TextStyle(
                      fontWeight: selectedSortOption == "Référence Asc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "Référence Desc",
                child: Row(
                  children: [
                    if (selectedSortOption == "Référence Desc")
                      Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text("Référence Z-A", style: TextStyle(
                      fontWeight: selectedSortOption == "Référence Desc" ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
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
            ? ListView.builder(
                itemCount: 8,
                itemBuilder: (_, __) => const AlkShimmerListTile(),
              )
            : Column(
                children: [
                  // Drawer Header with gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade700,
                          Colors.purple.shade400,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Iconsax.category,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catégories',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Parcourir nos produits',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Breadcrumb navigation with improved styling
                  if (navigationStack.isNotEmpty)
                    Container(
                      color: Colors.purple.shade50,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.purple.shade700,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Retour vers ${navigationStack.last}',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.purple.shade300,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (var category
                            in categoriesController.mainCategories.entries)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: selectedCategoryId == category.value && navigationStack.isEmpty
                                  ? Colors.purple.shade50
                                  : Colors.transparent,
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                childrenPadding: EdgeInsets.only(left: 12),
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedCategoryId == category.value && navigationStack.isEmpty
                                        ? Colors.purple.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Iconsax.folder_2,
                                    color: selectedCategoryId == category.value && navigationStack.isEmpty
                                        ? Colors.purple.shade700
                                        : Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
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
                                  child: Text(
                                    category.key,
                                    style: TextStyle(
                                      fontWeight: selectedCategoryId == category.value && navigationStack.isEmpty
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: selectedCategoryId == category.value && navigationStack.isEmpty
                                          ? Colors.purple.shade700
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                iconColor: Colors.purple.shade700,
                                collapsedIconColor: Colors.grey.shade600,
                                children: [
                                  if (categoriesController.categoryTree
                                      .containsKey(category.value))
                                    for (var subcategory in categoriesController
                                        .categoryTree[category.value]!)
                                      Container(
                                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: selectedCategoryId == subcategory['id']
                                              ? Colors.purple.shade50
                                              : Colors.transparent,
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            dividerColor: Colors.transparent,
                                          ),
                                          child: ExpansionTile(
                                            tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                            childrenPadding: EdgeInsets.only(left: 8),
                                            leading: Container(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Iconsax.category_2,
                                                color: selectedCategoryId == subcategory['id']
                                                    ? Colors.purple.shade600
                                                    : Colors.grey.shade500,
                                                size: 16,
                                              ),
                                            ),
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
                                              child: Text(
                                                subcategory['name'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: selectedCategoryId == subcategory['id']
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: selectedCategoryId == subcategory['id']
                                                      ? Colors.purple.shade700
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                            iconColor: Colors.purple.shade600,
                                            collapsedIconColor: Colors.grey.shade500,
                                            children: [
                                              if (categoriesController.categoryTree
                                                  .containsKey(subcategory['id']))
                                                for (var subSubcategory
                                                    in categoriesController
                                                        .categoryTree[subcategory['id']]!)
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(6),
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
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(6),
                                                          color: selectedCategoryId == subSubcategory['id']
                                                              ? Colors.purple.shade50
                                                              : Colors.transparent,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Iconsax.arrow_right_3,
                                                              size: 14,
                                                              color: selectedCategoryId == subSubcategory['id']
                                                                  ? Colors.purple.shade600
                                                                  : Colors.grey.shade400,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                subSubcategory['name'],
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: selectedCategoryId == subSubcategory['id']
                                                                      ? FontWeight.w600
                                                                      : FontWeight.normal,
                                                                  color: selectedCategoryId == subSubcategory['id']
                                                                      ? Colors.purple.shade700
                                                                      : Colors.grey.shade600,
                                                                ),
                                                              ),
                                                            ),
                                                            if (selectedCategoryId == subSubcategory['id'])
                                                              Container(
                                                                padding: EdgeInsets.all(4),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.purple.shade600,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: Icon(
                                                                  Icons.check,
                                                                  size: 10,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                            ],
                                          ),
                                        ),
                                      )
                                ],
                              ),
                            ),
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
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Recherche',
                      prefixIcon: Icon(Iconsax.search_normal),
                      suffixIcon: searchTextController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                if (isSearching) {
                                  _clearSearch();
                                } else {
                                  searchTextController.clear();
                                  _removeOverlay();
                                }
                              },
                              tooltip: 'Effacer',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        _removeOverlay(); // Remove suggestions overlay
                        _searchProducts(query);
                        setState(() {
                          isSearchVisible = false; // Hide search bar after search
                        });
                      }
                    },
                    onChanged: (value) {
                      // Trigger rebuild to show/hide clear button
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
            // Active search and filter chips
            if (isSearching || selectedSortOption != "None")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isSearching)
                      Chip(
                        avatar: Icon(
                          Iconsax.search_normal,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Recherche: "$currentSearchQuery"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        onDeleted: () {
                          _clearSearch();
                        },
                        backgroundColor: Colors.purple,
                        deleteIconColor: Colors.white,
                      ),
                    if (selectedSortOption != "None")
                      Chip(
                        avatar: Icon(
                          Iconsax.filter,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          _getSortOptionLabel(selectedSortOption),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        onDeleted: () {
                          setState(() {
                            selectedSortOption = "None";
                            _applySorting();
                          });
                        },
                        backgroundColor: Colors.deepPurple.shade400,
                        deleteIconColor: Colors.white,
                      ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AlkSize.defaultSpace),
                      child: AlkShimmerProductGrid(itemCount: 6),
                    )
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

  /// Show QR scanner dialog
  void _showQrScanner(BuildContext context) {
    // Get NavigationController instance
    NavigationController? navigationController;
    try {
      navigationController = Get.find<NavigationController>();
    } catch (e) {
      navigationController = null;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: AlkQrScannerWidget(
              onQrCodeScanned: (String qrCode) async {
                // Close the scanner
                Navigator.of(context).pop();

                debugPrint('📱 QR Code scanned in Store: $qrCode');

                // Process the QR code
                if (navigationController != null) {
                  final qrController = QrNavigationController(navigationController);
                  final success = await qrController.processScannedCode(qrCode);
                  debugPrint('📱 QR Processing result: ${success ? "Success" : "Failed"}');
                } else {
                  debugPrint('❌ NavigationController not available');
                  // Show error message if NavigationController is not available
                  Get.snackbar(
                    'Erreur',
                    'Navigation non disponible',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                }
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }
}
