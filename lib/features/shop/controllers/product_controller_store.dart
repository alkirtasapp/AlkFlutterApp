import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ProductControllerStore {
  
  Future<Map<String, dynamic>?> fetchProductDataStore(
    int productIndex, int categoryId) async {
  try {
    // ✅ Open Hive box for caching
    var box = Hive.box('productCache');
    String cacheKey = "store_product_${categoryId}_$productIndex";

    // ✅ Step 1: Check if the product is already in cache
    if (box.containsKey(cacheKey)) {
      print("⚡ Using cached store product data for Category $categoryId, Index $productIndex");
      return Map<String, dynamic>.from(box.get(cacheKey));
    }

    final List<int> categoryIds = [categoryId];
    const int productsPerCategory = 10;
    final List<Map<String, dynamic>> fetchedProducts = [];

    for (int categoryId in categoryIds) {
      final categoryApi =
          'https://www.alkirtas.com/api/products?sort=[id_DESC]&display=full&filter[active]=1&filter[id_category_default]=[$categoryId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      print("📡 Fetching products for Category ID: $categoryId");
      
      final response = await http.get(Uri.parse(categoryApi));

      if (response.statusCode == 200) {
        final categoryData = json.decode(utf8.decode(response.bodyBytes));

        // ✅ Log full API response
        print("📡 API Response for Category $categoryId: ${categoryData.toString()}");

        final List<dynamic> categoryProducts = categoryData['products'] ?? [];

        // ✅ Ensure categoryProducts is not empty before proceeding
        if (categoryProducts.isEmpty) {
          print("⚠️ No products found for Category ID: $categoryId");
          continue;
        }

        final selectedProducts =
            categoryProducts.take(productsPerCategory).toList();
        fetchedProducts.addAll(selectedProducts.map((product) => product as Map<String, dynamic>));

        if (fetchedProducts.length >= 10) break;
      } else {
        print("❌ API Error: ${response.statusCode} for Category ID: $categoryId");
      }
    }

    // ✅ Ensure fetchedProducts is not empty before accessing an index
    if (fetchedProducts.isEmpty) {
      print("⚠️ No products available for Category ID: $categoryId");
      return null;
    }

    if (productIndex >= fetchedProducts.length) {
      print("⚠️ Product Index $productIndex is out of range (Max: ${fetchedProducts.length - 1})");
      return null;
    }

    final product = fetchedProducts[productIndex];

    // ✅ Ensure all values are correctly formatted
    product['id'] = int.tryParse(product['id'].toString()) ?? 0;
    product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
    product['quantity'] = int.tryParse(product['quantity'].toString()) ?? 0;

    print("🛒 Selected Product: ${product['name']} (ID: ${product['id']})");

    // Fetch discount data for the product
    final discount = await fetchDiscount(product['id']);
    if (discount != null && discount['reduction_type'] == 'percentage') {
      final reduction = discount['reduction'];
      product['discount'] = (reduction is String)
          ? double.tryParse(reduction) ?? 0
          : (reduction ?? 0);
    } else {
      product['discount'] = 0;
    }

    print('💲 Discount for product ${product['id']}: ${product['discount']}%');

    // Fetch and apply tax calculation
    final ttcPrice = await fetchTTCPrice(
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

    print("🖼️ Images for product ${product['id']}: ${product['image_urls']}");

    // Fetch Stock Quantity
    int? stockQuantity = await fetchQuantity(product['id']);
    product['quantity'] = stockQuantity ?? 0;

    print("📦 Stock for product ${product['id']}: ${product['quantity']} units");

    // ✅ Step 3: Save product to cache
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
        'https://www.alkirtas.com/api/stock_availables?display=full&limit=10&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    final response = await http.get(Uri.parse(stockApi));

    print('🔍 Fetching stock for Product ID: $productId'); // ✅ Log Request
    print('📥 API Raw Response: ${response.body}'); // ✅ Log Full API Response

    if (response.statusCode == 200) {
      final stockData = json.decode(utf8.decode(response.bodyBytes));

      // Check if 'stock_availables' exists and is a list
      if (stockData.containsKey('stock_availables') &&
          stockData['stock_availables'] is List &&
          stockData['stock_availables'].isNotEmpty) {
        
        // Find the correct product entry based on 'id_product'
        final stockEntries = stockData['stock_availables'] as List;
        for (var stock in stockEntries) {
          if (stock['id_product'].toString() == productId.toString()) {
            int quantity = int.tryParse(stock['quantity'].toString()) ?? 0;
            
            print('✅ Stock for Product ID $productId: $quantity units'); // ✅ Log Correct Quantity
            return quantity;
          }
        }

        print('⚠️ Product ID $productId not found in stock_availables list');
      } else {
        print('⚠️ No stock data available for Product ID: $productId');
      }
    } else {
      print('❌ API Request Failed. Status Code: ${response.statusCode}');
    }
  } catch (e) {
    print('🔥 Error fetching stock quantity for Product ID $productId: $e');
  }

  print('❌ Returning NULL for Product ID: $productId'); // ✅ Log Null Return
  return null;
}


  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(discountApi));

      print(
          'Response for product $productId: ${response.body}'); // Debugging output

      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));

        if (!discountData.containsKey('specific_prices')) {
          print('No specific_prices key in response for product $productId');
          return null;
        }

        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) {
          print('No discounts found for product $productId');
          return null;
        }

        DateTime now = DateTime.now();
        Map<String, dynamic>? permanentDiscount;
        Map<String, dynamic>? latestDiscount;

        for (var discount in discounts) {
          if (!discount.containsKey('reduction') ||
              !discount.containsKey('reduction_type')) {
            print(
                'Skipping discount for product $productId: Incomplete data ${discount}');
            continue;
          }

          String fromDateStr = discount['from'] ?? "";
          String toDateStr = discount['to'] ?? "";

          DateTime? fromDate = DateTime.tryParse(fromDateStr);
          DateTime? toDate = DateTime.tryParse(toDateStr);

          // Check for permanent discount (always valid)
          if (fromDateStr == "0000-00-00 00:00:00" &&
              toDateStr == "0000-00-00 00:00:00") {
            print('Permanent discount found for product $productId');
            permanentDiscount = discount;
            continue; // Still check for other discounts
          }

          // Ensure the discount is within the valid period
          if (fromDate != null &&
              toDate != null &&
              (now.isBefore(fromDate) || now.isAfter(toDate))) {
            print(
                'Skipping expired discount for product $productId: From $fromDate to $toDate');
            continue;
          }

          // Select the latest valid discount (based on 'to' date)
          if (latestDiscount == null ||
              (toDate != null &&
                  toDate.isAfter(DateTime.tryParse(latestDiscount['to']) ??
                      DateTime(1900)))) {
            latestDiscount = discount;
          }
        }

        // Apply permanent discount if available; otherwise, use the latest valid discount
        Map<String, dynamic>? selectedDiscount =
            permanentDiscount ?? latestDiscount;

        if (selectedDiscount != null) {
          double parsedReduction =
              double.tryParse(selectedDiscount['reduction']) ?? 0;
          parsedReduction = parsedReduction * 100; // Convert to percentage

          print(
              'Final selected discount for product $productId: $parsedReduction%');

          return {
            'reduction': parsedReduction.toString(), // Ensure string format
            'reduction_type': 'percentage',
          };
        }

        print('No valid discount available for product $productId');
      } else {
        print(
            'Failed to fetch discount for product $productId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching discount for product $productId: $e');
    }
    return null;
  }

  Future<double?> fetchTTCPrice(
      int productId, dynamic priceHT, dynamic taxRulesGroupId) async {
    try {
      // If id_tax_rules_group is 0, return the original price (HT)
      if (taxRulesGroupId == 0) {
        return double.tryParse(priceHT.toString());
      }

      // Step 2: Fetch id_tax from tax rules API
      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax,id_tax_rules_group]&filter[id_tax_rules_group]=[$taxRulesGroupId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) {
        return double.tryParse(
            priceHT.toString()); // Return HT price if API fails
      }

      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));

      // Check if tax rule exists
      if (taxRulesData['tax_rules'] == null ||
          taxRulesData['tax_rules'].isEmpty) {
        return double.tryParse(
            priceHT.toString()); // No tax rule found, return HT price
      }

      final int taxId = taxRulesData['tax_rules'][0]['id_tax'];

      // Step 3: Fetch tax rate from taxes API
      final taxesApi =
          'https://www.alkirtas.com/api/taxes?display=[rate,id]&filter[id]=[$taxId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxesResponse = await http.get(Uri.parse(taxesApi));
      if (taxesResponse.statusCode != 200) {
        return double.tryParse(
            priceHT.toString()); // Return HT price if API fails
      }

      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
      final double taxRate = double.parse(taxesData['taxes'][0]['rate']);

      // Step 4: Calculate TTC price
      double priceHTDouble = double.parse(priceHT.toString());
      double priceTTC = priceHTDouble * (1 + (taxRate / 100));

      return priceTTC;
    } catch (e) {
      print('Error fetching TTC price: $e');
      return double.tryParse(priceHT.toString()); // If error, return HT price
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
