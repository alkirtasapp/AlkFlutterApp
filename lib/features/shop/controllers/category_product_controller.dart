// d:\flutter\test\lib\features\shop\controllers\category_product_controller.dart (Modified with Looping Fetch)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'dart:async'; // Import for Completer/Future

class CategoryProductController {
  // --- Static Cache and State Management (Unchanged) ---
  static final Map<int, List<Map<String, dynamic>>> _staticCachedProducts = {};
  static final Map<int, bool> _staticIsLoading = {};
  static final Map<int, String?> _staticError = {};
  static final Map<int, Completer<void>> _staticFetchCompleters = {};

  // --- Instance Variables (Unchanged) ---
  final int categoryId;
  final int limit; // This now represents the TARGET number of active products (e.g., 8)

  CategoryProductController({required this.categoryId, this.limit = 8});

  // --- Instance Getters (Unchanged) ---
  bool get isLoading => _staticIsLoading[categoryId] ?? false;
  String? get error => _staticError[categoryId];
  List<Map<String, dynamic>>? get products => _staticCachedProducts[categoryId];

  // --- Static Clear Method (Unchanged) ---
  static void clearCache() {
    _staticCachedProducts.clear();
    _staticIsLoading.clear();
    _staticError.clear();
    _staticFetchCompleters.clear();
    print("🧹 CategoryProductController static cache cleared.");
  }

  // --- Fetch Logic (Modified for Looping Fetch to reach limit) ---
  Future<void> fetchCategoryProducts() async {
    // Check if already loading or completed (Unchanged)
    if (_staticFetchCompleters.containsKey(categoryId)) {
      print("ℹ️ Fetch already in progress or completed for Category ID: $categoryId. Awaiting completion.");
      await _staticFetchCompleters[categoryId]!.future;
      return;
    }
    // Check cache (Unchanged)
    if (_staticCachedProducts.containsKey(categoryId)) {
      print("✅ Cache hit for Category ID: $categoryId. Skipping fetch.");
      _staticIsLoading[categoryId] = false;
      _staticError[categoryId] = null;
      return;
    }

    // Create Completer and set initial state (Unchanged)
    final completer = Completer<void>();
    _staticFetchCompleters[categoryId] = completer;
    _staticIsLoading[categoryId] = true;
    _staticError[categoryId] = null;

    print("🔄 Starting product fetch loop for Category ID: $categoryId (Target: $limit active)...");

    // List to hold the final active products
    List<Map<String, dynamic>> activeProductsFound = [];
    // List to hold products needing detail processing
    List<Map<String, dynamic>> productsToProcess = [];

    try {
      final ProductListCategory productListCategory = ProductListCategory();

      // --- Step 1: Fetch ALL Product IDs ---
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

      // --- Step 2: Loop Fetching Details in Batches until Limit is Reached ---
      int currentIdIndex = 0;
      const int batchSize = 10; // Fetch details in batches of 10

      while (activeProductsFound.length < limit && currentIdIndex < allProductIds.length) {
        // Determine the next batch of IDs
        int endIndex = currentIdIndex + batchSize;
        if (endIndex > allProductIds.length) {
          endIndex = allProductIds.length;
        }
        List<int> batchIds = allProductIds.sublist(currentIdIndex, endIndex);

        if (batchIds.isEmpty) {
          break; // Should not happen if currentIdIndex < allProductIds.length, but safety check
        }

        print("  -> Fetching details batch (${currentIdIndex + 1}-${endIndex}) for Category ID: $categoryId...");
        String idFilter = batchIds.join('|');
        final productDetailsApi =
            'https://www.alkirtas.com/api/products?display=full&filter[id]=[$idFilter]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

        final response = await http.get(Uri.parse(productDetailsApi));

        // Move index for the next iteration regardless of API success for this batch
        currentIdIndex = endIndex;

        if (response.statusCode != 200) {
          print("  ⚠️ Failed to load product details batch (Status: ${response.statusCode}). Skipping batch.");
          continue; // Skip to the next batch
        }

        final productData = json.decode(utf8.decode(response.bodyBytes));

        if (productData == null || !productData.containsKey('products') || productData['products'] == null) {
          print("  ⚠️ No product details returned in batch. Skipping batch.");
          continue; // Skip to the next batch
        }

        List<Map<String, dynamic>> rawProductsBatch = List<Map<String, dynamic>>.from(productData['products']);
        print("  ✅ Received details for ${rawProductsBatch.length} products in batch.");

        // Filter for active and add to list until limit is hit
        for (var product in rawProductsBatch) {
          if (product.containsKey('active') && product['active'].toString() == '1') {
            if (activeProductsFound.length < limit) {
              // Add to the final list and mark for processing
              activeProductsFound.add(product);
              productsToProcess.add(product); // Add here for processing later
              print("    + Found active product ${product['id']}. Total active: ${activeProductsFound.length}");
            } else {
              print("    - Limit ($limit) reached. Stopping search within batch.");
              break; // Stop checking this batch once limit is reached
            }
          }
        }
        // Check if limit is reached after processing the batch
        if (activeProductsFound.length >= limit) {
           print("  🏁 Target of $limit active products reached. Stopping fetch loop.");
           break; // Stop the outer while loop
        }
      } // End while loop

      // --- Step 3: Process Details for Found Active Products ---
      if (productsToProcess.isNotEmpty) {
         print("⚙️ Processing details for ${productsToProcess.length} active products found...");
         List<Future<void>> processingTasks = [];
         for (var product in productsToProcess) { // Process only those added
           processingTasks.add(_processProductDetails(product));
         }
         await Future.wait(processingTasks);
      } else {
         print("ℹ️ No active products found to process details for Category ID: $categoryId.");
      }

      // --- Step 4: Cache the final list ---
      _staticCachedProducts[categoryId] = activeProductsFound; // Store the list (might have < limit items if not enough active products exist)
      print("✅✅ Successfully fetched and processed ${activeProductsFound.length} active products for Category ID: $categoryId (Target was $limit).");
      completer.complete(); // Mark fetch as successful

    } catch (e) {
      print('❌❌ Error during product fetch/process loop for category $categoryId: $e');
      _staticError[categoryId] = 'Failed to load products: $e';
      _staticCachedProducts.remove(categoryId);
      completer.completeError(e);
    } finally {
      _staticIsLoading[categoryId] = false;
    }
  }

