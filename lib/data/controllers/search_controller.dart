import 'dart:convert';
import 'package:http/http.dart' as http;

class AlkSearchController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
  final String baseUrl = 'https://www.alkirtas.com/api/search';

  Future<List<Map<String, dynamic>>?> searchProducts(String query) async {
    try {
      final String searchApi = '$baseUrl?query=$query&language=1&display=full&output_format=JSON&ws_key=$apiKey';

      print("📡 Searching products with query: $query");

      final response = await http.get(Uri.parse(searchApi));
      if (response.statusCode != 200) {
        print("❌ API Error: ${response.statusCode}");
        return null;
      }

      final searchData = json.decode(utf8.decode(response.bodyBytes));
      if (searchData['products'] == null || searchData['products'].isEmpty) {
        print("⚠️ No products found for query: $query");
        return [];
      }

      List<Map<String, dynamic>> searchedProducts = [];

      for (var product in searchData['products']) {
        if (product is Map<String, dynamic>) {
          searchedProducts.add(product);
        }
      }

      return searchedProducts;
    } catch (e) {
      print('❌ Error searching products: $e');
      return null;
    }
  }
}