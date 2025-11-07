import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../data/controllers/search_controller.dart';
import '../../../controllers/categories_store_controller.dart';
import '../../../controllers/product_controller_store.dart';

/// Controller to manage store screen state and business logic
/// Handles product fetching, search, sorting, and category navigation
class StoreController extends ChangeNotifier {
  // Controllers
  final CategoriesStoreController categoriesController = CategoriesStoreController();
  final ProductControllerStore productController = ProductControllerStore();
  final AlkSearchController searchController = AlkSearchController();

  // State variables
  String selectedCategory = "";
  int selectedCategoryId = -1;
  bool isLoading = true;
  bool isFetchingMore = false;
  bool isSearching = false;
  List<Map<String, dynamic>> products = [];
  Set<int> fetchedProductIds = {};
  int offset = 0;
  final int limit = 10;
  String currentSearchQuery = "";
  String selectedSortOption = "None";

  // Navigation stack for breadcrumbs
  List<String> navigationStack = [];
  List<int> categoryIdStack = [];

  // Search suggestions
  List<String> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;

  List<String> get searchSuggestions => _searchSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Initialize categories and load first category
  Future<void> initializeCategories({int? initialCategoryId, String? initialCategoryName}) async {
    await categoriesController.fetchAllCategories();
    if (categoriesController.mainCategories.isNotEmpty) {
      selectedCategory = initialCategoryName ?? categoriesController.mainCategories.keys.first;
      selectedCategoryId = initialCategoryId ?? categoriesController.mainCategories.values.first;
      notifyListeners();
      await fetchProductsForCategory(selectedCategoryId);
    }
  }

