import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:alkirtas/models/home_section.dart';

class SectionsApi {
  static const String _boxName = 'sectionsBox';
  static const String _key = 'homeSections';

  /// Fetches home sections from the server's sections.json file
  /// Returns cached data if network fails
  static Future<List<HomeSection>> fetchHomeSections() async {
    // Open the Hive box
    var box = await Hive.openBox(_boxName);

    try {
      final response = await http.get(
        Uri.parse('https://alkirtas.com/banners/sections.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final sections = data
            .map((item) => HomeSection.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the result (convert to JSON for storage)
        final sectionsJson = data.map((item) => Map<String, dynamic>.from(item)).toList();
        await box.put(_key, sectionsJson);

        return sections;
      } else {
        // If network fails, try to return cached data
        final cached = box.get(_key);
        if (cached != null) {
          final List<dynamic> cachedData = cached as List<dynamic>;
          return cachedData
              .map((item) => HomeSection.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      // On error, return cached data if available
      final cached = box.get(_key);
      if (cached != null) {
        final List<dynamic> cachedData = cached as List<dynamic>;
        return cachedData
            .map((item) => HomeSection.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load sections: $e');
    }
  }

  /// Clears the cached sections
  static Future<void> clearCache() async {
    var box = await Hive.openBox(_boxName);
    await box.delete(_key);
  }
}
