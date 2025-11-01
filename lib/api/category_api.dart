import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class CategoryApi {
  static const String _boxName = 'categoryBox';
  static const String _key = 'homeCategories';

  /// Fetches home categories from the server's categories.json file
  /// Returns cached data if network fails
  static Future<List<Map<String, dynamic>>> fetchHomeCategories() async {
    // Open the Hive box
    var box = await Hive.openBox(_boxName);

    try {
      final response = await http.get(
        Uri.parse('https://alkirtas.com/banners/categories.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final categories = data.map((item) => Map<String, dynamic>.from(item)).toList();

        // Cache the result
        await box.put(_key, categories);
        return categories;
      } else {
        // If network fails, try to return cached data
        final cached = box.get(_key);
        if (cached != null) {
          return List<Map<String, dynamic>>.from(cached);
        }
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      // On error, return cached data if available
      final cached = box.get(_key);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Clears the cached categories
  static Future<void> clearCache() async {
    var box = await Hive.openBox(_boxName);
    await box.delete(_key);
  }
}