  // --- Helper Methods (Instance methods - Unchanged from previous version) ---
  Future<void> _processProductDetails(Map<String, dynamic> product) async {
    try {
      List<Future<void>> tasks = [];
      tasks.add(fetchDiscount(product['id']).then((discount) {
        if (discount != null && discount['reduction_type'] == 'percentage') {
          double reductionValue = (double.tryParse(discount['reduction'].toString()) ?? 0.0) * 100;
          product['discount'] = reductionValue;
        } else {
          product['discount'] = 0.0;
        }
      }));
      tasks.add(fetchTTCPrice(
              product['id'], product['price'], product['id_tax_rules_group'])
          .then((ttcPrice) {
        product['ttc_price'] = ttcPrice ?? double.tryParse(product['price'].toString()) ?? 0.0;
      }));
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
      await Future.wait(tasks);
    } catch (e) {
      print("❌ Error processing product ${product['id']} for category $categoryId: $e");
       product['discount'] ??= 0.0;
       product['ttc_price'] ??= double.tryParse(product['price'].toString()) ?? 0.0;
       product['image_urls'] ??= <String>[];
       product['default_image_url'] ??= constructImageUrl(product['id_default_image']);
    }
  }

  Future<Map<String, dynamic>?> fetchDiscount(dynamic productId) async {
     int prodId = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
     if (prodId == 0) return null;
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$prodId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final response = await http.get(Uri.parse(discountApi));
      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));
        if (!discountData.containsKey('specific_prices') || discountData['specific_prices'] == null) return null;
        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) return null;
        Map<String, dynamic>? selectedDiscount = Map<String, dynamic>.from(discounts.first);
        if (selectedDiscount['reduction_type'] == 'percentage') {
              return {
                'reduction': selectedDiscount['reduction'].toString(),
                'reduction_type': 'percentage',
             };
        } else if (selectedDiscount['reduction_type'] == 'amount') {
             return null;
        }
      }
    } catch (e) { print('❌ Error fetching discount for product $prodId: $e'); }
    return null;
  }

  Future<double?> fetchTTCPrice(dynamic productId, dynamic priceHT, dynamic taxRulesGroupId) async {
    double? basePrice = double.tryParse(priceHT.toString());
    if (basePrice == null) return null;
    int? rulesGroupId = taxRulesGroupId is int ? taxRulesGroupId : int.tryParse(taxRulesGroupId.toString());
    if (rulesGroupId == null || rulesGroupId == 0) return basePrice;
    try {
      final taxRulesApi = 'https://www.alkirtas.com/api/tax_rules?display=[id_tax]&filter[id_tax_rules_group]=[$rulesGroupId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) return basePrice;
      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
      if (taxRulesData['tax_rules'] == null || taxRulesData['tax_rules'].isEmpty) return basePrice;
      final int? taxId = int.tryParse(taxRulesData['tax_rules'][0]['id_tax'].toString());
      if (taxId == null) return basePrice;
      final taxesApi = 'https://www.alkirtas.com/api/taxes?display=[rate]&filter[id]=[$taxId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final taxesResponse = await http.get(Uri.parse(taxesApi));
      if (taxesResponse.statusCode != 200) return basePrice;
      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
       if (taxesData['taxes'] == null || taxesData['taxes'].isEmpty) return basePrice;
      final double? taxRate = double.tryParse(taxesData['taxes'][0]['rate'].toString());
      if (taxRate == null) return basePrice;
      return basePrice * (1 + (taxRate / 100));
    } catch (e) { print('❌ Error fetching TTC price for product $productId: $e'); return basePrice; }
  }

  String constructImageUrl(dynamic imageId) {
    if (imageId == null || imageId.toString().isEmpty) return 'https://via.placeholder.com/150?text=No+Image';
    final imageIdStr = imageId.toString();
    final path = imageIdStr.split('').join('/');
    return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
  }

   static String cleanDescription(String? description) {
    if (description == null || description.isEmpty) return "No description available";
    final document = htmlParser.parse(description);
    String cleanText = document.body?.text ?? "";
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanText;
  }
}