  /// Fetch products for a specific category
  Future<void> fetchProductsForCategory(int categoryId) async {
    isLoading = true;
    products.clear();
    fetchedProductIds.clear();
    offset = 0;
    isSearching = false;
    selectedSortOption = "None";
    notifyListeners();

    print("📡 Fetching products for Category ID: $categoryId, Offset: $offset");

    final List<Map<String, dynamic>> validProducts =
        await productController.fetchProductDataStore(categoryId, offset, limit) ?? [];

    if (validProducts.isNotEmpty) {
      for (var product in validProducts) {
        if (!fetchedProductIds.contains(product['id'])) {
          products.add(product);
          fetchedProductIds.add(product['id']);
        }
      }
      offset += validProducts.length;
      _applySorting();
      print("✅ Fetched ${validProducts.length} products for Category ID: $categoryId");
    } else {
      print("⚠️ No valid products found for Category ID: $categoryId");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load more products for current category
  Future<void> loadMoreProducts() async {
    if (isFetchingMore) return;

    isFetchingMore = true;
    notifyListeners();

    final List<int> allProductIds =
        await productController.productListCategory.fetchProductIdsFromCategory(selectedCategoryId);

    int remaining = allProductIds.length - offset;
    print("🔎 Found $remaining products remaining on category ID $selectedCategoryId");

    final List<int> nextBatchIds = allProductIds.skip(offset).take(limit * 5).toList();

    if (nextBatchIds.isEmpty) {
      print("⚠️ No more products to load for Category ID: $selectedCategoryId");
      isFetchingMore = false;
      notifyListeners();
      return;
    }

    final List<Map<String, dynamic>>? moreProducts =
        await productController.fetchProductsByIds(nextBatchIds);

    final activeProducts = moreProducts?.where((p) => p['active'].toString() == '1').toList() ?? [];

    if (activeProducts.isNotEmpty) {
      for (var product in activeProducts) {
        if (!fetchedProductIds.contains(product['id'])) {
          products.add(product);
          fetchedProductIds.add(product['id']);
        }
      }
      offset += nextBatchIds.length;
      _applySorting();
      print("✅ Displayed ${activeProducts.length} products, ${allProductIds.length - offset} remaining");
    } else {
      print("⚠️ No more active products found for Category ID: $selectedCategoryId");
      offset += nextBatchIds.length;
    }

    isFetchingMore = false;
    notifyListeners();
  }

  /// Search products by query
  Future<void> searchProducts(String query) async {
    isLoading = true;
    products.clear();
    fetchedProductIds.clear();
    isSearching = true;
    offset = 0;
    currentSearchQuery = query;
    selectedSortOption = "None";
    _searchSuggestions = [];
    notifyListeners();

    final List<int>? productIds =
        await searchController.searchProducts(query, offset: offset, limit: 100);

    if (productIds != null && productIds.isNotEmpty) {
      final List<Map<String, dynamic>>? searchedProducts =
          await productController.fetchProductsByIds(productIds);

      if (searchedProducts != null && searchedProducts.isNotEmpty) {
        for (var product in searchedProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += searchedProducts.length;
        _applySorting();
        print("✅ Displaying first ${searchedProducts.length} search results.");
      } else {
        print("⚠️ No valid product details found.");
      }
    } else {
      print("⚠️ No product IDs returned from search.");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load more search results
  Future<void> loadMoreSearchResults() async {
    if (isFetchingMore) return;

    isFetchingMore = true;
    notifyListeners();

    print("📡 Loading more search results for query: $currentSearchQuery, Offset: $offset");

    final List<int>? productIds =
        await searchController.searchProducts(currentSearchQuery, offset: offset, limit: 100);

    if (productIds != null && productIds.isNotEmpty) {
      final List<Map<String, dynamic>>? moreSearchedProducts =
          await productController.fetchProductsByIds(productIds);

      if (moreSearchedProducts != null && moreSearchedProducts.isNotEmpty) {
        for (var product in moreSearchedProducts) {
          if (!fetchedProductIds.contains(product['id'])) {
            products.add(product);
            fetchedProductIds.add(product['id']);
          }
        }
        offset += productIds.length;
        _applySorting();
        print("✅ Loaded ${moreSearchedProducts.length} more products for query: $currentSearchQuery");
      } else {
        print("⚠️ No more products found for query: $currentSearchQuery");
      }
    } else {
      print("⚠️ No more product IDs found for query: $currentSearchQuery");
    }

    isFetchingMore = false;
    notifyListeners();
  }

  /// Fetch search suggestions for autocomplete
  Future<void> fetchSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    _isLoadingSuggestions = true;
    notifyListeners();

    final List<int>? productIds =
        await searchController.searchProducts(query, offset: 0, limit: 10);

    if (productIds != null && productIds.isNotEmpty) {
      final List<Map<String, dynamic>>? suggestedProducts =
          await productController.fetchProductsByIds(productIds);

      if (suggestedProducts != null && suggestedProducts.isNotEmpty) {
        _searchSuggestions =
            suggestedProducts.map((p) => p['name'].toString()).toSet().toList();
      } else {
        _searchSuggestions = [];
      }
    } else {
      _searchSuggestions = [];
    }

    _isLoadingSuggestions = false;
    notifyListeners();
  }

  /// Clear search and return to category view
  void clearSearch() {
    isSearching = false;
    currentSearchQuery = "";
    products.clear();
    fetchedProductIds.clear();
    offset = 0;
    _searchSuggestions = [];
    notifyListeners();
    fetchProductsForCategory(selectedCategoryId);
  }

  /// Clear search suggestions
  void clearSearchSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  /// Apply selected sorting option
  void _applySorting() {
    if (selectedSortOption == "Price Asc") {
      products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSortOption == "Price Desc") {
      products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (selectedSortOption == "Name Asc") {
      products.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else if (selectedSortOption == "Name Desc") {
      products.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
    } else if (selectedSortOption == "Référence Asc") {
      products.sort((a, b) => (a['reference'] as String).compareTo(b['reference'] as String));
    } else if (selectedSortOption == "Référence Desc") {
      products.sort((a, b) => (b['reference'] as String).compareTo(a['reference'] as String));
    }
  }

  /// Update sorting option and re-sort
  void updateSortOption(String option) {
    selectedSortOption = option;
    _applySorting();
    notifyListeners();
  }

  /// Select a category and fetch its products
  void selectCategory(String categoryName, int categoryId) {
    selectedCategory = categoryName;
    selectedCategoryId = categoryId;
    navigationStack.clear();
    categoryIdStack.clear();
    notifyListeners();
    fetchProductsForCategory(categoryId);
  }

  /// Navigate to subcategory
  void navigateToSubcategory(String parentName, int parentId, String subcategoryName, int subcategoryId) {
    navigationStack.clear();
    categoryIdStack.clear();
    navigationStack.add(parentName);
    categoryIdStack.add(parentId);
    selectedCategory = subcategoryName;
    selectedCategoryId = subcategoryId;
    notifyListeners();
    fetchProductsForCategory(subcategoryId);
  }

  /// Navigate to sub-subcategory
  void navigateToSubSubcategory(
    String parentName,
    int parentId,
    String subcategoryName,
    int subcategoryId,
    String subSubcategoryName,
    int subSubcategoryId,
  ) {
    navigationStack.clear();
    categoryIdStack.clear();
    navigationStack.add(parentName);
    categoryIdStack.add(parentId);
    navigationStack.add(subcategoryName);
    categoryIdStack.add(subcategoryId);
    selectedCategory = subSubcategoryName;
    selectedCategoryId = subSubcategoryId;
    notifyListeners();
    fetchProductsForCategory(subSubcategoryId);
  }

  /// Navigate back in category hierarchy
  void navigateBack() {
    if (navigationStack.isEmpty) return;

    String parentCategory = navigationStack.last;
    int parentCategoryId = categoryIdStack.last;
    navigationStack.removeLast();
    categoryIdStack.removeLast();
    selectedCategory = parentCategory;
    selectedCategoryId = parentCategoryId;
    notifyListeners();
    fetchProductsForCategory(selectedCategoryId);
  }

  /// Get localized sort option label
  String getSortOptionLabel(String option) {
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

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}
