// lib/features/shop/controllers/category_product_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'dart:async';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class CategoryProductController {
  // --- Static Cache and State Management ---
  static final Map<int, List<Map<String, dynamic>>> _staticCachedProducts = {};
  static final Map<int, bool> _staticIsLoading = {};
  static final Map<int, String?> _staticError = {};
  static final Map<int, Completer<void>> _staticFetchCompleters = {};

  // --- Instance Variables ---
  final int categoryId;
  final int limit; // Target number of active products

  // --- Instantiate Dedicated Controllers ---
  final DiscountController _discountController = DiscountController();
  final TaxController _taxController = TaxController();
  final QuantityController _quantityController = QuantityController(); // Add QuantityController

  CategoryProductController({required this.categoryId, this.limit = 8});

  // --- Instance Getters ---
  bool get isLoading => _staticIsLoading[categoryId] ?? false;
  String? get error => _staticError[categoryId];
  List<Map<String, dynamic>>? get products => _staticCachedProducts[categoryId];

  // --- Static Clear Method ---
  static void clearCache() {
    _staticCachedProducts.clear();
    _staticIsLoading.clear();
    _staticError.clear();
    _staticFetchCompleters.clear();
    AlkLoggerHelper.debug("CategoryProductController static cache cleared.");
  }

  // --- New static method to fetch products from multiple categories ---
  static Future<List<Map<String, dynamic>>> fetchProductsFromCategories(
      List<int> categoryIds, int limit) async {
    List<Map<String, dynamic>> allProducts = [];
    List<Future<void>> fetchFutures = []; // To run fetches concurrently

    for (int currentCategoryId in categoryIds) {
      // Check cache first
      if (_staticCachedProducts.containsKey(currentCategoryId)) {
        // Add cached products directly (will be sorted later)
        allProducts.addAll(_staticCachedProducts[currentCategoryId] ?? []);
      } else {
        // If not cached and not already fetching, start the fetch
        if (!_staticFetchCompleters.containsKey(currentCategoryId)) {

          final controller = CategoryProductController(categoryId: currentCategoryId, limit: limit);
          // Add the future to the list, don't await here
          fetchFutures.add(controller.fetchCategoryProducts());
        } else {
          // If already fetching, just add its completer's future
          fetchFutures.add(_staticFetchCompleters[currentCategoryId]!.future);
        }
      }
    }

    // Wait for all necessary fetches to complete
    if (fetchFutures.isNotEmpty) {
      await Future.wait(fetchFutures);

      // After fetches are done, gather products from newly populated cache entries
      for (int currentCategoryId in categoryIds) {
        if (!_staticCachedProducts.containsKey(currentCategoryId)) {
           allProducts.addAll(_staticCachedProducts[currentCategoryId] ?? []);
        }
      }
       // Alternative: Clear and rebuild after await to avoid duplicates
       allProducts.clear();
       for (int currentCategoryId in categoryIds) {
         if (_staticCachedProducts.containsKey(currentCategoryId)) {
           allProducts.addAll(_staticCachedProducts[currentCategoryId] ?? []);
         }
       }
    }


    // --- Post-Processing ---
    // 1. Remove Duplicates (if a product exists in multiple fetched categories)
    final uniqueProductIds = <int>{};
    final uniqueProducts = <Map<String, dynamic>>[];
    for (var product in allProducts) {
      int? productId = int.tryParse(product['id']?.toString() ?? '');
      if (productId != null && uniqueProductIds.add(productId)) {
        uniqueProducts.add(product);
      }
    }
    allProducts = uniqueProducts;

    // 2. Sort by ID descending
    allProducts.sort((a, b) {
       int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
       int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
       return idB.compareTo(idA);
    });

    // 3. Apply limit
    List<Map<String, dynamic>> limitedProducts = allProducts.take(limit).toList();

    return limitedProducts;
  }


  // --- Existing Fetch Logic for a single category ---
  Future<void> fetchCategoryProducts() async {
    // Check if already loading or completed
    if (_staticFetchCompleters.containsKey(categoryId)) {
      await _staticFetchCompleters[categoryId]!.future;
      return;
    }
    // Check cache
    if (_staticCachedProducts.containsKey(categoryId)) {
      _staticIsLoading[categoryId] = false;
      _staticError[categoryId] = null;
      return;
    }

    // Create Completer and set initial state
    final completer = Completer<void>();
    _staticFetchCompleters[categoryId] = completer;
    _staticIsLoading[categoryId] = true;
    _staticError[categoryId] = null;

    List<Map<String, dynamic>> activeProductsFound = [];
    List<Map<String, dynamic>> productsToProcess = [];

    try {
      final ProductListCategory productListCategory = ProductListCategory();

      // Step 1: Fetch ALL Product IDs
      List<int> allProductIds = await productListCategory.fetchProductIdsFromCategory(categoryId);
      if (allProductIds.isEmpty) {
        _staticCachedProducts[categoryId] = [];
        completer.complete();
        _staticIsLoading[categoryId] = false;
        return;
      }

      // Step 2: Loop Fetching Details in Batches
      int currentIdIndex = 0;
      const int batchSize = 10; // Keep batch size reasonable
      while (activeProductsFound.length < limit && currentIdIndex < allProductIds.length) {
        int endIndex = currentIdIndex + batchSize;
        if (endIndex > allProductIds.length) endIndex = allProductIds.length;
        List<int> batchIds = allProductIds.sublist(currentIdIndex, endIndex);
        if (batchIds.isEmpty) break;

        String idFilter = batchIds.join('|');
        final productDetailsApi = 'https://www.alkirtas.com/api/products?display=full&filter[id]=[$idFilter]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';
        final response = await http.get(Uri.parse(productDetailsApi));
        currentIdIndex = endIndex; // Move index

        if (response.statusCode != 200) {
          AlkLoggerHelper.warning("Failed to load product details batch (Status: ${response.statusCode}). Skipping batch.");
          continue;
        }
        final productData = json.decode(utf8.decode(response.bodyBytes));
        if (productData == null || !productData.containsKey('products') || productData['products'] == null) {
          AlkLoggerHelper.warning("No product details returned in batch. Skipping batch.");
          continue;
        }

        List<Map<String, dynamic>> rawProductsBatch = List<Map<String, dynamic>>.from(productData['products']);

        // Filter for active and add to list
        for (var product in rawProductsBatch) {
          if (product.containsKey('active') && product['active'].toString() == '1') {
            if (activeProductsFound.length < limit) {
              // Add to temporary list for processing, not directly to final list yet
              productsToProcess.add(product);
            } else {
              break; // Stop checking this batch
            }
          }
        }
        if (productsToProcess.length >= limit) {
           break; // Stop fetching more batches
        }
      } // End while loop

      // --- Step 3: Process Details for Found Potential Active Products ---
      if (productsToProcess.isNotEmpty) {
        List<Future<void>> processingTasks = [];
        for (var product in productsToProcess) {
           processingTasks.add(_processProductDetails(product).then((processedProduct) {
             if (activeProductsFound.length < limit) {
                activeProductsFound.add(processedProduct);
             }
           }));
        }
        await Future.wait(processingTasks);
      }

      // Step 4: Cache the final list of processed, active products
      _staticCachedProducts[categoryId] = activeProductsFound;
      AlkLoggerHelper.debug("Category $categoryId: ${activeProductsFound.length} products cached");
      completer.complete();

    } catch (e, stacktrace) {
      AlkLoggerHelper.error('Error during product fetch/process loop for category $categoryId: $e', stacktrace);
      _staticError[categoryId] = 'Failed to load products: $e';
      _staticCachedProducts.remove(categoryId); // Clear potentially partial cache
      if (!completer.isCompleted) completer.completeError(e); // Complete with error if not already done
    } finally {
      _staticIsLoading[categoryId] = false;
       // Ensure completer is removed if fetch failed before completion
      if (!_staticFetchCompleters[categoryId]!.isCompleted) {
         _staticFetchCompleters.remove(categoryId);
      }
    }
  }

  // --- Helper Method: _processProductDetails (Returns the processed product map) ---
  Future<Map<String, dynamic>> _processProductDetails(Map<String, dynamic> product) async {
    try {
      int productId = int.tryParse(product['id'].toString()) ?? 0;
      double priceHT = double.tryParse(product['price'].toString()) ?? 0.0;
      dynamic taxRulesGroupId = product['id_tax_rules_group'];

      if (productId == 0) {
        AlkLoggerHelper.warning("Skipping detail processing for product with invalid ID: ${product['id']}");
        // Return product as is, maybe with default error values?
        product['discount'] = 0.0;
        product['ttc_price'] = priceHT;
        product['image_urls'] = <String>[];
        product['default_image_url'] = constructImageUrl(null);
        return product;
      }

      List<Future<void>> tasks = [];

      // Fetch discount
      tasks.add(_discountController.fetchDiscount(productId).then((discountData) {
        if (discountData != null && discountData['reduction_type'] == 'percentage') {
          double reductionValue = double.tryParse(discountData['reduction'].toString()) ?? 0.0;
          product['discount'] = reductionValue;
        } else {
          product['discount'] = 0.0;
        }
      }));

      // Fetch TTC price
      tasks.add(_taxController.fetchTTCPrice(productId, priceHT, taxRulesGroupId)
          .then((ttcPrice) {
        product['ttc_price'] = ttcPrice ?? priceHT;
      }));

      // Process Image URLs
      tasks.add(Future(() {
        if (product.containsKey('associations') &&
            product['associations'].containsKey('images')) {
          final images = product['associations']['images'] as List;
          List<String> imageUrls =
              images.map((image) => constructImageUrl(image['id'])).toList();
          product['image_urls'] = imageUrls;
        } else {
          product['image_urls'] = <String>[];
        }
        product['default_image_url'] = constructImageUrl(product['id_default_image']);
      }));

      // Fetch actual quantity
      tasks.add(_quantityController.fetchQuantity(productId).then((fetchedStock) {
        // Store as string to match existing data structure expectations
        product['quantity'] = fetchedStock?.toString() ?? '0';
      }));

      await Future.wait(tasks);

    } catch (e) {
      AlkLoggerHelper.error("Error processing product details via external controllers for ${product['id']}", e);
      // Apply default values on error to avoid null issues downstream
      product['discount'] ??= 0.0;
      product['ttc_price'] ??= double.tryParse(product['price'].toString()) ?? 0.0;
      product['image_urls'] ??= <String>[];
      product['quantity'] ??= '0'; // Ensure quantity has a default if fetch failed
      product['default_image_url'] ??= constructImageUrl(product['id_default_image']);
    }
    // Return the modified product map
    return product;
  }

  // --- Image URL construction (remains internal) ---
  String constructImageUrl(dynamic imageId) {
    if (imageId == null || imageId.toString().isEmpty || imageId.toString() == '0') {
       return 'https://via.placeholder.com/150?text=No+Image';
    }
    final imageIdStr = imageId.toString();
    // Basic path construction, adjust if your Prestashop uses a different structure
    final path = imageIdStr.split('').join('/');
    return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
  }

  // --- Description cleaning (remains internal static method) ---
  static String cleanDescription(String? description) {
    if (description == null || description.isEmpty) return "No description available";
    try {
      final document = htmlParser.parse(description);
      String cleanText = document.body?.text ?? "";
      // Replace multiple whitespace characters (including newlines, tabs) with a single space
      cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
      return cleanText.isEmpty ? "No description available" : cleanText;
    } catch (e) {
      AlkLoggerHelper.error("Error cleaning description", e);
      return "No description available"; // Fallback on parsing error
    }
  }
}
