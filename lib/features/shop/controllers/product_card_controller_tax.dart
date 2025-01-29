import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ProductCardControllerTax {
  Future<Map<String, dynamic>?> fetchProductData(int productIndex) async {
    try {
      final List<int> categoryIds = [598, 601, 292, 162, 18];
      const int productsPerCategory = 2;
      final List<Map<String, dynamic>> fetchedProducts = [];

      for (int categoryId in categoryIds) {
        final categoryApi =
            'https://www.alkirtas.com/api/products?display=[id,name,price,id_default_image,manufacturer_name,id_category_default,id_tax_rules_group]&filter[id_category_default]=[$categoryId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

        final response = await http.get(Uri.parse(categoryApi));
        if (response.statusCode == 200) {
          final categoryData = json.decode(utf8.decode(response.bodyBytes));
          final categoryProducts = categoryData['products'] as List<dynamic>;

          categoryProducts.shuffle(Random());
          final selectedProducts = categoryProducts.take(productsPerCategory).toList();

          fetchedProducts.addAll(selectedProducts.map((product) => product as Map<String, dynamic>));
          if (fetchedProducts.length >= 10) break;
        }
      }

      final product = fetchedProducts[productIndex % fetchedProducts.length];

      // Fetch discount data for the product
      final discount = await fetchDiscount(product['id']);
      if (discount != null) {
        product['discount'] = discount; // Attach discount to product data
      }

      return product;
    } catch (e) {
      print('Error fetching products: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(discountApi));
      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));
        final discounts = discountData['specific_prices'] as List<dynamic>;
        if (discounts.isNotEmpty) {
          return discounts.first as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error fetching discount: $e');
    }
    return null;
  }

  //fetch TTC price
  

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
