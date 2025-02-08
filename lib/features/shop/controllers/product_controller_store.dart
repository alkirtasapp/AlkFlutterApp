import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ProductControllerStore {
  Future<Map<String, dynamic>?> fetchProductDataStore(int productIndex, int categoryId) async {
    try {
      var box = Hive.box('productCache');
      String cacheKey = "store_product_${categoryId}_$productIndex";

      if (box.containsKey(cacheKey)) {
        print("⚡ Using cached store product data for Category $categoryId, Index $productIndex");
        return Map<String, dynamic>.from(box.get(cacheKey));
      }

      final List<int> categoryIds = [categoryId];
      //const int productsPerCategory = 10;

      // ✅ Fetch all categories in parallel using Future.wait()
      List<Future<http.Response>> requests = categoryIds.map((id) {
        final categoryApi =
            'https://www.alkirtas.com/api/products?sort=[id_DESC]&display=full&filter[active]=1&filter[id_category_default]=[$id]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
        return http.get(Uri.parse(categoryApi));
      }).toList();

      final responses = await Future.wait(requests);
      List<Map<String, dynamic>> fetchedProducts = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final categoryData = json.decode(utf8.decode(response.bodyBytes));

          // ✅ Check if 'products' key exists and is a List
          final categoryProducts = categoryData['products'];
          if (categoryProducts == null || categoryProducts is! List) {
            print("⚠️ API returned unexpected data structure: ${categoryData.toString()}");
            return null;
          }

          if (categoryProducts.isNotEmpty) {
            fetchedProducts.addAll(categoryProducts.map((product) => product as Map<String, dynamic>));
          }
        }
      }

      if (fetchedProducts.isEmpty || productIndex >= fetchedProducts.length) {
        print("⚠️ No products available for Category ID: $categoryId");
        return null;
      }

      final product = fetchedProducts[productIndex];

      // ✅ Ensure proper type conversions
      product['id'] = product['id'] is int ? product['id'] : int.tryParse(product['id'].toString()) ?? 0;
      product['price'] = product['price'] is double ? product['price'] : double.tryParse(product['price'].toString()) ?? 0.0;
      product['quantity'] = product['quantity'] is int ? product['quantity'] : int.tryParse(product['quantity'].toString()) ?? 0;

      print("🛒 Selected Product: ${product['name']} (ID: ${product['id']})");

      // ✅ Fetch discount data
      final discount = await fetchDiscount(product['id']);
      product['discount'] = discount != null && discount['reduction_type'] == 'percentage'
          ? (double.tryParse(discount['reduction'].toString()) ?? 0)
          : 0;

      // ✅ Fetch and apply tax calculation
      final ttcPrice = await fetchTTCPrice(product['id'], product['price'], product['id_tax_rules_group']);
      if (ttcPrice != null) {
        product['ttc_price'] = ttcPrice;
      }

      // ✅ Fetch images
      if (product.containsKey('associations') && product['associations'].containsKey('images')) {
        final images = product['associations']['images'] as List;
        product['image_urls'] = images.map((image) => constructImageUrl(image['id'])).toList();
      } else {
        product['image_urls'] = [];
      }

      // ✅ Fetch Stock Quantity
      int? stockQuantity = await fetchQuantity(product['id']);
      product['quantity'] = stockQuantity ?? 0;

      print("📦 Stock for product ${product['id']}: ${product['quantity']} units");

      // ✅ Cache product data
      box.put(cacheKey, product);
      print("💾 Cached store product data for Category $categoryId, Index $productIndex");

      return product;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return null;
    }
  }

  Future<int?> fetchQuantity(int productId) async {
    try {
      final stockApi =
          'https://www.alkirtas.com/api/stock_availables?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final response = await http.get(Uri.parse(stockApi));

      if (response.statusCode == 200) {
        final stockData = json.decode(utf8.decode(response.bodyBytes));

        if (stockData.containsKey('stock_availables') && stockData['stock_availables'] is List) {
          for (var stock in stockData['stock_availables']) {
            if (stock['id_product'].toString() == productId.toString()) {
              return int.tryParse(stock['quantity'].toString()) ?? 0;
            }
          }
        }
      }
    } catch (e) {
      print('🔥 Error fetching stock quantity for Product ID $productId: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final response = await http.get(Uri.parse(discountApi));

      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));

        if (discountData.containsKey('specific_prices') && discountData['specific_prices'] is List) {
          for (var discount in discountData['specific_prices']) {
            if (discount.containsKey('reduction') && discount.containsKey('reduction_type')) {
              return {
                'reduction': (double.tryParse(discount['reduction'].toString()) ?? 0) * 100,
                'reduction_type': discount['reduction_type']
              };
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching discount for product $productId: $e');
    }
    return null;
  }

  Future<double?> fetchTTCPrice(int productId, dynamic priceHT, dynamic taxRulesGroupId) async {
    try {
      if (taxRulesGroupId == 0) {
        return double.tryParse(priceHT.toString());
      }

      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax]&filter[id_tax_rules_group]=[$taxRulesGroupId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));

      if (taxRulesResponse.statusCode == 200) {
        final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
        if (taxRulesData.containsKey('tax_rules') && taxRulesData['tax_rules'] is List) {
          final int taxId = taxRulesData['tax_rules'][0]['id_tax'];
          final taxesApi = 'https://www.alkirtas.com/api/taxes?display=[rate]&filter[id]=[$taxId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
          final taxesResponse = await http.get(Uri.parse(taxesApi));

          if (taxesResponse.statusCode == 200) {
            final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
            final double taxRate = double.parse(taxesData['taxes'][0]['rate']);
            return (double.parse(priceHT.toString()) * (1 + (taxRate / 100)));
          }
        }
      }
    } catch (e) {
      print('Error fetching TTC price: $e');
    }
    return double.tryParse(priceHT.toString());
  }

  String constructImageUrl(dynamic imageId) {
    return 'https://www.alkirtas.com/img/p/${imageId.toString().split('').join('/')}/$imageId.jpg';
  }
}
