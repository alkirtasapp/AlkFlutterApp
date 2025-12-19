import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';

class CategoriesStoreController {
  String get apiKey => AppConfig.prestashopApiKey;
  final String apiUrl =
      "https://www.alkirtas.com/api/categories?display=[id,id_parent,name,level_depth]&filter[active]=1&output_format=JSON&ws_key=";

  /// ✅ Store main categories dynamically (Level 2)
  Map<String, int> mainCategories = {};

  /// ✅ Store the full category tree (Levels 2, 3, and 4)
  Map<int, List<Map<String, dynamic>>> categoryTree = {};

  /// ✅ Hive caching box for category data
  final Box cacheBox = Hive.box('productCache');

  /// Fetch and process all categories from the API in one call
  Future<void> fetchAllCategories() async {
    const String cacheKey = "all_categories";

    // ✅ Check cache first
    if (cacheBox.containsKey(cacheKey)) {
      var cachedData = cacheBox.get(cacheKey);
      _processCategories(cachedData);
      _logInfo("⚡ Using cached categories.");
      return;
    }

    final url = "$apiUrl$apiKey";
    _logInfo("📡 Fetching all categories in one request...");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> categories = data['categories'] ?? [];

        // ✅ Process categories into a structured format
        _processCategories(categories);

        // ✅ Store in cache
        cacheBox.put(cacheKey, categories);
        _logSuccess("✅ Successfully loaded and cached all categories.");
      } else {
        _logError("❌ Failed to fetch categories. HTTP ${response.statusCode}");
      }
    } catch (e) {
      _logError("🔥 Exception while fetching categories: $e");
    }
  }


    
  /// Process the fetched categories and organize them into a tree
  void _processCategories(List<dynamic> categories) {
    mainCategories.clear();
    categoryTree.clear();

    // Define the desired order of categories with their corresponding names
    final orderedCategories = [
      "Livres",
      "Parascolaires",
      "Livres Scolaires",
      "Fournitures",
      "Papeterie",
      "Bagagerie",
      "Bureautique",
      "Art et Loisirs",
      "Jeux et jouets",
      "Cadeaux et fetes",
      "Déstockage" 
    ];

    // First, collect all level 2 categories in a temporary map
    Map<String, int> tempCategories = {};
    for (var category in categories) {
      int id = category['id'];
      int level = category['level_depth'];
      String name = category['name'];

      // Replace "PROMO 50%" with "Déstockage" if found
      if (name == "PROMO 50%") {
        name = "Déstockage";
      }

      if (level == 2) {
        tempCategories[name] = id;
      }

      // Build category tree regardless of order
      int parentId = category['id_parent'];
      if (!categoryTree.containsKey(parentId)) {
        categoryTree[parentId] = [];
      }
      categoryTree[parentId]!.add({"id": id, "name": name});
    }

    // Add categories in the specified order
    for (String categoryName in orderedCategories) {
      if (tempCategories.containsKey(categoryName)) {
        mainCategories[categoryName] = tempCategories[categoryName]!;
      }
    }

    // Add any remaining categories that weren't in the ordered list
    tempCategories.forEach((name, id) {
      if (!mainCategories.containsKey(name)) {
        mainCategories[name] = id;
      }
    });

    _logSuccess("✅ Processed ${categories.length} categories into a structured tree with custom ordering.");
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
