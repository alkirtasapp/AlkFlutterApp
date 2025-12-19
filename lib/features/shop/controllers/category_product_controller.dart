// lib/features/shop/controllers/category_product_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'dart:async';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart'; // Import QuantityController
import 'package:alkirtas/config/app_config.dart';

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
    print("🧹 CategoryProductController static cache cleared.");
  }

  // --- New static method to fetch products from multiple categories ---
  static Future<List<Map<String, dynamic>>> fetchProductsFromCategories(
      List<int> categoryIds, int limit) async {
    List<Map<String, dynamic>> allProducts = [];
    List<Future<void>> fetchFutures = []; // To run fetches concurrently

    print("🔄 Starting multi-category fetch for IDs: $categoryIds (Limit: $limit)");

    for (int currentCategoryId in categoryIds) {
      // Check cache first
      if (_staticCachedProducts.containsKey(currentCategoryId)) {
        print("✅ Cache hit for Category ID: $currentCategoryId in multi-fetch.");
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
          print("⏳ Awaiting existing fetch for Category ID: $currentCategoryId in multi-fetch.");
          fetchFutures.add(_staticFetchCompleters[currentCategoryId]!.future);
        }
      }
    }

    // Wait for all necessary fetches to complete
    if (fetchFutures.isNotEmpty) {
      print("⏳ Waiting for ${fetchFutures.length} fetch operations to complete...");
      await Future.wait(fetchFutures);
      print("✅ All fetch operations completed.");

      // After fetches are done, gather products from newly populated cache entries
      for (int currentCategoryId in categoryIds) {
        // Only add if not already added from cache initially
        if (!_staticCachedProducts.containsKey(currentCategoryId)) {
           // This check might be redundant if fetch always populates, but safe
           print("➕ Adding newly fetched products for Category ID: $currentCategoryId");
           allProducts.addAll(_staticCachedProducts[currentCategoryId] ?? []);
        } else {
           // Check if it was added *during* the await phase (unlikely but possible)
           // A simpler approach is to rebuild the list *after* await
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
     print("🔍 Found ${allProducts.length} products initially, ${uniqueProducts.length} unique products after filtering.");
    allProducts = uniqueProducts;


    // 2. Sort by ID descending (as requested)
    // Ensure 'id' is treated as a number for sorting
    allProducts.sort((a, b) {
       int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
       int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
       return idB.compareTo(idA); // Descending order
    });
    print("📊 Sorted unique products by ID descending.");

    // 3. Apply limit
    List<Map<String, dynamic>> limitedProducts = allProducts.take(limit).toList();
    print("✂️ Limited results to $limit products. Final count: ${limitedProducts.length}");

    return limitedProducts;
  }


  // --- Existing Fetch Logic for a single category (Remains the same) ---
  Future<void> fetchCategoryProducts() async {
    // Check if already loading or completed
    if (_staticFetchCompleters.containsKey(categoryId)) {
      print("ℹ️ Fetch already in progress or completed for Category ID: $categoryId. Awaiting completion.");
      await _staticFetchCompleters[categoryId]!.future;
      return;
    }
    // Check cache
    if (_staticCachedProducts.containsKey(categoryId)) {
      print("✅ Cache hit for Category ID: $categoryId. Skipping fetch.");
      _staticIsLoading[categoryId] = false;
      _staticError[categoryId] = null;
      return;
    }

    // Create Completer and set initial state
    final completer = Completer<void>();
    _staticFetchCompleters[categoryId] = completer;
    _staticIsLoading[categoryId] = true;
    _staticError[categoryId] = null;

    print("🔄 Starting product fetch loop for Category ID: $categoryId (Target: $limit active)...");

    List<Map<String, dynamic>> activeProductsFound = [];
    List<Map<String, dynamic>> productsToProcess = [];

    try {
      final ProductListCategory productListCategory = ProductListCategory();

      // Step 1: Fetch ALL Product IDs
      print("📡 Fetching ALL product IDs for Category ID: $categoryId using ProductListCategory...");
      List<int> allProductIds = await productListCategory.fetchProductIdsFromCategory(categoryId);
      if (allProductIds.isEmpty) {
        print("ℹ️ No product IDs found for Category ID: $categoryId via ProductListCategory.");
        _staticCachedProducts[categoryId] = [];
        completer.complete();
        _staticIsLoading[categoryId] = false;
        return;
      }
      print("✅ Found ${allProductIds.length} total product IDs for Category ID: $categoryId.");

      // Step 2: Loop Fetching Details in Batches
      int currentIdIndex = 0;
      const int batchSize = 10; // Keep batch size reasonable
      while (activeProductsFound.length < limit && currentIdIndex < allProductIds.length) {
        int endIndex = currentIdIndex + batchSize;
        if (endIndex > allProductIds.length) endIndex = allProductIds.length;
        List<int> batchIds = allProductIds.sublist(currentIdIndex, endIndex);
        if (batchIds.isEmpty) break;

        print(" -> Fetching details batch (${currentIdIndex + 1}-${endIndex}) for Category ID: $categoryId...");
        String idFilter = batchIds.join('|');
        final productDetailsApi = 'https://www.alkirtas.com/api/products?display=full&filter[id]=[$idFilter]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';
        final response = await http.get(Uri.parse(productDetailsApi));
        currentIdIndex = endIndex; // Move index

        if (response.statusCode != 200) {
          print(" ⚠️ Failed to load product details batch (Status: ${response.statusCode}). Skipping batch.");
          continue;
        }
        final productData = json.decode(utf8.decode(response.bodyBytes));
        if (productData == null || !productData.containsKey('products') || productData['products'] == null) {
          print(" ⚠️ No product details returned in batch. Skipping batch.");
          continue;
        }

        List<Map<String, dynamic>> rawProductsBatch = List<Map<String, dynamic>>.from(productData['products']);
        print(" ✅ Received details for ${rawProductsBatch.length} products in batch.");

        // Filter for active and add to list
        for (var product in rawProductsBatch) {
          if (product.containsKey('active') && product['active'].toString() == '1') {
            if (activeProductsFound.length < limit) {
              // Add to temporary list for processing, not directly to final list yet
              productsToProcess.add(product);
              print(" + Found potential active product ${product['id']}. Total potential: ${productsToProcess.length}");
            } else {
              print(" - Limit ($limit) reached for potential products. Stopping search within batch.");
              break; // Stop checking this batch
            }
          }
        }
        if (productsToProcess.length >= limit) {
           print(" 🏁 Target of $limit potential active products reached. Stopping fetch loop.");
           break; // Stop fetching more batches
        }
      } // End while loop

      // --- Step 3: Process Details for Found Potential Active Products ---
      if (productsToProcess.isNotEmpty) {
        print("⚙️ Processing details for ${productsToProcess.length} potential active products found...");
        List<Future<void>> processingTasks = [];
        for (var product in productsToProcess) {
          // Process details and add the processed product to the final list
           processingTasks.add(_processProductDetails(product).then((processedProduct) {
             // Only add if processing didn't fail implicitly and limit not reached
             if (activeProductsFound.length < limit) {
                activeProductsFound.add(processedProduct);
                print(" ++ Added processed active product ${processedProduct['id']}. Total active: ${activeProductsFound.length}");
             }
           }));
        }
        await Future.wait(processingTasks);
         print("✅ Processing tasks completed for category $categoryId.");
      } else {
        print("ℹ️ No potential active products found to process details for Category ID: $categoryId.");
      }

      // Step 4: Cache the final list of processed, active products
      _staticCachedProducts[categoryId] = activeProductsFound; // Cache the processed list
      print("✅✅ Successfully fetched and processed ${activeProductsFound.length} active products for Category ID: $categoryId (Target was $limit).");
      completer.complete();

    } catch (e, stacktrace) {
      print('❌❌ Error during product fetch/process loop for category $categoryId: $e');
      print(stacktrace); // Print stacktrace for debugging
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
        print("❌ Skipping detail processing for product with invalid ID: ${product['id']}");
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
      print("❌ Error processing product details via external controllers for ${product['id']}: $e");
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
      print("Error cleaning description: $e");
      return "No description available"; // Fallback on parsing error
    }
  }
}
