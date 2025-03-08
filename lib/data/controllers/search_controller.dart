import 'dart:convert';
import 'package:http/http.dart' as http;

class AlkSearchController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
  final String baseUrl = 'https://www.alkirtas.com/api/products';

  Future<List<int>?> searchProducts(String query, {int offset = 0, int limit = 100}) async {
    try {
      final String cleanedQuery = query.trim();

      // ✅ Keep the entire phrase together instead of splitting into separate words
      final String formattedQuery = "%[$cleanedQuery]%";

      final String searchApi = '$baseUrl?filter[name]=$formattedQuery&language=1'
          '&sort=[id_DESC]&filter[active]=1&display=full&output_format=JSON'
          '&ws_key=$apiKey&limit=$limit';

      print("📡 Searching products with query: $cleanedQuery, Offset: $offset, Limit: $limit");
      print("🔗 API Request URL: $searchApi");

      final response = await http.get(Uri.parse(searchApi));
      if (response.statusCode != 200) {
        print("❌ API Error: ${response.statusCode}");
        return null;
      }

      final searchData = json.decode(utf8.decode(response.bodyBytes));

      if (searchData == null || searchData is! Map<String, dynamic> || !searchData.containsKey('products')) {
        print("⚠️ No products found for query: $cleanedQuery or invalid response.");
        return [];
      }

      final List<int> productIds = (searchData['products'] as List)
          .where((product) => product is Map<String, dynamic> && product.containsKey('id'))
          .map((product) => int.tryParse(product['id'].toString()) ?? -1)
          .where((id) => id != -1)
          .toList();

      print("✅ Found ${productIds.length} active products for query: $cleanedQuery");
      return productIds;
    } catch (e) {
      print('❌ Error searching products: $e');
      return null;
    }
  }
}
