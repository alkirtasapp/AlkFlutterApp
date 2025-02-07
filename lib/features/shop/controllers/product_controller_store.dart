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

    // ✅ Fetch product IDs from the category API
    final List<int> productIds = await fetchProductIdsFromCategory(categoryId);

    if (productIds.isEmpty) {
      print("⚠️ No product IDs found for Category ID: $categoryId");
      return null;
    }

    const int productsPerCategory = 12; // Keep max products logic intact
    final List<int> selectedProductIds = productIds.take(productsPerCategory).toList();

    // ✅ Fetch all selected products in one batch request
    final Map<int, Map<String, dynamic>>? allProducts = await fetchMultipleProducts(selectedProductIds);

    if (allProducts == null || allProducts.isEmpty) {
      print("⚠️ No products available for Category ID: $categoryId");
      return null;
    }

    if (productIndex >= allProducts.length) {
      print("⚠️ Product Index $productIndex is out of range (Max: ${allProducts.length - 1})");
      return null;
    }

    final productId = selectedProductIds[productIndex];

    if (!allProducts.containsKey(productId)) {
      print("⚠️ Product ID $productId not found in fetched data");
      return null;
    }

    final product = allProducts[productId]!;

    // ✅ Save product to cache
    box.put(cacheKey, product);
    print("💾 Cached store product data for Category $categoryId, Index $productIndex");

    return product;
  } catch (e) {
    print('❌ Error fetching products: $e');
    return null;
  }
}

// ✅ Fetch multiple products in one API call
Future<Map<int, Map<String, dynamic>>?> fetchMultipleProducts(List<int> productIds) async {
  try {
    if (productIds.isEmpty) return null;

    final productApi =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=[${productIds.join(",")}]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("📡 Fetching multiple products: ${productIds.join(",")}");

    final response = await http.get(Uri.parse(productApi));

    if (response.statusCode == 200) {
      final productData = json.decode(utf8.decode(response.bodyBytes));

      if (productData['products'] == null || productData['products'].isEmpty) {
        return {};
      }

      // ✅ Ensure data is always returned as a map
      return {
        for (var product in (productData['products'] is List ? productData['products'] : [productData['products']]))
          int.parse(product['id'].toString()): product
      };
    } else {
      print("❌ API Error: ${response.statusCode}");
      return {};
    }
  } catch (e) {
    print("🔥 Error fetching multiple products: $e");
    return {};
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

              print(
                  '✅ Stock for Product ID $productId: $quantity units'); // ✅ Log Correct Quantity
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

Future<List<int>> fetchProductIdsFromCategory(int categoryId) async {
  try {
    final categoryApi =
        'https://www.alkirtas.com/api/categories?display=full&filter[id]=[$categoryId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("📡 Fetching product IDs for Category ID: $categoryId");

    final response = await http.get(Uri.parse(categoryApi));

    if (response.statusCode == 200) {
      final categoryData = json.decode(utf8.decode(response.bodyBytes));

      if (categoryData['categories'] == null ||
          categoryData['categories'].isEmpty) {
        print("⚠️ No categories found for ID: $categoryId");
        return [];
      }

      final category = categoryData['categories'][0];

      if (category.containsKey('associations') &&
          category['associations'].containsKey('products')) {
        List<dynamic> productList = category['associations']['products'];

        List<int> productIds = productList
            .map((product) => int.parse(product['id'].toString()))
            .toList();
        productIds.sort((a, b) => b.compareTo(a)); // ✅ Sort by ID DESC

        print("📦 Found ${productIds.length} products in category $categoryId");

        return productIds;
      } else {
        print("⚠️ No products associated with Category ID: $categoryId");
      }
    } else {
      print(
          "❌ API Error: ${response.statusCode} while fetching Category $categoryId");
    }
  } catch (e) {
    print("🔥 Error fetching product IDs: $e");
  }
  return [];
}
