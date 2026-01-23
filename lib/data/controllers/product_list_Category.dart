import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class ProductListCategory {
  Future<List<int>> fetchProductIdsFromCategory(int categoryId) async {
    try {
      final categoryApi =
          'https://www.alkirtas.com/api/categories?display=full&filter[id]=[$categoryId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(categoryApi));

      if (response.statusCode == 200) {
        final categoryData = json.decode(utf8.decode(response.bodyBytes));

        if (categoryData['categories'] == null ||
            categoryData['categories'].isEmpty) {
          AlkLoggerHelper.warning('No categories found for ID: $categoryId');
          return [];
        }

        final category = categoryData['categories'][0];

        if (category.containsKey('associations') &&
            category['associations'].containsKey('products')) {
          List<dynamic> productList = category['associations']['products'];

          List<int> productIds = productList
              .map((product) => int.parse(product['id'].toString()))
              .toList();
          productIds.sort((a, b) => b.compareTo(a)); // Sort by ID DESC

          return productIds;
        } else {
          AlkLoggerHelper.warning('No products associated with Category ID: $categoryId');
        }
      } else {
        AlkLoggerHelper.error('API Error: ${response.statusCode} while fetching Category $categoryId');
      }
    } catch (e) {
      AlkLoggerHelper.error('Error fetching product IDs for category $categoryId', e);
    }
    return [];
  }

}