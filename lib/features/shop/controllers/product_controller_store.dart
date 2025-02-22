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

 Future<List<Map<String, dynamic>>?> fetchProductDataStore(int categoryId, int offset, int limit) async {
  try {
    var box = Hive.box('productCache');
    String cacheKey = "store_product_${categoryId}_$offset";

    // Check Cache First
    if (box.containsKey(cacheKey)) {
      print("⚡ Using cached products for Category $categoryId, Offset $offset");
      return List<Map<String, dynamic>>.from(box.get(cacheKey));
    }

    // Get Product IDs from the category
    final List<int> productIds = await productListCategory.fetchProductIdsFromCategory(categoryId);
    if (productIds.isEmpty) {
      print("⚠️ No product IDs found for Category ID: $categoryId");
      return null;
    }

    // Ensure we start from the correct offset
    if (offset >= productIds.length) {
      print("❌ No more products to fetch for Category ID: $categoryId");
      return [];
    }

    // Fetch Products from API
    String productIdsParam = productIds.skip(offset).take(limit).join('|');
    final String productApi =
        'https://www.alkirtas.com/api/products?display=full&filter[id]=[$productIdsParam]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("📡 Fetching products for Category ID: $categoryId, Offset: $offset");

    final response = await http.get(Uri.parse(productApi));
    if (response.statusCode != 200) {
      print("❌ API Error: ${response.statusCode}");
      return null;
    }

    final productData = json.decode(utf8.decode(response.bodyBytes));
    if (productData['products'] == null || productData['products'].isEmpty) {
      print("⚠️ No products found for Category ID: $categoryId");
      return null;
    }

    List<Map<String, dynamic>> fetchedProducts = [];

    for (var product in productData['products']) {
      if (product is Map<String, dynamic> &&
          product.containsKey('active') &&
          product['active'].toString() == '1') {

        // Fetch details, images, stock, and discounts
        product['id'] = int.tryParse(product['id'].toString()) ?? 0;
        product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
        product['quantity'] = int.tryParse(product['quantity'].toString()) ?? 0;

        final discount = await discountController.fetchDiscount(product['id']);
        product['discount'] = discount != null && discount['reduction_type'] == 'percentage'
            ? double.tryParse(discount['reduction'].toString()) ?? 0
            : 0;

        product['ttc_price'] = await taxController.fetchTTCPrice(
            product['id'], product['price'], product['id_tax_rules_group']) ?? product['price'];

        if (product.containsKey('associations') && product['associations'].containsKey('images')) {
          final images = product['associations']['images'] as List;
          product['image_urls'] = images.map((image) => constructImageUrl(image['id'])).toList();
        } else {
          product['image_urls'] = [];
        }

        product['quantity'] = await quantityController.fetchQuantity(product['id']) ?? 0;

        fetchedProducts.add(product);
      }
    }

    // Cache the results
    box.put(cacheKey, fetchedProducts);
    return fetchedProducts;
  } catch (e) {
    print('❌ Error fetching products: $e');
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
