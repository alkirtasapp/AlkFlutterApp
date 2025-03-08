import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:test/data/controllers/details_controller.dart';
import 'package:test/data/controllers/discount_controller.dart';
import 'package:test/data/controllers/product_list_Category.dart';
import 'package:test/data/controllers/tax_controller.dart';
import 'package:test/data/controllers/quantity_controller.dart';

class ProductControllerStore {
  final QuantityController quantityController = QuantityController();
  final DiscountController discountController = DiscountController();
  final TaxController taxController = TaxController();
  final ProductListCategory productListCategory = ProductListCategory();
  final DetailsController detailsController = DetailsController();

  Future<List<Map<String, dynamic>>?> fetchProductDataStore(
      int categoryId, int offset, int limit) async {
    try {
      var box = Hive.box('productCache');
      String cacheKey = "store_product_${categoryId}_$offset";

      // Check Cache First
      if (box.containsKey(cacheKey)) {
        print(
            "⚡ Using cached products for Category $categoryId, Offset $offset");
        return List<Map<String, dynamic>>.from(box.get(cacheKey));
      }

      // Get Product IDs from the category
      final List<int> productIds =
          await productListCategory.fetchProductIdsFromCategory(categoryId);
      if (productIds.isEmpty) {
        print("⚠️ No product IDs found for Category ID: $categoryId");
        return null;
      }

      // Ensure we start from the correct offset
      if (offset >= productIds.length) {
        print(
            "❌ Offset ($offset) is beyond available products (${productIds.length}) for Category ID: $categoryId");
        return [];
      }

      List<Map<String, dynamic>> fetchedProducts = [];
      int currentOffset = offset;
      Set<int> processedProductIds = {};

      const int batchSize = 10; // Adjust the batch size as needed

      while (fetchedProducts.length < limit && currentOffset < productIds.length) {
        List<int> batchProductIds = [];

        // Collect product IDs for the batch
        while (batchProductIds.length < batchSize && currentOffset < productIds.length) {
          int productId = productIds[currentOffset];
          currentOffset++;

          if (productId == null || productId <= 0 || processedProductIds.contains(productId)) {
            print("⚠️ Invalid or duplicate product ID at index $currentOffset");
            continue;
          }

          processedProductIds.add(productId);
          batchProductIds.add(productId);
        }

        if (batchProductIds.isEmpty) {
          break;
        }

        await _fetchAndProcessProducts(batchProductIds, fetchedProducts);
      }

      // Cache the results
      box.put(cacheKey, fetchedProducts);
      print("✅ Cached products for Category $categoryId, Offset $offset");
      return fetchedProducts;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return null;
    }
  }

  Future<void> _fetchAndProcessProducts(List<int> batchProductIds, List<Map<String, dynamic>> fetchedProducts) async {
    String productIdsParam = batchProductIds.join('|');
    final String productApi =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsParam]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("📡 Fetching products for IDs: $productIdsParam");

    final response = await http.get(Uri.parse(productApi));
    if (response.statusCode != 200) {
      print("❌ API Error: ${response.statusCode}");
      return;
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));
    if (productData['products'] == null || productData['products'].isEmpty) {
      print("⚠️ No products found for IDs: $productIdsParam");
      return;
    }

    List<Future<void>> processingTasks = [];

    for (var product in productData['products']) {
      if (product is Map<String, dynamic> &&
          product.containsKey('active') &&
          product['active'].toString() == '1') {
        processingTasks.add(_processProductDetails(product, fetchedProducts));
      }
    }

    await Future.wait(processingTasks);
  }


 Future<List<String>> fetchProductFeatures(String productId) async {
  try {
    final DetailsController detailsController = DetailsController();
    final String apiUrl =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=$productId&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("🟡 Fetching product features for ID: $productId");

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      print("❌ API Error: ${response.statusCode} for Product ID: $productId");
      return [];
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));

    if (productData == null ||
        !productData.containsKey('products') ||
        productData['products'].isEmpty) {
      print("❌ No product data found for ID: $productId");
      return [];
    }

    final product = productData['products'][0]; // Fix: Extract first product object

    if (!product.containsKey('associations') ||
        !product['associations'].containsKey('product_features')) {
      print("⚠️ No features found for Product ID: $productId");
      return [];
    }

    // ✅ Extract product feature IDs
    final List<Map<String, dynamic>> featuresList =
        List<Map<String, dynamic>>.from(product['associations']['product_features']);

    print("🔍 Found ${featuresList.length} features for Product ID: $productId");

    // 🔹 Use DetailsController to fetch feature names & values
    Map<String, String> featureMap =
        await detailsController.fetchProductFeatures(featuresList);

    if (featureMap.isEmpty) {
      print("⚠️ No mapped features for Product ID: $productId");
    } else {
      print("✅ Features Fetched: ${featureMap.entries.map((e) => "${e.key}: ${e.value}").toList()}");
    }

    return featureMap.entries.map((e) => "${e.key}: ${e.value}").toList();
  } catch (e) {
    print("❌ Exception fetching features for product $productId: $e");
    return [];
  }
}




  Future<void> _processProductDetails(Map<String, dynamic> product, List<Map<String, dynamic>> fetchedProducts) async {
    try {
      // Ensure product has stock
      product['id'] = int.tryParse(product['id'].toString()) ?? 0;
      product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
      product['quantity'] = int.tryParse(product['quantity'].toString()) ?? 0;

      final discount = await discountController.fetchDiscount(product['id']);

      if (discount != null &&
          discount is Map<String, dynamic> &&
          discount.containsKey('reduction_type')) {
        product['discount'] = discount['reduction_type'] == 'percentage'
            ? double.tryParse(discount['reduction'].toString()) ?? 0
            : 0;
      } else {
        product['discount'] = 0;
      }

      product['ttc_price'] = await taxController.fetchTTCPrice(
              product['id'],
              product['price'],
              product['id_tax_rules_group']) ??
          product['price'];

      if (product.containsKey('associations') &&
          product['associations'].containsKey('images')) {
        final images = product['associations']['images'] as List;
        product['image_urls'] =
            images.map((image) => constructImageUrl(image['id'])).toList();
      } else {
        product['image_urls'] = [];
      }

      //product['quantity'] =
      //    await quantityController.fetchQuantity(product['id']) ?? 0;

  

      fetchedProducts.add(product);

     
    } catch (e) {
      print("❌ Error processing product details for ${product['id']}: $e");
    }
  }

  Future<List<Map<String, dynamic>>?> fetchProductsByIds(List<int> productIds) async {
    try {
      if (productIds.isEmpty) {
        print("⚠️ No product IDs provided");
        return null;
      }

      List<Map<String, dynamic>> fetchedProducts = [];
      Set<int> processedProductIds = {};

      const int batchSize = 100; // Adjust the batch size as needed

      for (int i = 0; i < productIds.length; i += batchSize) {
        List<int> batchProductIds = productIds.skip(i).take(batchSize).toList();

        if (batchProductIds.isEmpty) {
          break;
        }

        await _fetchAndProcessProducts(batchProductIds, fetchedProducts);
      }

      return fetchedProducts;
    } catch (e) {
      print('❌ Error fetching products by IDs: $e');
      return null;
    }
  }

  String constructImageUrl(dynamic imageId) {
    if (imageId == null) return 'placeholder_image_url';
    final imageIdStr = imageId.toString();
    final path = imageIdStr.split('').join('/');
    return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
  }
}
