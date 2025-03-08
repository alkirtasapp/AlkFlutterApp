import 'dart:convert';
import 'package:http/http.dart' as http;

class AlkSearchController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
  final String baseUrl = 'https://www.alkirtas.com/api/products';

  Future<List<int>?> searchProducts(String query, {int offset = 0, int limit = 100}) async {
    try {
      final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
      final Set<int> productIds = {};

      for (final word in words) {
        
        final String formattedQuery = '%[$word%]';

        final String searchApi = '$baseUrl?filter[name]=$formattedQuery&language=1'
            '&sort=[id_DESC]&filter[active]=1&display=full&output_format=JSON'
            '&ws_key=$apiKey&limit=$limit';

        print("📡 Searching products with query: $word, Offset: $offset, Limit: $limit");
        print("🔗 API Request URL: $searchApi");

        final response = await http.get(Uri.parse(searchApi));
        if (response.statusCode != 200) {
          print("❌ API Error: ${response.statusCode}");
          continue;
        }

        final searchData = json.decode(utf8.decode(response.bodyBytes));

        if (searchData == null || searchData is! Map<String, dynamic> || !searchData.containsKey('products')) {
          print("⚠️ No products found for query: $word or invalid response.");
          continue;
        }

        final ids = (searchData['products'] as List)
            .where((product) => product is Map<String, dynamic> && product.containsKey('id'))
            .map((product) => int.tryParse(product['id'].toString()) ?? -1)
            .where((id) => id != -1);

        productIds.addAll(ids);
      }

      print("✅ Found ${productIds.length} unique active products for query: $query");
      return productIds.toList();
    } catch (e) {
      print('❌ Error searching products: $e');
      return null;
    }
  }
}
