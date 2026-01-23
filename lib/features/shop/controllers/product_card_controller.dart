import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/details_controller.dart';
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class ProductCardControllerTax {
  final DetailsController detailsController = DetailsController();
  final ProductListCategory productListCategory = ProductListCategory();

  //  Prevents re-fetching productIds
  static List<int>? cachedProductIds;
  //  Ensures fetch runs ONCE productIds
  static Future<void>? _fetchingProductsFuture;

  //Prevents re-fetching products details
  static List<Map<String, dynamic>>? cachedProducts;
  static Future<void>? _fetchingProductsDetailsFuture;

  // Define categories and products per category
  final List<int> categoryIds = [2];
  final int productsPerCategory = 10;

  Future<Map<String, dynamic>?> fetchProductData(int productIndex) async {
    try {
      // Step 1: Fetch product IDs if not already fetched
      if (cachedProductIds == null) {
        if (_fetchingProductsFuture != null) {
          await _fetchingProductsFuture;
        } else {
          _fetchingProductsFuture = _fetchProductIds();
          await _fetchingProductsFuture;
          _fetchingProductsFuture = null;
        }
      }

      // Step 2: Wait for any ongoing product details fetch
      if (_fetchingProductsDetailsFuture != null) {
        await _fetchingProductsDetailsFuture;
      }

      // Step 3: Fetch all product details in one API request
      if (cachedProducts == null && cachedProductIds != null) {
        _fetchingProductsDetailsFuture =
            _fetchAndProcessAllProductDetails(cachedProductIds!);
        await _fetchingProductsDetailsFuture;
        _fetchingProductsDetailsFuture = null;

        // Reverse the cachedProducts list to display the latest products first
        cachedProducts = cachedProducts?.reversed.toList();
      }

      // Use random index with productIndex
      if (cachedProducts != null && cachedProducts!.isNotEmpty) {
        final randomIndex = productIndex % cachedProducts!.length;
        return cachedProducts![randomIndex];
      }
      return null;
    } catch (e) {
      AlkLoggerHelper.error("Products fetch failed", e);
      return null;
    }
  }

  Future<void> _fetchAndProcessAllProductDetails(List<int> productIds) async {
    String productIdsQuery = productIds.join('|');
    final productApi =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsQuery]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

    final response = await http.get(Uri.parse(productApi));
    if (response.statusCode != 200) {
      AlkLoggerHelper.error("Product details fetch failed: ${response.statusCode}");
      return;
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));
    if (!productData.containsKey('products')) {
      return;
    }

    List<Map<String, dynamic>> rawProducts =
        List<Map<String, dynamic>>.from(productData['products']);
    List<Map<String, dynamic>> processedProducts = [];

    //  Step 4: Process all product details concurrently
    List<Future<void>> asyncTasks = [];

    for (var product in rawProducts) {
      if (product.containsKey('active')&&
      product['active'].toString()=='1'){
      asyncTasks.add(_processProductDetails(product));
      processedProducts.add(product);
    }
    }

    await Future.wait(asyncTasks);
    cachedProducts = processedProducts;
  }

  ///  Fetches product IDs only ONCE and caches them
  Future<void> _fetchProductIds() async {
    final List<int> productIds = [];
    int attempts = 0; // To prevent infinite loops
    const int maxAttempts = 5; // Limit the number of attempts to fetch more IDs
    const int batchSize = 100; // Fetch product IDs in batches of 100

    // Fetch products from each category
    for (int categoryId in categoryIds) {
      while (productIds.length < productsPerCategory && attempts < maxAttempts) {
        attempts++;
        List<int> categoryProductIds =
            await productListCategory.fetchProductIdsFromCategory(categoryId);

        // Fetch details for these product IDs in batches
        for (int i = 0; i < categoryProductIds.length; i += batchSize) {
          final batch = categoryProductIds.sublist(
            i,
            (i + batchSize > categoryProductIds.length)
                ? categoryProductIds.length
                : i + batchSize,
          );

          String productIdsQuery = batch.join('|');
          final productApi =
              'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsQuery]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

          final response = await http.get(Uri.parse(productApi));
          if (response.statusCode != 200) {
            continue;
          }

          final productData = json.decode(utf8.decode(response.bodyBytes));
          if (!productData.containsKey('products')) {
            continue;
          }

          List<Map<String, dynamic>> rawProducts =
              List<Map<String, dynamic>>.from(productData['products']);

          // Filter active products
          List<int> activeProductIds = rawProducts
              .where((product) =>
                  product.containsKey('active') &&
                  product['active'].toString() == '1')
              .map((product) => int.parse(product['id'].toString()))
              .toList();

          productIds.addAll(activeProductIds);

          // Break if we have enough product IDs
          if (productIds.length >= productsPerCategory) {
            break;
          }
        }

        // Break if we have enough product IDs
        if (productIds.length >= productsPerCategory) {
          break;
        }
      }
    }

    if (productIds.isEmpty) {
      AlkLoggerHelper.warning("No active product IDs found");
      return;
    }

    cachedProductIds = productIds;
  }

  //
  Future<void> _processProductDetails(Map<String, dynamic> product) async {
    try {
      List<Future<void>> tasks = [];

      //  Fetch discount
      tasks.add(fetchDiscount(product['id']).then((discount) {
        if (discount != null && discount['reduction_type'] == 'percentage') {
          product['discount'] = double.tryParse(discount['reduction']) ?? 0;
        } else {
          product['discount'] = 0;
        }
      }));

      //  Fetch tax-inclusive price (TTC)
      tasks.add(fetchTTCPrice(
              product['id'], product['price'], product['id_tax_rules_group'])
          .then((ttcPrice) {
        product['ttc_price'] = ttcPrice ?? product['price'];
      }));

      //  Fetch images
      tasks.add(Future(() {
        if (product.containsKey('associations') &&
            product['associations'].containsKey('images')) {
          final images = product['associations']['images'] as List;
          List<String> imageUrls =
              images.map((image) => constructImageUrl(image['id'])).toList();
          product['image_urls'] = imageUrls;
        } else {
          product['image_urls'] = [];
        }
      }));

      await Future.wait(tasks);
    } catch (e) {
      AlkLoggerHelper.error("Product ${product['id']} processing failed", e);
    }
  }

  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(discountApi));
      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));
        if (!discountData.containsKey('specific_prices')) return null;

        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) return null;

        Map<String, dynamic>? selectedDiscount = discounts.first;
        double parsedReduction =
            double.tryParse(selectedDiscount?['reduction']) ?? 0;
        parsedReduction = parsedReduction * 100;

        return {
          'reduction': parsedReduction.toString(),
          'reduction_type': 'percentage',
        };
      }
    } catch (e) {
      AlkLoggerHelper.error("Discount fetch failed for product $productId", e);
    }
    return null;
  }

  Future<double?> fetchTTCPrice(
      int productId, dynamic priceHT, dynamic taxRulesGroupId) async {
    try {
      if (taxRulesGroupId == 0) {
        return double.tryParse(priceHT.toString());
      }

      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax,id_tax_rules_group]&filter[id_tax_rules_group]=[$taxRulesGroupId]&limit=1&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) {
        return double.tryParse(priceHT.toString());
      }

      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
      if (taxRulesData['tax_rules'] == null ||
          taxRulesData['tax_rules'].isEmpty) {
        return double.tryParse(priceHT.toString());
      }

      final int taxId = taxRulesData['tax_rules'][0]['id_tax'];

      final taxesApi =
          'https://www.alkirtas.com/api/taxes?display=[rate,id]&filter[id]=[$taxId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final taxesResponse = await http.get(Uri.parse(taxesApi));
      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
      final double taxRate = double.parse(taxesData['taxes'][0]['rate']);

      return (double.parse(priceHT.toString())) * (1 + (taxRate / 100));
    } catch (e) {
      AlkLoggerHelper.error("TTC price fetch failed", e);
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

  //
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
