// lib/features/shop/controllers/category_product_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'dart:async';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class CategoryProductController {
  // --- Static Cache and State Management ---
  static final Map<int, List<Map<String, dynamic>>> _staticCachedProducts = {};
  static final Map<int, bool> _staticIsLoading = {};
  static final Map<int, String?> _staticError = {};
  static final Map<int, Completer<void>> _staticFetchCompleters = {};

  // Flag to use enriched API (set to true after module is installed)
  static bool useEnrichedApi = true;

  // --- Instance Variables ---
  final int categoryId;
  final int limit; // Target number of active products

  // --- Instantiate Dedicated Controllers (fallback when enriched API unavailable) ---
  final DiscountController _discountController = DiscountController();
  final TaxController _taxController = TaxController();
  final QuantityController _quantityController = QuantityController();

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

    try {
      // OPTIMIZED PATH: Use enriched API to get only active product IDs + enrichment data
      if (useEnrichedApi) {
        final enrichedProducts = await ProductEnrichedService.fetchEnrichedByCategory(
          categoryId,
          limit: limit,
          offset: 0,
        );

        if (enrichedProducts.isNotEmpty) {
          AlkLoggerHelper.debug("Enriched API returned ${enrichedProducts.length} active products for category $categoryId (home)");

          // Extract product IDs from enriched data
          final List<int> activeProductIds = enrichedProducts
              .map((p) => int.tryParse(p['id_product'].toString()) ?? 0)
              .where((id) => id > 0)
              .toList();

          if (activeProductIds.isNotEmpty) {
            // Index enriched data by product ID for O(1) lookup
            final Map<int, Map<String, dynamic>> enrichedIndex = {};
            for (var enriched in enrichedProducts) {
              final id = int.tryParse(enriched['id_product'].toString()) ?? 0;
              if (id > 0) {
                enrichedIndex[id] = enriched;
              }
            }

            // Fetch full product details from PrestaShop API (single batch call)
            final String productIdsParam = activeProductIds.join('|');
            final productDetailsApi = 'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsParam]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

            AlkLoggerHelper.debug("Fetching full details for ${activeProductIds.length} products (home)");
            final response = await http.get(Uri.parse(productDetailsApi));

            if (response.statusCode == 200) {
              final productData = json.decode(utf8.decode(response.bodyBytes));
              if (productData != null && productData.containsKey('products') && productData['products'] != null) {
                List<Future<void>> processingTasks = [];
                for (var product in productData['products']) {
                  if (product is Map<String, dynamic>) {
                    final productId = int.tryParse(product['id'].toString()) ?? 0;
                    final enriched = enrichedIndex[productId];
                    processingTasks.add(_processProductDetails(product, enriched: enriched).then((processedProduct) {
                      if (activeProductsFound.length < limit) {
                        activeProductsFound.add(processedProduct);
                      }
                    }));
                  }
                }
                await Future.wait(processingTasks);
              }
            }
          }

          // Cache and return if we got results
          if (activeProductsFound.isNotEmpty) {
            _staticCachedProducts[categoryId] = activeProductsFound;
            AlkLoggerHelper.debug("Category $categoryId: ${activeProductsFound.length} products cached (optimized)");
            completer.complete();
            return;
          }
        }

        AlkLoggerHelper.debug("Enriched API returned no products for category $categoryId, falling back to legacy method");
      }

      // FALLBACK PATH: Legacy method (fetch all IDs, loop through batches)
      final ProductListCategory productListCategory = ProductListCategory();
      List<Map<String, dynamic>> productsToProcess = [];

      List<int> allProductIds = await productListCategory.fetchProductIdsFromCategory(categoryId);
      if (allProductIds.isEmpty) {
        _staticCachedProducts[categoryId] = [];
        completer.complete();
        _staticIsLoading[categoryId] = false;
        return;
      }

      int currentIdIndex = 0;
      const int batchSize = 20;
      while (productsToProcess.length < limit && currentIdIndex < allProductIds.length) {
        int endIndex = currentIdIndex + batchSize;
        if (endIndex > allProductIds.length) endIndex = allProductIds.length;
        List<int> batchIds = allProductIds.sublist(currentIdIndex, endIndex);
        if (batchIds.isEmpty) break;

        String idFilter = batchIds.join('|');
        final productDetailsApi = 'https://www.alkirtas.com/api/products?display=full&filter[id]=[$idFilter]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';
        final response = await http.get(Uri.parse(productDetailsApi));
        currentIdIndex = endIndex;

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

        for (var product in rawProductsBatch) {
          if (product.containsKey('active') && product['active'].toString() == '1') {
            if (productsToProcess.length < limit) {
              productsToProcess.add(product);
            } else {
              break;
            }
          }
        }
        if (productsToProcess.length >= limit) {
          break;
        }
      }

      if (productsToProcess.isNotEmpty) {
        Map<int, Map<String, dynamic>> enrichedData = {};
        if (useEnrichedApi) {
          final productIds = productsToProcess
              .map((p) => int.tryParse(p['id'].toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
          enrichedData = await ProductEnrichedService.fetchEnrichedByIds(productIds);
          AlkLoggerHelper.debug("Fetched enriched data for ${enrichedData.length} products (home fallback)");
        }

        List<Future<void>> processingTasks = [];
        for (var product in productsToProcess) {
          final productId = int.tryParse(product['id'].toString()) ?? 0;
          final enriched = enrichedData[productId];
          processingTasks.add(_processProductDetails(product, enriched: enriched).then((processedProduct) {
            if (activeProductsFound.length < limit) {
              activeProductsFound.add(processedProduct);
            }
          }));
        }
        await Future.wait(processingTasks);
      }

      _staticCachedProducts[categoryId] = activeProductsFound;
      AlkLoggerHelper.debug("Category $categoryId: ${activeProductsFound.length} products cached (legacy)");
      completer.complete();

    } catch (e, stacktrace) {
      AlkLoggerHelper.error('Error during product fetch/process loop for category $categoryId: $e', stacktrace);
      _staticError[categoryId] = 'Failed to load products: $e';
      _staticCachedProducts.remove(categoryId);
      if (!completer.isCompleted) completer.completeError(e);
    } finally {
      _staticIsLoading[categoryId] = false;
      if (!_staticFetchCompleters[categoryId]!.isCompleted) {
        _staticFetchCompleters.remove(categoryId);
      }
    }
  }

  // --- Helper Method: _processProductDetails (Returns the processed product map) ---
  Future<Map<String, dynamic>> _processProductDetails(
    Map<String, dynamic> product, {
    Map<String, dynamic>? enriched,
  }) async {
    try {
      int productId = int.tryParse(product['id'].toString()) ?? 0;
      double priceHT = double.tryParse(product['price'].toString()) ?? 0.0;
      dynamic taxRulesGroupId = product['id_tax_rules_group'];

      if (productId == 0) {
        AlkLoggerHelper.warning("Skipping detail processing for product with invalid ID: ${product['id']}");
        product['discount'] = 0.0;
        product['ttc_price'] = priceHT;
        product['image_urls'] = <String>[];
        product['default_image_url'] = constructImageUrl(null);
        return product;
      }

      // Use enriched data if available (single API call), otherwise fallback to individual calls
      if (enriched != null && useEnrichedApi) {
        // Apply pre-calculated enriched data (no additional API calls!)
        ProductEnrichedService.applyEnrichedData(product, enriched);
        // Convert quantity to string to match existing data structure
        product['quantity'] = product['quantity'].toString();
      } else {
        // Fallback: individual API calls (old method)
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

        // Fetch actual quantity
        tasks.add(_quantityController.fetchQuantity(productId).then((fetchedStock) {
          product['quantity'] = fetchedStock?.toString() ?? '0';
        }));

        await Future.wait(tasks);
      }

      // Process Image URLs (always needed, not in enriched data)
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

    } catch (e) {
      AlkLoggerHelper.error("Error processing product details via external controllers for ${product['id']}", e);
      // Apply default values on error to avoid null issues downstream
      product['discount'] ??= 0.0;
      product['ttc_price'] ??= double.tryParse(product['price'].toString()) ?? 0.0;
      product['image_urls'] ??= <String>[];
      product['quantity'] ??= '0';
      product['default_image_url'] ??= constructImageUrl(product['id_default_image']);
    }
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
