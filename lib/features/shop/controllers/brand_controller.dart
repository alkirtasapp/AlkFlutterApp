import 'dart:convert';
import 'package:http/http.dart' as http;

class BrandController {
  Future<Map<String, dynamic>?> fetchBrandData(int brandIndex) async {
    try {
      final List<int> brandIds = [5, 4, 1621, 910 , 34,48,1627,811];

      if (brandIndex >= brandIds.length) return null;

      final brandId = brandIds[brandIndex]; // Get specific brand ID

      final brandApi =
          'https://www.alkirtas.com/api/manufacturers?display=full&filter[id]=[$brandId]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

      final response = await http.get(Uri.parse(brandApi));

      if (response.statusCode == 200) {
        final brandData = json.decode(utf8.decode(response.bodyBytes));
        final manufacturers = brandData['manufacturers'] as List<dynamic>;

        if (manufacturers.isNotEmpty) {
          final manufacturer = manufacturers.first;
          final String brandImageUrl = 'https://www.alkirtas.com/img/m/${manufacturer['id']}.jpg';

          return {
            'id': manufacturer['id'].toString(),
            'name': manufacturer['name'] ?? 'Unknown',
            'logoUrl': brandImageUrl, // Include image URL
          };
        }
      }
    } catch (e) {
      print('Error fetching brands: $e');
    }
    return null;
  }
}
