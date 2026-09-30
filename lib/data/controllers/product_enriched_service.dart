import 'dart:convert';
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';
import 'package:alkirtas/utils/network/cache_buster.dart';

/// Service to fetch pre-calculated product enrichment data from PrestaShop module.
/// This replaces multiple API calls (quantity, discount, tax, brand) with a single call.
class ProductEnrichedService {
  static const String _moduleBaseUrl = 'https://www.alkirtas.com/module/productenriched/api';
  static const String _homeDealsConfigUrl = 'https://www.alkirtas.com/banners/home_deals.json';
  static final Map<String, Future<List<Map<String, dynamic>>>>
      _homeSellingRequests = {};

  /// Reload configured home deals after an explicit home refresh.
  static void clearHomeSellingCache() => _homeSellingRequests.clear();

  /// Fetch enriched data for multiple product IDs
  /// Returns a Map with product ID as key for easy lookup
  static Future<Map<int, Map<String, dynamic>>> fetchEnrichedByIds(List<int> productIds) async {
    if (productIds.isEmpty) return {};

    try {
      // Join IDs with pipe separator
      final idsParam = productIds.join('|');
      final url = '$_moduleBaseUrl?action=getByIds&ids=$idsParam&ws_key=${AppConfig.prestashopApiKey}';

      AlkLoggerHelper.debug('Fetching enriched data for ${productIds.length} products');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Enriched API error: ${response.statusCode}');
        return {};
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        AlkLoggerHelper.warning('Enriched API returned no data');
        return {};
      }

      final products = data['data']['products'] as List<dynamic>? ?? [];

      // Index by product ID for O(1) lookup
      final Map<int, Map<String, dynamic>> indexed = {};
      for (var product in products) {
        final id = int.tryParse(product['id_product'].toString()) ?? 0;
        if (id > 0) {
          indexed[id] = Map<String, dynamic>.from(product);
        }
      }

      AlkLoggerHelper.debug('Fetched enriched data for ${indexed.length} products');
      return indexed;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching enriched data', e);
      return {};
    }
  }

  /// Fetch enriched data for products in a category
  static Future<List<Map<String, dynamic>>> fetchEnrichedByCategory(
    int categoryId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = '$_moduleBaseUrl?action=getByCategory&category=$categoryId&limit=$limit&offset=$offset&ws_key=${AppConfig.prestashopApiKey}';

      AlkLoggerHelper.debug('Fetching enriched products for category $categoryId (offset: $offset, limit: $limit)');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Enriched API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        AlkLoggerHelper.warning('Enriched API returned no data for category $categoryId');
        return [];
      }

      final products = data['data']['products'] as List<dynamic>? ?? [];
      return products.map((p) => Map<String, dynamic>.from(p)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error fetching enriched data by category', e);
      return [];
    }
  }

  /// First-screen selling feed using existing enriched category endpoints.
  /// This lets us test a conversion block before adding a dedicated backend route.
  static Future<List<Map<String, dynamic>>> fetchHomeSellingProducts({
    List<int> categoryIds = const [290],
    int limit = 8,
  }) {
    final cacheKey = '${categoryIds.join(',')}:$limit';
    return _homeSellingRequests.putIfAbsent(
      cacheKey,
      () => _loadHomeSellingProducts(categoryIds: categoryIds, limit: limit),
    );
  }

  static Future<List<Map<String, dynamic>>> _loadHomeSellingProducts({
    required List<int> categoryIds,
    required int limit,
  }) async {
    final configuredIds = await _fetchHomeDealProductIds();
    if (configuredIds != null) {
      if (configuredIds.isEmpty) return [];

      final productsById = await fetchEnrichedByIds(configuredIds.take(100).toList());
      final configuredProducts = configuredIds
          .where((id) => productsById.containsKey(id))
          .map((id) => productsById[id]!)
          .where((row) {
            final stock = int.tryParse(row['quantity'].toString()) ?? 0;
            return stock > 0;
          })
          .take(limit)
          .toList();

      if (configuredProducts.isNotEmpty) return configuredProducts;
      AlkLoggerHelper.warning('Home deals config returned no valid in-stock products, using fallback');
    }

    return _loadHomeFallbackByModifiedDate(categoryIds, limit);
  }

  /// Read dates for the complete category before choosing the newest deals.
  /// Enriched category responses do not guarantee modification-date ordering.
  static Future<List<Map<String, dynamic>>> _loadHomeFallbackByModifiedDate(
    List<int> categoryIds,
    int limit,
  ) async {
    if (limit <= 0) return [];
    try {
      final categories = await Future.wait(categoryIds.map(
        (id) => ProductListCategory().fetchProductIdsFromCategory(id),
      ));
      final ids = categories.expand((ids) => ids).toSet().toList();
      final datedProducts = <Map<String, dynamic>>[];
      for (var offset = 0; offset < ids.length; offset += 100) {
        final batch = ids.skip(offset).take(100).join('|');
        final uri = Uri.parse(AppConfig.prestashopUrl('products', params: {
          'display': '[id,date_upd]',
          'filter[id]': '[$batch]',
          'filter[active]': '[1]',
        }));
        final response = await http.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          AlkLoggerHelper.warning('Home deals modification dates unavailable: HTTP ${response.statusCode}');
          return [];
        }
        final data = json.decode(utf8.decode(response.bodyBytes));
        final rows = data['products'] as List<dynamic>? ?? [];
        datedProducts.addAll(rows.map((row) => Map<String, dynamic>.from(row)));
      }
      datedProducts.sort((a, b) {
        final aDate = DateTime.tryParse(a['date_upd'].toString());
        final bDate = DateTime.tryParse(b['date_upd'].toString());
        final dateOrder = (bDate?.millisecondsSinceEpoch ?? 0)
            .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
        if (dateOrder != 0) return dateOrder;
        return (int.tryParse(b['id'].toString()) ?? 0)
            .compareTo(int.tryParse(a['id'].toString()) ?? 0);
      });

      final products = <Map<String, dynamic>>[];
      // Keep scanning in date order if newer products are unavailable or sold out.
      for (var offset = 0; offset < datedProducts.length; offset += 30) {
        final batch = datedProducts.skip(offset).take(30).toList();
        final enriched = await fetchEnrichedByIds(batch
            .map((row) => int.parse(row['id'].toString())).toList());
        for (final row in batch) {
          final product = enriched[int.parse(row['id'].toString())];
          if (product == null) continue;
          final stock = int.tryParse(product['quantity'].toString()) ?? 0;
          if (stock <= 0) continue;
          products.add(product);
          if (products.length == limit) return products;
        }
      }
      return products;
    } catch (e) {
      AlkLoggerHelper.warning('Home deals fallback could not load modification dates');
      return [];
    }
  }
  static Future<List<int>?> _fetchHomeDealProductIds() async {
    try {
      final response = await http
          .get(CacheBuster.uri(_homeDealsConfigUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;

      final enabled = data['enabled'];
      if (enabled == false || enabled == 'false' || enabled == 0 || enabled == '0') {
        return <int>[];
      }

      final rawIds = data['product_ids'];
      if (rawIds is! List) return null;

      final ids = rawIds
          .map((value) => int.tryParse(value.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();

      return ids.isEmpty ? null : ids;
    } catch (e) {
      AlkLoggerHelper.warning('Home deals config unavailable: $e');
      return null;
    }
  }

  /// Fetch enriched data for products by manufacturer (brand)
  static Future<List<Map<String, dynamic>>> fetchEnrichedByManufacturer(
    int manufacturerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = '$_moduleBaseUrl?action=getByManufacturer&manufacturer=$manufacturerId&limit=$limit&offset=$offset&ws_key=${AppConfig.prestashopApiKey}';

      AlkLoggerHelper.debug('Fetching enriched products for manufacturer $manufacturerId (offset: $offset, limit: $limit)');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Enriched API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        AlkLoggerHelper.warning('Enriched API returned no data for manufacturer $manufacturerId');
        return [];
      }

      final products = data['data']['products'] as List<dynamic>? ?? [];
      return products.map((p) => Map<String, dynamic>.from(p)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error fetching enriched data by manufacturer', e);
      return [];
    }
  }

  /// Search brands by name (returns matching manufacturers with product counts)
  static Future<List<Map<String, dynamic>>> searchBrands(String query) async {
    if (query.length < 2) return [];
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_moduleBaseUrl?action=searchBrands&query=$encodedQuery&ws_key=${AppConfig.prestashopApiKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['success'] != true || data['data'] == null) return [];
      final brands = data['data']['brands'] as List<dynamic>? ?? [];
      return brands.map((b) => Map<String, dynamic>.from(b)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error searching brands', e);
      return [];
    }
  }

  /// Fetch enriched data for a product by reference
  static Future<Map<String, dynamic>?> fetchEnrichedByReference(String reference) async {
    try {
      final url = '$_moduleBaseUrl?action=getByReference&reference=$reference&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Enriched API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data']?['product'] == null) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']['product']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching enriched data by reference', e);
      return null;
    }
  }

  /// Fetch enriched data for a product by EAN13 (barcode)
  static Future<Map<String, dynamic>?> fetchEnrichedByBarcode(String barcode) async {
    try {
      final url = '$_moduleBaseUrl?action=getByEan13&ean13=$barcode&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Enriched API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data']?['product'] == null) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']['product']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching enriched data by barcode', e);
      return null;
    }
  }

  /// Log search query for insights
  static Future<void> logSearchQuery(String query, int resultCount, String userType) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_moduleBaseUrl?action=logSearch&query=$encodedQuery&result_count=$resultCount&user_type=$userType&ws_key=${AppConfig.prestashopApiKey}';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success']) {
          AlkLoggerHelper.info('Search logged: $query ($resultCount results)');
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Failed to log search: $e');
    }
  }

  /// Get trending searches
  static Future<List<Map<String, dynamic>>> getTrendingSearches({int limit = 10, int days = 7}) async {
    try {
      final url = '$_moduleBaseUrl?action=getTrendingSearches&limit=$limit&days=$days&ws_key=${AppConfig.prestashopApiKey}';
      
      print('Fetching trending searches from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success']) {
          // Handle both array and object responses
          final trendingData = data['data']['trending'];
          List<Map<String, dynamic>> trending;
          
          if (trendingData is List) {
            trending = List<Map<String, dynamic>>.from(trendingData);
          } else if (trendingData is Map) {
            // Convert object values to array
            trending = (trendingData as Map<String, dynamic>)
                .values
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          } else {
            trending = [];
          }
          
          print('Trending searches loaded: ${trending.length}');
          return trending;
        }
      }
      return [];
    } catch (e) {
      print('Failed to fetch trending searches: $e');
      return [];
    }
  }

  /// Apply enriched data to a product map
  /// This merges the enriched fields into the existing product data
  static void applyEnrichedData(Map<String, dynamic> product, Map<String, dynamic> enriched) {
    // Quantity
    product['quantity'] = int.tryParse(enriched['quantity'].toString()) ?? 0;

    // Price with tax (TTC) - use price_ttc (before discount), NOT final_price_ttc
    // The UI applies discount itself, so we need the original TTC price
    product['ttc_price'] = double.tryParse(enriched['price_ttc'].toString()) ??
                           product['price'] ?? 0.0;

    // Discount percentage
    if (enriched['has_discount'] == 1 || enriched['has_discount'] == '1') {
      product['discount'] = double.tryParse(enriched['discount_value'].toString()) ?? 0.0;
    } else {
      product['discount'] = 0.0;
    }

    // Brand/manufacturer name
    if (enriched['manufacturer_name'] != null && enriched['manufacturer_name'].toString().isNotEmpty) {
      product['brand'] = enriched['manufacturer_name'];
    } else {
      product['brand'] = 'Unknown';
    }

    // Reference and EAN13 (if not already present)
    if (enriched['reference'] != null) {
      product['reference'] = enriched['reference'];
    }
    if (enriched['ean13'] != null) {
      product['ean13'] = enriched['ean13'];
    }
  }

  /// Build a complete product map from enriched data only (no 2nd API call needed)
  /// Returns a product map ready for display
  /// IMPORTANT: Field names must match what ProductCardStore expects!
  static Map<String, dynamic> buildProductFromEnriched(Map<String, dynamic> enriched) {
    final productId = int.tryParse(enriched['id_product'].toString()) ?? 0;

    // Get the raw image ID - UI will construct the URL itself
    final idDefaultImage = enriched['id_default_image'];

    // Build image URLs list for product detail page (uses image_urls)
    List<String> imageUrls = [];
    if (idDefaultImage != null) {
      final imageId = idDefaultImage.toString();
      if (imageId.isNotEmpty && imageId != 'null' && imageId != '0') {
        final path = imageId.split('').join('/');
        final imageUrl = 'https://www.alkirtas.com/img/p/$path/$imageId.jpg';
        imageUrls.add(imageUrl);
      }
    }

    // Get brand name - keep as manufacturer_name for UI compatibility
    final manufacturerName = (enriched['manufacturer_name'] != null && enriched['manufacturer_name'].toString().isNotEmpty)
        ? enriched['manufacturer_name'].toString()
        : 'Unknown';

    final manufacturerId = int.tryParse(enriched['id_manufacturer'].toString()) ?? 0;

    //AlkLoggerHelper.debug('Building product $productId: manufacturer=$manufacturerName, id_default_image=$idDefaultImage');

    return {
      'id': productId,
      'name': (enriched['name'] ?? 'Unknown').toString().replaceAll("\\'", "'"),
      'description_short': (enriched['description_short'] ?? '').toString().replaceAll("\\'", "'"),
      'price': double.tryParse(enriched['price_ht'].toString()) ?? 0.0,
      'ttc_price': double.tryParse(enriched['price_ttc'].toString()) ?? 0.0,
      'quantity': int.tryParse(enriched['quantity'].toString()) ?? 0,
      'discount': (enriched['has_discount'] == 1 || enriched['has_discount'] == '1')
          ? double.tryParse(enriched['discount_value'].toString()) ?? 0.0
          : 0.0,
      // UI expects 'manufacturer_name' not 'brand'
      'manufacturer_name': manufacturerName,
      'brand': manufacturerName, // Keep for backwards compatibility
      'reference': enriched['reference'] ?? '',
      'ean13': enriched['ean13'] ?? '',
      'id_tax_rules_group': int.tryParse(enriched['id_tax_rules_group'].toString()) ?? 0,
      'active': enriched['is_active']?.toString() ?? '1',
      // UI expects 'id_default_image' to construct URL itself
      'id_default_image': idDefaultImage,
      'image_urls': imageUrls, // For product detail page
      'id_manufacturer': manufacturerId,
    };
  }

  /// Check if the enriched module is available
  static Future<bool> isModuleAvailable() async {
    try {
      final url = '$_moduleBaseUrl?action=getStats&ws_key=${AppConfig.prestashopApiKey}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch the available filter options (price range, manufacturers, features) for a category.
  /// Pass `filterParams` (from StoreFilterState.toQueryParams()) so counts reflect
  /// the in-progress selection — each section's count pool excludes that section's own filter.
  static Future<Map<String, dynamic>?> fetchFacets(
    int categoryId, {
    Map<String, String> filterParams = const {},
  }) async {
    try {
      final buf = StringBuffer('$_moduleBaseUrl?action=getFacets&category=$categoryId');
      filterParams.forEach((k, v) {
        buf.write('&$k=${Uri.encodeQueryComponent(v)}');
      });
      buf.write('&ws_key=${AppConfig.prestashopApiKey}');
      final url = buf.toString();

      AlkLoggerHelper.debug('Fetching facets for category $categoryId (filters=${filterParams.length})');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Facets API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['success'] != true || data['data'] == null) {
        AlkLoggerHelper.warning('Facets API returned no data for category $categoryId');
        return null;
      }

      return Map<String, dynamic>.from(data['data']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching facets', e);
      return null;
    }
  }

  /// Fetch products in a category matching the given filter params.
  /// `filterParams` should come from StoreFilterState.toQueryParams().
  /// Returns the same shape as fetchEnrichedByCategory so buildProductFromEnriched works on each row.
  static Future<List<Map<String, dynamic>>> fetchFilteredProducts(
    int categoryId, {
    required Map<String, String> filterParams,
    String sort = 'default',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final buf = StringBuffer('$_moduleBaseUrl?action=getProductsFiltered'
          '&category=$categoryId'
          '&sort=$sort'
          '&limit=$limit'
          '&offset=$offset');
      filterParams.forEach((k, v) {
        buf.write('&$k=${Uri.encodeQueryComponent(v)}');
      });
      buf.write('&ws_key=${AppConfig.prestashopApiKey}');
      final url = buf.toString();

      AlkLoggerHelper.debug('Fetching filtered products for category $categoryId (offset $offset, sort $sort)');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Filtered API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['success'] != true || data['data'] == null) {
        AlkLoggerHelper.warning('Filtered API returned no data');
        return [];
      }

      final products = data['data']['products'] as List<dynamic>? ?? [];
      return products.map((p) => Map<String, dynamic>.from(p)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error fetching filtered products', e);
      return [];
    }
  }
}
