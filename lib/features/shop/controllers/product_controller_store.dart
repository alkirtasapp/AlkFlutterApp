import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/data/controllers/details_controller.dart';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
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

      // Get Product IDs from the category
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

      List<Map<String, dynamic>> fetchedProducts = [];
      int currentOffset = offset;
      Set<int> processedProductIds = {};

      const int batchSize = 10; // Adjust as needed

      // Keep fetching batches until we have enough active products or reach the end
      while (fetchedProducts.length < limit && currentOffset < productIds.length) {
        List<int> batchProductIds = [];

        // Collect product IDs for the batch
        while (batchProductIds.length < batchSize && currentOffset < productIds.length) {
          int productId = productIds[currentOffset];
          currentOffset++;

          if (productId == null || productId <= 0 || processedProductIds.contains(productId)) {
            continue;
          }

          processedProductIds.add(productId);
          batchProductIds.add(productId);
        }

        if (batchProductIds.isEmpty) {
          break;
        }

        // Fetch and process products for the batch
        List<Map<String, dynamic>> tempProducts = [];
        await _fetchAndProcessProducts(batchProductIds, tempProducts);

        // Only add active products
        fetchedProducts.addAll(tempProducts.where((p) => p['active'].toString() == '1'));

        // If we reach the end of productIds, break
        if (currentOffset >= productIds.length) {
          break;
        }
      }

      // If we have more than limit, trim the list
      if (fetchedProducts.length > limit) {
        fetchedProducts = fetchedProducts.take(limit).toList();
      }

      // Cache the results
      box.put(cacheKey, fetchedProducts);
      AlkLoggerHelper.info("Cached products for Category $categoryId, Offset $offset");
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




  Future<void> _processProductDetails(Map<String, dynamic> product, List<Map<String, dynamic>> fetchedProducts) async {
    try {
      // Ensure product has stock
      product['id'] = int.tryParse(product['id'].toString()) ?? 0;
      product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
      // Fetch actual quantity using QuantityController
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

      if (product.containsKey('associations') &&
          product['associations'].containsKey('images')) {
        final images = product['associations']['images'] as List;
        product['image_urls'] =
            images.map((image) => constructImageUrl(image['id'])).toList();
      } else {
        product['image_urls'] = [];
      }

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

      // Ensure reference field is present (should already be in product data from API)
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

      // Search by EAN13 in PrestaShop API
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

      // PrestaShop returns products as either a List or a Map depending on the number of results
      dynamic productsData = productData['products'];
      Map<String, dynamic> product;

      if (productsData is List) {
        // Multiple products or array format
        if (productsData.isEmpty) {
          AlkLoggerHelper.warning("No product found with barcode: $barcode");
          return null;
        }
        product = productsData[0];
      } else if (productsData is Map) {
        // Single product returned as Map with product ID as key
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

      // Process the product details (discount, price, images, etc.)
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

  // Search product by reference (default_code)
  Future<Map<String, dynamic>?> searchProductByReference(String reference) async {
    try {
      AlkLoggerHelper.debug("Searching for product with reference: $reference");

      // Search by reference in PrestaShop API
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

      // PrestaShop returns products as either a List or a Map
      dynamic productsData = productData['products'];
      Map<String, dynamic> product;

      if (productsData is List) {
        if (productsData.isEmpty) {
          AlkLoggerHelper.warning("No product found with reference: $reference");
          return null;
        }
        product = productsData[0];
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

      // Process the product details (discount, price, images, etc.)
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
