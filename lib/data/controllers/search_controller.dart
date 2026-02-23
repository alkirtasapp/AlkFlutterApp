import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';

class AlkSearchController {
  String get apiKey => AppConfig.prestashopApiKey;
  static const String _enrichedBaseUrl =
      'https://www.alkirtas.com/module/productenriched/api';

  /// Search products using the enriched API with word splitting.
  /// Each word in the query is matched independently against product name AND reference.
  /// Returns a list of matching product IDs.
  Future<List<int>?> searchProducts(String query, {int offset = 0, int limit = 100}) async {
    try {
      final String cleanedQuery = query.trim();
      if (cleanedQuery.isEmpty) return [];

      final String encodedQuery = Uri.encodeComponent(cleanedQuery);
      final String searchApi =
          '$_enrichedBaseUrl?action=searchProducts&query=$encodedQuery'
          '&limit=$limit&offset=$offset&ws_key=$apiKey';

      print("📡 Searching products (enriched): $cleanedQuery, Offset: $offset, Limit: $limit");

      final response = await http.get(Uri.parse(searchApi));
      if (response.statusCode != 200) {
        print("❌ Enriched search API Error: ${response.statusCode}");
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data == null ||
          data is! Map<String, dynamic> ||
          data['success'] != true ||
          data['data'] == null) {
        print("⚠️ No results for query: $cleanedQuery");
        return [];
      }

      final products = data['data']['products'] as List<dynamic>? ?? [];

      final List<int> productIds = products
          .map((p) => int.tryParse(p['id_product'].toString()) ?? -1)
          .where((id) => id > 0)
          .toList();

      print("✅ Found ${productIds.length} products for query: $cleanedQuery "
          "(total: ${data['data']['total'] ?? '?'})");
      return productIds;
    } catch (e) {
      print('❌ Error searching products: $e');
      return null;
    }
  }
}
