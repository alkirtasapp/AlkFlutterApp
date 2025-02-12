import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:test/data/controllers/discount_controller.dart';
import 'package:test/data/controllers/product_list_Category.dart';
import 'package:test/data/controllers/tax_controller.dart';

import '../../../data/controllers/quantity_controller.dart';

class ProductControllerStore {
  final QuantityController quantityController = QuantityController();
  final DiscountController discountController = DiscountController();
  final TaxController taxController = TaxController();
  final ProductListCategory productListCategory = ProductListCategory();

  Future<Map<String, dynamic>?> fetchProductDataStore(
      int productIndex, int categoryId) async {
    try {
      //  Open Hive box for caching
      var box = Hive.box('productCache');
      String cacheKey = "store_product_${categoryId}_$productIndex";

      //  Step 1: Check if the product is already in cache
      if (box.containsKey(cacheKey)) {
        print(
            "⚡ Using cached store product data for Category $categoryId, Index $productIndex");
        return Map<String, dynamic>.from(box.get(cacheKey));
      }

      //  Fetch product IDs from the category API first
      final List<int> productIds =
          await productListCategory.fetchProductIdsFromCategory(categoryId);

      if (productIds.isEmpty) {
        print("⚠️ No product IDs found for Category ID: $categoryId");
        return null;
      }

      const int productsPerCategory = 50; // Keep max products logic intact
      final List<Map<String, dynamic>> fetchedProducts = [];

      for (int productId in productIds.take(productsPerCategory)) {
        final productApi =
            'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
        print("📡 Fetching products for Product ID: \$productId");

        final response = await http.get(Uri.parse(productApi));

        if (response.statusCode == 200) {
          final productData = json.decode(utf8.decode(response.bodyBytes));

          if (productData['products'] == null ||
              productData['products'].isEmpty) {
            print("⚠️ No product found for Product ID: \$productId");
            continue;
          }

          final List<dynamic> productList = productData['products'];

          //  Filter out inactive products and add only active products
          final List<Map<String, dynamic>> activeProducts = productList
              .where((product) =>
                  product.containsKey('active') &&
                  product['active'].toString() == '1')
              .map((product) => product as Map<String, dynamic>)
              .toList();

          fetchedProducts.addAll(activeProducts);
        } else {
          print(
              "❌ API Error: ${response.statusCode} for Product ID: \$productId");
        }
      }

      if (fetchedProducts.isEmpty) {
        print("⚠️ No products available for Category ID: $categoryId");
        return null;
      }

      if (productIndex >= fetchedProducts.length) {
        print(
            "⚠️ Product Index $productIndex is out of range (Max: ${fetchedProducts.length - 1})");
        return null;
      }

      final product = fetchedProducts[productIndex];

      //  all values are correctly formatted
      product['id'] = int.tryParse(product['id'].toString()) ?? 0;
      product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
      product['quantity'] = int.tryParse(product['quantity'].toString()) ?? 0;

      print("🛒 Selected Product: ${product['name']} (ID: ${product['id']})");

      // Fetch discount data for the product
      final discount = await discountController.fetchDiscount(product['id']);
      if (discount != null && discount['reduction_type'] == 'percentage') {
        final reduction = discount['reduction'];
        product['discount'] = (reduction is String)
            ? double.tryParse(reduction) ?? 0
            : (reduction ?? 0);
      } else {
        product['discount'] = 0;
      }

      print(
          '💲 Discount for product ${product['id']}: ${product['discount']}%');

      //  apply tax calculation
      final ttcPrice = await taxController.fetchTTCPrice(
          product['id'], product['price'], product['id_tax_rules_group']);
      if (ttcPrice != null) {
        product['ttc_price'] = ttcPrice; // Attach calculated TTC price
      }

      // Fetch images from associations
      if (product.containsKey('associations') &&
          product['associations'].containsKey('images')) {
        final images = product['associations']['images'] as List;
        List<String> imageUrls = images.map((image) {
          return constructImageUrl(image['id']);
        }).toList();
        product['image_urls'] = imageUrls;
      } else {
        product['image_urls'] = [];
      }

      print(
          "🖼️ Images for product ${product['id']}: ${product['image_urls']}");

      // Fetch Stock Quantity
      int? stockQuantity =
          await quantityController.fetchQuantity(product['id']);
      product['quantity'] = stockQuantity ?? 0;

      print(
          "📦 Stock for product ${product['id']}: ${product['quantity']} units");

      //  Step 3: Save product to cache
      box.put(cacheKey, product);
      print(
          "💾 Cached store product data for Category $categoryId, Index $productIndex");

      return product;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return null;
    }
  }

  String constructImageUrl(dynamic imageId) {
    if (imageId == null) {
      return 'placeholder_image_url';
    }
    final imageIdStr = imageId.toString();
    final digits = imageIdStr.split('');
    final path = digits.join('/');
    return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
  }
}

