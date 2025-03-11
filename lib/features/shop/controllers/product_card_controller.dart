import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:test/data/controllers/details_controller.dart';

class ProductCardControllerTax {
  final DetailsController detailsController = DetailsController();

  static List<int>? cachedProductIds; // ✅ Prevents re-fetching
  static Future<void>? _fetchingProductsFuture; // ✅ Ensures fetch runs ONCE

  Future<Map<String, dynamic>?> fetchProductData(int productIndex) async {
    try {
      var box = Hive.box('productCache');
      String cacheKey = "product_$productIndex";

      // ✅ Step 1: Check if product is cached
      if (box.containsKey(cacheKey)) {
        print("⚡ Using cached product data for ID $productIndex");
        return Map<String, dynamic>.from(box.get(cacheKey));
      }

      // ✅ Step 2: Fetch product IDs if not already fetched
      if (cachedProductIds == null) {
        if (_fetchingProductsFuture != null) {
          print("🔄 Waiting for existing fetch...");
          await _fetchingProductsFuture; // ✅ Wait for ongoing fetch instead of starting new one
        } else {
          _fetchingProductsFuture = _fetchProductIds();
          await _fetchingProductsFuture;
          _fetchingProductsFuture = null; // ✅ Reset after fetch completes
        }
      }

      print("🔍 Final Product IDs: $cachedProductIds"); // ✅ Logs only ONCE per session

      // ✅ Step 3: Fetch all product details in one API request
      String productIdsQuery = cachedProductIds!.join('|');
      final productApi =
          'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsQuery]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(productApi));
      if (response.statusCode != 200) {
        print("❌ Failed to fetch product details.");
        return null;
      }

      final productData = json.decode(utf8.decode(response.bodyBytes));
      if (!productData.containsKey('products')) {
        print("❌ No product data found.");
        return null;
      }

      List<Map<String, dynamic>> rawProducts = List<Map<String, dynamic>>.from(productData['products']);
      List<Map<String, dynamic>> processedProducts = [];

      // ✅ Step 4: Process all product details concurrently
      List<Future<void>> asyncTasks = [];
      for (var product in rawProducts) {
        asyncTasks.add(_processProductDetails(product));
        processedProducts.add(product);
      }

      await Future.wait(asyncTasks);
      print("✅ Processed All Product Data");

      // ✅ Step 5: Cache all products at once
      for (var i = 0; i < processedProducts.length; i++) {
        box.put("product_$i", processedProducts[i]);
      }
      print("💾 Cached all product data.");

      return processedProducts.isNotEmpty ? processedProducts[productIndex % processedProducts.length] : null;
    } catch (e) {
      print('❌ Error fetching all products: $e');
      return null;
    }
  }

  /// ✅ Fetches product IDs only ONCE and caches them
  Future<void> _fetchProductIds() async {
    final List<int> categoryIds = [10, 17, 11, 486, 12, 590, 544];
    const int productsPerCategory = 2;
    final List<int> productIds = [];

    for (int categoryId in categoryIds) {
      final categoryApi =
          'https://www.alkirtas.com/api/products?display=full&filter[active]=1'
          '&sort=[id_DESC]&filter[id_category_default]=[$categoryId]&limit=$productsPerCategory'
          '&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(categoryApi));
      if (response.statusCode == 200) {
        final categoryData = json.decode(utf8.decode(response.bodyBytes));
        final categoryProducts = categoryData['products'] as List<dynamic>;

        List<int> selectedIds = categoryProducts
            .map((product) => product['id'] is String 
                ? int.parse(product['id']) 
                : product['id'] as int) // ✅ Safe conversion
            .toList();

        productIds.addAll(selectedIds);
      }
    }

    if (productIds.isEmpty) {
      print("❌ No product IDs fetched.");
      return;
    }

    cachedProductIds = productIds; // ✅ Store fetched IDs
    print("✅ Cached Product IDs: $cachedProductIds"); // ✅ Logs only once!
  }

  Future<void> _processProductDetails(Map<String, dynamic> product) async {
    try {
      List<Future<void>> tasks = [];

      // ✅ Fetch discount
      tasks.add(fetchDiscount(product['id']).then((discount) {
        if (discount != null && discount['reduction_type'] == 'percentage') {
          product['discount'] = double.tryParse(discount['reduction']) ?? 0;
        } else {
          product['discount'] = 0;
        }
      }));

      // ✅ Fetch tax-inclusive price (TTC)
      tasks.add(fetchTTCPrice(product['id'], product['price'], product['id_tax_rules_group']).then((ttcPrice) {
        product['ttc_price'] = ttcPrice ?? product['price'];
      }));

      // ✅ Fetch images
      tasks.add(Future(() {
        if (product.containsKey('associations') && product['associations'].containsKey('images')) {
          final images = product['associations']['images'] as List;
          List<String> imageUrls = images.map((image) => constructImageUrl(image['id'])).toList();
          product['image_urls'] = imageUrls;
        } else {
          product['image_urls'] = [];
        }
      }));

      await Future.wait(tasks);
    } catch (e) {
      print("❌ Error processing product ${product['id']}: $e");
    }
  }
 
  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(discountApi));
      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));
        if (!discountData.containsKey('specific_prices')) return null;

        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) return null;

        Map<String, dynamic>? selectedDiscount = discounts.first;
        double parsedReduction = double.tryParse(selectedDiscount?['reduction']) ?? 0;
        parsedReduction = parsedReduction * 100;

        return {
          'reduction': parsedReduction.toString(),
          'reduction_type': 'percentage',
        };
      }
    } catch (e) {
      print('❌ Error fetching discount for product $productId');
    }
    return null;
  }
  Future<double?> fetchTTCPrice(int productId, dynamic priceHT, dynamic taxRulesGroupId) async {
    try {
      if (taxRulesGroupId == 0) {
        return double.tryParse(priceHT.toString());
      }

      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax,id_tax_rules_group]&filter[id_tax_rules_group]=[$taxRulesGroupId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) {
        return double.tryParse(priceHT.toString());
      }

      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
      if (taxRulesData['tax_rules'] == null || taxRulesData['tax_rules'].isEmpty) {
        return double.tryParse(priceHT.toString());
      }

      final int taxId = taxRulesData['tax_rules'][0]['id_tax'];

      final taxesApi =
          'https://www.alkirtas.com/api/taxes?display=[rate,id]&filter[id]=[$taxId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxesResponse = await http.get(Uri.parse(taxesApi));
      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
      final double taxRate = double.parse(taxesData['taxes'][0]['rate']);

      return (double.parse(priceHT.toString())) * (1 + (taxRate / 100));
    } catch (e) {
      print('❌ Error fetching TTC price');
      return double.tryParse(priceHT.toString());
    }
  }
  static String cleanDescription(String? description) {
    if (description == null || description.isEmpty) {
      return "No description available";
    }

    // Parse the HTML and extract the text content
    final document = htmlParser.parse(description);
    String cleanText = document.body?.text ?? "";

    // Remove extra spaces and newlines
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanText;
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
