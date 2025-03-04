import 'dart:convert';
import 'package:http/http.dart' as http;

class AlkSearchController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
  final String baseUrl = 'https://www.alkirtas.com/api/search';

  Future<List<int>?> searchProducts(String query, {int offset = 0, int limit = 20}) async {
    try {
      final String searchApi = '$baseUrl?query=$query&language=1&display=full&output_format=JSON&ws_key=$apiKey&start=$offset&limit=$limit';

      print("📡 Searching products with query: $query, Offset: $offset, Limit: $limit");
      print("🔗 API Request URL: $searchApi");

      final response = await http.get(Uri.parse(searchApi));
      if (response.statusCode != 200) {
        print("❌ API Error: ${response.statusCode}");
        return null;
      }

      final searchData = json.decode(utf8.decode(response.bodyBytes));
      print("🔍 API Response Data: ${searchData}");

      if (searchData['products'] == null || searchData['products'].isEmpty) {
        print("⚠️ No products found for query: $query");
        return null;
      }

      final List<int> productIds = (searchData['products'] as List)
          .map((product) => int.parse(product['id'].toString()))
          .toList();

      print("✅ Found ${productIds.length} products for query: $query");
      return productIds;
    } catch (e) {
      print('❌ Error searching products: $e');
      return null;
    }
  }
}