import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Service to fetch author data from the AuthorPages PrestaShop module.
class AuthorService {
  static const String _moduleBaseUrl = 'https://www.alkirtas.com/module/authorpages/api';

  /// Get author by exact name match
  /// Returns author data: {id_author, name, description, image_url, rewrite, url}
  static Future<Map<String, dynamic>?> getAuthorByName(String name) async {
    if (name.isEmpty) return null;

    try {
      final encodedName = Uri.encodeComponent(name);
      final url = '$_moduleBaseUrl?action=getAuthorByName&name=$encodedName&ws_key=${AppConfig.prestashopApiKey}';

      AlkLoggerHelper.debug('Fetching author by name: $name');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        AlkLoggerHelper.debug('Author not found: $name');
        return null;
      }

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Author API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data']?['author'] == null) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']['author']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching author by name', e);
      return null;
    }
  }

  /// Get author by ID
  static Future<Map<String, dynamic>?> getAuthorById(int authorId) async {
    if (authorId <= 0) return null;

    try {
      final url = '$_moduleBaseUrl?action=getAuthorById&id=$authorId&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Author API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data']?['author'] == null) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']['author']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching author by ID', e);
      return null;
    }
  }

  /// Get product IDs for an author
  /// Returns list of product IDs that belong to this author
  static Future<List<int>> getProductsByAuthor(String authorName) async {
    if (authorName.isEmpty) return [];

    try {
      final encodedName = Uri.encodeComponent(authorName);
      final url = '$_moduleBaseUrl?action=getProductsByAuthor&name=$encodedName&ws_key=${AppConfig.prestashopApiKey}';

      AlkLoggerHelper.debug('Fetching products for author: $authorName');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Author products API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        return [];
      }

      final productIds = data['data']['product_ids'] as List<dynamic>? ?? [];
      final count = data['data']['count'] ?? 0;

      AlkLoggerHelper.debug('Found $count products for author: $authorName');

      return productIds.map((id) => id as int).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error fetching products by author', e);
      return [];
    }
  }

  /// Search authors by partial name
  /// Returns list of matching authors
  static Future<List<Map<String, dynamic>>> searchAuthors(String query) async {
    if (query.length < 2) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_moduleBaseUrl?action=searchAuthors&query=$encodedQuery&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        return [];
      }

      final authors = data['data']['authors'] as List<dynamic>? ?? [];
      return authors.map((a) => Map<String, dynamic>.from(a)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error searching authors', e);
      return [];
    }
  }

  /// Get authors by starting letter
  static Future<List<Map<String, dynamic>>> getAuthorsByLetter(String letter) async {
    if (letter.isEmpty) return [];

    try {
      final encodedLetter = Uri.encodeComponent(letter);
      final url = '$_moduleBaseUrl?action=getAuthorsByLetter&letter=$encodedLetter&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        return [];
      }

      final authors = data['data']['authors'] as List<dynamic>? ?? [];
      return authors.map((a) => Map<String, dynamic>.from(a)).toList();
    } catch (e) {
      AlkLoggerHelper.error('Error fetching authors by letter', e);
      return [];
    }
  }

  /// Get all authors grouped by first letter
  /// Returns {letters: [...], authors_by_letter: {A: [...], B: [...]}}
  static Future<Map<String, dynamic>?> getAllAuthorsGrouped() async {
    try {
      final url = '$_moduleBaseUrl?action=getAllAuthorsGrouped&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['success'] != true || data['data'] == null) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']);
    } catch (e) {
      AlkLoggerHelper.error('Error fetching all authors grouped', e);
      return null;
    }
  }
}
