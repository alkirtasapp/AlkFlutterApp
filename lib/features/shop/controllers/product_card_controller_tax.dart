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
          final selectedProducts =
              categoryProducts.take(productsPerCategory).toList();

          fetchedProducts.addAll(
              selectedProducts.map((product) => product as Map<String, dynamic>));
          if (fetchedProducts.length >= 10) break;
        }
      }

      final product = fetchedProducts[productIndex % fetchedProducts.length];

      // Fetch discount data for the product
      final discount = await fetchDiscount(product['id']);
      if (discount != null) {
        product['discount'] = discount; // Attach discount to product data
      }

      // Fetch and apply tax calculation
      final ttcPrice = await fetchTTCPrice(product['id'], product['price']);
      if (ttcPrice != null) {
        product['ttc_price'] = ttcPrice; // Attach calculated TTC price
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

  Future<double?> fetchTTCPrice(int productId, dynamic priceHT) async {
    try {
      // Step 1: Fetch id_tax_rules_group for the product
      final productTaxGroupApi =
          'https://www.alkirtas.com/api/products?display=[id_tax_rules_group]&filter[id]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final productResponse = await http.get(Uri.parse(productTaxGroupApi));
      if (productResponse.statusCode != 200) return null;
      final productData = json.decode(utf8.decode(productResponse.bodyBytes));
      final int taxRulesGroupId = productData['products'][0]['id_tax_rules_group'];

      // Step 2: Fetch id_tax from tax rules API
      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax,id_tax_rules_group]&filter[id_tax_rules_group]=[$taxRulesGroupId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) return null;
      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
      final int taxId = taxRulesData['tax_rules'][0]['id_tax'];

      // Step 3: Fetch tax rate from taxes API
      final taxesApi =
          'https://www.alkirtas.com/api/taxes?display=[rate,id]&filter[id]=[$taxId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxesResponse = await http.get(Uri.parse(taxesApi));
      if (taxesResponse.statusCode != 200) return null;
      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
      final double taxRate = double.parse(taxesData['taxes'][0]['rate']);

      // Step 4: Calculate TTC price
      double priceHTDouble = double.parse(priceHT.toString());
      double priceTTC = priceHTDouble * (1 + (taxRate / 100));

      return priceTTC;
    } catch (e) {
      print('Error fetching TTC price: $e');
      return null;
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
