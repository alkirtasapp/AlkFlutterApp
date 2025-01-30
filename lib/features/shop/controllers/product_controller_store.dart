import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ProductControllerStore {
  Future<List<Map<String, dynamic>>> fetchRandomProducts() async {
    try {
      final List<int> categoryIds = [10, 11, 12, 17, 486, 544, 588, 590];
      final List<Map<String, dynamic>> allProducts = [];
      
      for (int categoryId in categoryIds) {
        final categoryApi =
            'https://www.alkirtas.com/api/products?display=[id,name,price,id_default_image,manufacturer_name,id_category_default,id_tax_rules_group]&filter[id_category_default]=[$categoryId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

        final response = await http.get(Uri.parse(categoryApi));
        if (response.statusCode == 200) {
          final categoryData = json.decode(utf8.decode(response.bodyBytes));
          final categoryProducts = categoryData['products'] as List<dynamic>;
          
         allProducts.addAll(categoryProducts.map((product) {
            return {
              'id': int.tryParse(product['id'].toString()) ?? 0, // Ensure ID is an int
              'name': product['name'].toString(),
              'price': double.tryParse(product['price'].toString()) ?? 0.0,
              'id_default_image': int.tryParse(product['id_default_image'].toString()) ?? 0,
              'manufacturer_name': product['manufacturer_name']?.toString() ?? 'Unknown',
              'id_category_default': int.tryParse(product['id_category_default'].toString()) ?? 0,
              'id_tax_rules_group': int.tryParse(product['id_tax_rules_group'].toString()) ?? 0,
            };
          }));

        }
      }

      if (allProducts.isNotEmpty) {
        allProducts.shuffle(Random()); // Shuffle to get random products
        return allProducts.take(10).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching random products: $e');
      return [];
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
      final productTaxGroupApi =
          'https://www.alkirtas.com/api/products?display=[id_tax_rules_group]&filter[id]=[$productId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final productResponse = await http.get(Uri.parse(productTaxGroupApi));
      if (productResponse.statusCode != 200) return null;
      final productData = json.decode(utf8.decode(productResponse.bodyBytes));
      final int taxRulesGroupId = productData['products'][0]['id_tax_rules_group'];

      final taxRulesApi =
          'https://www.alkirtas.com/api/tax_rules?display=[id_tax,id_tax_rules_group]&filter[id_tax_rules_group]=[$taxRulesGroupId]&limit=1&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxRulesResponse = await http.get(Uri.parse(taxRulesApi));
      if (taxRulesResponse.statusCode != 200) return null;
      final taxRulesData = json.decode(utf8.decode(taxRulesResponse.bodyBytes));
      final int taxId = taxRulesData['tax_rules'][0]['id_tax'];

      final taxesApi =
          'https://www.alkirtas.com/api/taxes?display=[rate,id]&filter[id]=[$taxId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final taxesResponse = await http.get(Uri.parse(taxesApi));
      if (taxesResponse.statusCode != 200) return null;
      final taxesData = json.decode(utf8.decode(taxesResponse.bodyBytes));
      final double taxRate = double.parse(taxesData['taxes'][0]['rate']);

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
