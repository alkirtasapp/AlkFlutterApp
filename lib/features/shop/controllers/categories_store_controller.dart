import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CategoriesStoreController {
  final String apiKey = "Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
  final String apiUrl = "https://www.alkirtas.com/api/categories";

  /// ✅ Main categories dynamically fetched from the API
  Map<String, int> categoryMap = {};

  /// Store subcategories fetched from the API
  Map<int, List<Map<String, dynamic>>> subcategories = {};

  /// Fetch main categories dynamically from the API
  Future<void> fetchMainCategories() async {
    final url =
        "$apiUrl?display=[id,name]&filter[level_depth]=2&output_format=JSON&ws_key=$apiKey";

    _logInfo("📡 Fetching main categories...");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> categories = data['categories'] ?? [];

        categoryMap = {
          for (var cat in categories) cat["name"]: cat["id"] as int
        };

        _logSuccess("✅ Loaded ${categoryMap.length} main categories successfully.");
      } else {
        _logError("❌ Failed to fetch main categories. HTTP ${response.statusCode}");
      }
    } catch (e) {
      _logError("🔥 Exception while fetching main categories: $e");
    }
  }

  /// Fetch subcategories for all main categories after fetching main categories
  Future<void> fetchAllSubcategories() async {
    _logInfo("📡 Fetching subcategories for all main categories...");
    for (var categoryId in categoryMap.values) {
      await fetchSubcategories(categoryId);
    }
    _logSuccess("✅ Finished loading subcategories for all main categories.");
  }

  /// Fetch subcategories for a specific main category
  Future<void> fetchSubcategories(int categoryId) async {
    final url =
        "$apiUrl?display=[id,name]&filter[level_depth]=3&filter[id_parent]=$categoryId&output_format=JSON&ws_key=$apiKey";

    _logInfo("📡 Requesting subcategories for category ID: $categoryId...");
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> categories = data['categories'] ?? [];

        subcategories[categoryId] = categories
            .map((cat) => {"id": cat["id"], "name": cat["name"]})
            .toList();

        _logSuccess("✅ Loaded ${categories.length} subcategories for Category ID: $categoryId");
      } else {
        _logError("❌ Failed to fetch subcategories for Category ID: $categoryId. HTTP ${response.statusCode}");
      }
    } catch (e) {
      _logError("🔥 Exception while fetching subcategories for Category ID $categoryId: $e");
    }
  }

  /// Log info messages
  void _logInfo(String message) {
    debugPrint("[ℹ️ INFO] ${DateTime.now().toIso8601String()} - $message");
  }

  /// Log success messages
  void _logSuccess(String message) {
    debugPrint("[✅ SUCCESS] ${DateTime.now().toIso8601String()} - $message");
  }

  /// Log error messages
  void _logError(String message) {
    debugPrint("[❌ ERROR] ${DateTime.now().toIso8601String()} - $message");
  }
}
