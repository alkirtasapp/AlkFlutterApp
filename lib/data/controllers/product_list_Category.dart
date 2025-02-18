import 'dart:convert';
import 'package:http/http.dart' as http;


class ProductListCategory {
  Future<List<int>> fetchProductIdsFromCategory(int categoryId) async {
  try {
    final categoryApi =
        'https://www.alkirtas.com/api/categories?display=full&filter[id]=[$categoryId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    print("📡 Fetching product IDs for Category ID: $categoryId");

    final response = await http.get(Uri.parse(categoryApi));

    if (response.statusCode == 200) {
      final categoryData = json.decode(utf8.decode(response.bodyBytes));

      if (categoryData['categories'] == null ||
          categoryData['categories'].isEmpty) {
        print("⚠️ No categories found for ID: $categoryId");
        return [];
      }

      final category = categoryData['categories'][0];

      if (category.containsKey('associations') &&
          category['associations'].containsKey('products')) {
        List<dynamic> productList = category['associations']['products'];

        List<int> productIds = productList
            .map((product) => int.parse(product['id'].toString()))
            .toList();
        productIds.sort((a, b) => b.compareTo(a)); //  Sort by ID DESC
         // ✅ Reverse the list correctly

        

        print("📦 Found ${productIds.length} products in category $categoryId");

        return productIds;
      } else {
        print("⚠️ No products associated with Category ID: $categoryId");
      }
    } else {
      print(
          "❌ API Error: ${response.statusCode} while fetching Category $categoryId");
    }
  } catch (e) {
    print("🔥 Error fetching product IDs: $e");
  }
  return [];
}

}