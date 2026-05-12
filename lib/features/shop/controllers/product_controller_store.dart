import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/data/controllers/details_controller.dart';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/features/shop/controllers/brand_controller.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class ProductControllerStore {
  final QuantityController quantityController = QuantityController();
  final DiscountController discountController = DiscountController();
  final TaxController taxController = TaxController();
  final ProductListCategory productListCategory = ProductListCategory();
  final DetailsController detailsController = DetailsController();
  final BrandController brandController = BrandController();

  // Flag to use enriched API (set to true after module is installed)
  static bool useEnrichedApi = true;

  Future<List<Map<String, dynamic>>?> fetchProductDataStore(
      int categoryId, int offset, int limit) async {
    try {
      var box = Hive.box('productCache');
      String cacheKey = "store_product_${categoryId}_$offset";

      // Check Cache First
      if (box.containsKey(cacheKey)) {
        AlkLoggerHelper.debug(
            "Using cached products for Category $categoryId, Offset $offset");
        return List<Map<String, dynamic>>.from(box.get(cacheKey));
      }

      List<Map<String, dynamic>> fetchedProducts = [];

      // OPTIMIZED PATH: Use enriched API to get complete product data (single API call!)
      if (useEnrichedApi) {
        final enrichedProducts = await ProductEnrichedService.fetchEnrichedByCategory(
          categoryId,
          limit: limit,
          offset: offset,
        );

        if (enrichedProducts.isNotEmpty) {
          AlkLoggerHelper.debug("Enriched API returned ${enrichedProducts.length} active products for category $categoryId");

          // Check if enriched data has name field (v1.1.0+ with full data)
          final hasFullData = enrichedProducts.first.containsKey('name') &&
                              enrichedProducts.first['name'] != null;

          if (hasFullData) {
            // SINGLE API CALL PATH: Build products directly from enriched data
            AlkLoggerHelper.debug("Using single API call path (enriched has full data)");

            for (var enriched in enrichedProducts) {
              final product = ProductEnrichedService.buildProductFromEnriched(enriched);
              fetchedProducts.add(product);
            }
          } else {
            // FALLBACK: 2 API calls (old enriched table without name/description)
            AlkLoggerHelper.debug("Using 2 API calls path (enriched missing name field)");

            final List<int> activeProductIds = enrichedProducts
                .map((p) => int.tryParse(p['id_product'].toString()) ?? 0)
                .where((id) => id > 0)
                .toList();

            if (activeProductIds.isNotEmpty) {
              final Map<int, Map<String, dynamic>> enrichedIndex = {};
              for (var enriched in enrichedProducts) {
                final id = int.tryParse(enriched['id_product'].toString()) ?? 0;
                if (id > 0) {
                  enrichedIndex[id] = enriched;
                }
              }

              final String productIdsParam = activeProductIds.join('|');
              final String productApi =
                  'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsParam]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

              AlkLoggerHelper.debug("Fetching full details for ${activeProductIds.length} products");
              final response = await http.get(Uri.parse(productApi));

              if (response.statusCode == 200) {
                final productData = json.decode(utf8.decode(response.bodyBytes));
                if (productData['products'] != null && productData['products'].isNotEmpty) {
                  for (var product in productData['products']) {
                    if (product is Map<String, dynamic>) {
                      final productId = int.tryParse(product['id'].toString()) ?? 0;
                      final enriched = enrichedIndex[productId];
                      await _processProductDetails(product, fetchedProducts, enriched: enriched);
                    }
                  }
                }
              }
            }
          }

          // Cache and return if we got results
          if (fetchedProducts.isNotEmpty) {
            box.put(cacheKey, fetchedProducts);
            AlkLoggerHelper.info("Cached ${fetchedProducts.length} products for Category $categoryId, Offset $offset (optimized)");
            return fetchedProducts;
          }
        }

        AlkLoggerHelper.debug("Enriched API returned no products, falling back to legacy method");
      }

      // FALLBACK PATH: Legacy method (fetch all IDs, loop through batches)
      final List<int> productIds =
          await productListCategory.fetchProductIdsFromCategory(categoryId);
      if (productIds.isEmpty) {
        AlkLoggerHelper.warning("No product IDs found for Category ID: $categoryId");
        return null;
      }

      if (offset >= productIds.length) {
        AlkLoggerHelper.warning(
            "Offset ($offset) is beyond available products (${productIds.length}) for Category ID: $categoryId");
        return [];
      }

      int currentOffset = offset;
      Set<int> processedProductIds = {};

      const int batchSize = 20;

      while (fetchedProducts.length < limit && currentOffset < productIds.length) {
        List<int> batchProductIds = [];

        while (batchProductIds.length < batchSize && currentOffset < productIds.length) {
          int productId = productIds[currentOffset];
          currentOffset++;

          if (productId <= 0 || processedProductIds.contains(productId)) {
            continue;
          }

          processedProductIds.add(productId);
          batchProductIds.add(productId);
        }

        if (batchProductIds.isEmpty) {
          break;
        }

        List<Map<String, dynamic>> tempProducts = [];
        await _fetchAndProcessProducts(batchProductIds, tempProducts);

        fetchedProducts.addAll(tempProducts.where((p) => p['active'].toString() == '1'));

        if (currentOffset >= productIds.length) {
          break;
        }
      }

      if (fetchedProducts.length > limit) {
        fetchedProducts = fetchedProducts.take(limit).toList();
      }

      box.put(cacheKey, fetchedProducts);
      AlkLoggerHelper.info("Cached products for Category $categoryId, Offset $offset (legacy)");
      return fetchedProducts;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching products', e);
      return null;
    }
  }

  Future<void> _fetchAndProcessProducts(List<int> batchProductIds, List<Map<String, dynamic>> fetchedProducts) async {
    String productIdsParam = batchProductIds.join('|');
    final String productApi =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsParam]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

    AlkLoggerHelper.debug("Fetching products for IDs: $productIdsParam");

    final response = await http.get(Uri.parse(productApi));
    if (response.statusCode != 200) {
      AlkLoggerHelper.error("API Error: ${response.statusCode}");
      return;
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));
    if (productData['products'] == null || productData['products'].isEmpty) {
      AlkLoggerHelper.warning("No products found for IDs: $productIdsParam");
      return;
    }

    // Fetch enriched data for all products in batch (single API call!)
    Map<int, Map<String, dynamic>> enrichedData = {};
    if (useEnrichedApi) {
      enrichedData = await ProductEnrichedService.fetchEnrichedByIds(batchProductIds);
      AlkLoggerHelper.debug("Fetched enriched data for ${enrichedData.length} products");
    }

    List<Future<void>> processingTasks = [];

    for (var product in productData['products']) {
      if (product is Map<String, dynamic> &&
          product.containsKey('active') &&
          product['active'].toString() == '1') {
        final productId = int.tryParse(product['id'].toString()) ?? 0;
        final enriched = enrichedData[productId];
        processingTasks.add(_processProductDetails(product, fetchedProducts, enriched: enriched));
      }
    }

    await Future.wait(processingTasks);
  }


 Future<List<String>> fetchProductFeatures(String productId) async {
  try {
    final DetailsController detailsController = DetailsController();
    final String apiUrl =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=$productId&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      AlkLoggerHelper.error("API Error: ${response.statusCode} for Product ID: $productId");
      return [];
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));

    if (productData == null ||
        !productData.containsKey('products') ||
        productData['products'].isEmpty) {
      return [];
    }

    final product = productData['products'][0];

    if (!product.containsKey('associations') ||
        !product['associations'].containsKey('product_features')) {
      return [];
    }

    final List<Map<String, dynamic>> featuresList =
        List<Map<String, dynamic>>.from(product['associations']['product_features']);

    Map<String, String> featureMap =
        await detailsController.fetchProductFeatures(featuresList);

    return featureMap.entries.map((e) => "${e.key}: ${e.value}").toList();
  } catch (e) {
    AlkLoggerHelper.error("Exception fetching features for product $productId", e);
    return [];
  }
}




  Future<void> _processProductDetails(
    Map<String, dynamic> product,
    List<Map<String, dynamic>> fetchedProducts, {
    Map<String, dynamic>? enriched,
  }) async {
    try {
      product['id'] = int.tryParse(product['id'].toString()) ?? 0;
      product['ttc_price'] = double.tryParse(product['ttc_price'].toString()) ?? 0.0;

      // Use enriched data if available (single API call), otherwise fallback to individual calls
      if (enriched != null && useEnrichedApi) {
        // Apply pre-calculated enriched data (no additional API calls!)
        ProductEnrichedService.applyEnrichedData(product, enriched);
      } else {
        // Fallback: individual API calls (old method)
        product['quantity'] = await quantityController.fetchQuantity(product['id']) ?? 0;

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

        // Fetch brand/manufacturer name
        if (product.containsKey('id_manufacturer')) {
          final manufacturerId = int.tryParse(product['id_manufacturer'].toString()) ?? 0;
          if (manufacturerId > 0) {
            final brandName = await brandController.fetchBrandNameById(manufacturerId);
            product['brand'] = brandName ?? 'Unknown';
          } else {
            product['brand'] = 'Unknown';
          }
        } else {
          product['brand'] = 'Unknown';
        }
      }

      // Build image URLs (always needed, not in enriched data)
      if (product.containsKey('associations') &&
          product['associations'].containsKey('images')) {
        final images = product['associations']['images'] as List;
        product['image_urls'] =
            images.map((image) => constructImageUrl(image['id'])).toList();
      } else {
        product['image_urls'] = [];
      }

      // Ensure reference field is present
      if (!product.containsKey('reference') || product['reference'] == null) {
        product['reference'] = '';
      }

      fetchedProducts.add(product);
    } catch (e) {
      AlkLoggerHelper.error("Error processing product details for ${product['id']}", e);
    }
  }
   // Fetch Products by IDs
  Future<List<Map<String, dynamic>>?> fetchProductsByIds(List<int> productIds) async {
    try {
      if (productIds.isEmpty) {
        AlkLoggerHelper.warning("No product IDs provided");
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
      AlkLoggerHelper.error('Error fetching products by IDs', e);
      return null;
    }
  }

  // Search product by barcode (EAN13)
  Future<Map<String, dynamic>?> searchProductByBarcode(String barcode) async {
    try {
      AlkLoggerHelper.debug("Searching for product with barcode: $barcode");

      // Try enriched API first (faster, single call)
      if (useEnrichedApi) {
        final enriched = await ProductEnrichedService.fetchEnrichedByBarcode(barcode);
        if (enriched != null) {
          // Still need to fetch full product data for images, name, description, etc.
          final productId = int.tryParse(enriched['id_product'].toString()) ?? 0;
          if (productId > 0) {
            final product = await _fetchFullProductById(productId);
            if (product != null) {
              ProductEnrichedService.applyEnrichedData(product, enriched);
              _buildImageUrls(product);
              AlkLoggerHelper.info("Product found with barcode: $barcode - ${product['name']}");
              return product;
            }
          }
        }
      }

      // Fallback: Search by EAN13 in PrestaShop API
      final String productApi =
          'https://www.alkirtas.com/api/products?display=full&filter[ean13]=$barcode&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(productApi));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error("API Error: ${response.statusCode}");
        return null;
      }

      final productData = json.decode(utf8.decode(response.bodyBytes));

      if (productData['products'] == null || productData['products'].isEmpty) {
        AlkLoggerHelper.warning("No product found with barcode: $barcode");
        return null;
      }

      dynamic productsData = productData['products'];
      Map<String, dynamic> product;

      if (productsData is List) {
        if (productsData.isEmpty) {
          AlkLoggerHelper.warning("No product found with barcode: $barcode");
          return null;
        }
        product = Map<String, dynamic>.from(productsData[0]);
      } else if (productsData is Map) {
        final productKeys = productsData.keys.toList();
        if (productKeys.isEmpty) {
          AlkLoggerHelper.warning("No product found with barcode: $barcode");
          return null;
        }
        product = Map<String, dynamic>.from(productsData[productKeys.first]);
      } else {
        AlkLoggerHelper.error("Unexpected products data format: ${productsData.runtimeType}");
        return null;
      }

      // Process the product details
      List<Map<String, dynamic>> tempProducts = [];
      await _processProductDetails(product, tempProducts);

      if (tempProducts.isEmpty) {
        AlkLoggerHelper.error("Error processing product with barcode: $barcode");
        return null;
      }

      AlkLoggerHelper.info("Product found with barcode: $barcode - ${tempProducts[0]['name']}");
      return tempProducts[0];
    } catch (e) {
      AlkLoggerHelper.error('Error searching product by barcode', e);
      return null;
    }
  }
  // Construct Image URL from image ID
  String constructImageUrl(dynamic imageId) {
    if (imageId == null) return 'placeholder_image_url';
    final imageIdStr = imageId.toString();
    final path = imageIdStr.split('').join('/');
    return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
  }

  // Fetch full product data by ID (for name, description, images, etc.)
  Future<Map<String, dynamic>?> _fetchFullProductById(int productId) async {
    try {
      // Use filter[id] pattern (returns "products" array) — works reliably with PrestaShop
      final String productApi =
          'https://www.alkirtas.com/api/products?display=full&filter[id]=$productId&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(productApi));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('_fetchFullProductById: API returned ${response.statusCode} for product $productId');
        return null;
      }

      final productData = json.decode(utf8.decode(response.bodyBytes));

      if (productData['products'] != null) {
        final products = productData['products'];
        if (products is List && products.isNotEmpty) {
          return Map<String, dynamic>.from(products.first);
        }
      }
      // Fallback: direct access returns singular "product"
      if (productData['product'] != null) {
        return Map<String, dynamic>.from(productData['product']);
      }
      AlkLoggerHelper.error('_fetchFullProductById: no product data in response for $productId');
      return null;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching product by ID: $productId', e);
      return null;
    }
  }

  // Build image URLs for a product
  void _buildImageUrls(Map<String, dynamic> product) {
    if (product.containsKey('associations') &&
        product['associations'].containsKey('images')) {
      final images = product['associations']['images'] as List;
      product['image_urls'] =
          images.map((image) => constructImageUrl(image['id'])).toList();
    } else {
      product['image_urls'] = [];
    }
  }

  /// Fetches the complete gallery (associations.images) for a single product.
  /// Uses the regular PrestaShop endpoint so we keep using the enriched API
  /// elsewhere without toggling [useEnrichedApi].
  Future<List<String>> fetchProductImages(String productId) async {
    try {
      final intId = int.tryParse(productId);
      if (intId == null) {
        AlkLoggerHelper.error('fetchProductImages: invalid productId=$productId');
        return [];
      }

      final product = await _fetchFullProductById(intId);
      if (product == null) {
        AlkLoggerHelper.error('fetchProductImages: _fetchFullProductById returned null for $productId');
        return [];
      }

   

      _buildImageUrls(product);
      final images = product['image_urls'];
      if (images is List) {
      //  AlkLoggerHelper.debug('fetchProductImages: built ${images.length} image URLs');
        return images.map((image) => image.toString()).where((url) => url.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      AlkLoggerHelper.error('Error fetching gallery for product $productId', e);
      return [];
    }
  }

  // Search product by reference (default_code)
  Future<Map<String, dynamic>?> searchProductByReference(String reference) async {
    try {
      AlkLoggerHelper.debug("Searching for product with reference: $reference");

      // Try enriched API first (faster, single call)
      if (useEnrichedApi) {
        final enriched = await ProductEnrichedService.fetchEnrichedByReference(reference);
        if (enriched != null) {
          final productId = int.tryParse(enriched['id_product'].toString()) ?? 0;
          if (productId > 0) {
            final product = await _fetchFullProductById(productId);
            if (product != null) {
              ProductEnrichedService.applyEnrichedData(product, enriched);
              _buildImageUrls(product);
              AlkLoggerHelper.info("Product found with reference: $reference - ${product['name']}");
              return product;
            }
          }
        }
      }

      // Fallback: Search by reference in PrestaShop API
      final String productApi =
          'https://www.alkirtas.com/api/products?display=full&filter[reference]=$reference&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(productApi));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error("API Error: ${response.statusCode}");
        return null;
      }

      final productData = json.decode(utf8.decode(response.bodyBytes));

      if (productData['products'] == null || productData['products'].isEmpty) {
        AlkLoggerHelper.warning("No product found with reference: $reference");
        return null;
      }

      dynamic productsData = productData['products'];
      Map<String, dynamic> product;

      if (productsData is List) {
        if (productsData.isEmpty) {
          AlkLoggerHelper.warning("No product found with reference: $reference");
          return null;
        }
        product = Map<String, dynamic>.from(productsData[0]);
      } else if (productsData is Map) {
        final productKeys = productsData.keys.toList();
        if (productKeys.isEmpty) {
          AlkLoggerHelper.warning("No product found with reference: $reference");
          return null;
        }
        product = Map<String, dynamic>.from(productsData[productKeys.first]);
      } else {
        AlkLoggerHelper.error("Unexpected products data format: ${productsData.runtimeType}");
        return null;
      }

      // Process the product details
      List<Map<String, dynamic>> tempProducts = [];
      await _processProductDetails(product, tempProducts);

      if (tempProducts.isEmpty) {
        AlkLoggerHelper.error("Error processing product with reference: $reference");
        return null;
      }

      AlkLoggerHelper.info("Product found with reference: $reference - ${tempProducts[0]['name']}");
      return tempProducts[0];
    } catch (e) {
      AlkLoggerHelper.error('Error searching product by reference', e);
      return null;
    }
  }

  /// Fetch filtered products for a category using the enriched module's getProductsFiltered action.
  /// Bypasses the Hive cache because filter combinations have a long tail.
  Future<List<Map<String, dynamic>>?> fetchFilteredProductsForCategory(
    int categoryId, {
    required Map<String, String> filterParams,
    required String sort,
    required int offset,
    required int limit,
  }) async {
    try {
      final enrichedRows = await ProductEnrichedService.fetchFilteredProducts(
        categoryId,
        filterParams: filterParams,
        sort: sort,
        limit: limit,
        offset: offset,
      );

      if (enrichedRows.isEmpty) {
        AlkLoggerHelper.debug('Filtered API returned no products for category $categoryId');
        return [];
      }

      // Same fast path as fetchProductDataStore: build products directly from enriched rows
      final List<Map<String, dynamic>> products = [];
      for (final enriched in enrichedRows) {
        products.add(ProductEnrichedService.buildProductFromEnriched(enriched));
      }

      AlkLoggerHelper.debug(
          'Filtered: ${products.length} products for category $categoryId (offset $offset)');
      return products;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching filtered products', e);
      return null;
    }
  }
}


// This Controller is used to fetch product data from the PrestaShop API for StoreDrawer Screen (Noutique)
// the Store Screen contain a drawer that holds all the categories and subCategories of the store
// the user can navigate through the categories and subCategories to find the products he is looking for
// Products are being fetched from certain categories and then a laalkirtas products are selected
/* -fields extracted from the productApi :
      - ProductID
      - productName
      - productPrice
      - constructImages (to get the product image)
      - productDescription
      - productReference
      - productManufacturer
      - productAvailableNow
      - productCategoryID
        
  -fields extracted from the categoryApi :
      - CategoryID
      - CategoryName
      - CategoryParentID
      - CategoryLevelDepth

  -fields extracted from the Feature api : 
      - FeatureID
      - FeatureName
      - FeatureValue
      - FeaturePosition
      - FeatureCustom
      - FeatureIDProduct
   
  -fields extracted from the tax api :
      - TaxID
      - TaxRate
  -fields extracted from stock api :
      - StockID
      - StockQuantity      
*/
