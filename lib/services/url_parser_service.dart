import 'package:flutter/material.dart';

/// Service class for parsing URLs from QR codes to extract category and product IDs
class UrlParserService {
  /// Parse URL and extract category or product ID
  /// Returns a Map with 'type' (category/product) and 'id' (the extracted ID)
  static Map<String, dynamic>? parseAlkirtasUrl(String url) {
    try {
      debugPrint('🔍 QR Parser: Original URL: $url');

      // Normalize the URL
      String normalizedUrl = _normalizeUrl(url);
      debugPrint('🔍 QR Parser: Normalized URL: $normalizedUrl');

      // Check if it's a category URL
      final categoryResult = _extractCategoryId(normalizedUrl);
      if (categoryResult != null) {
        debugPrint('✅ QR Parser: Found category - ID: ${categoryResult['id']}');
        return categoryResult;
      }

      // Check if it's a product URL
      final productResult = _extractProductId(normalizedUrl);
      if (productResult != null) {
        debugPrint('✅ QR Parser: Found product - ID: ${productResult['id']}');
        return productResult;
      }

      // If no pattern matches, return null
      debugPrint('❌ QR Parser: No pattern matched for URL: $normalizedUrl');
      return null;
    } catch (e) {
      debugPrint('❌ QR Parser Error: $e');
      return null;
    }
  }

  /// Normalize URL by removing protocol and www if present
  static String _normalizeUrl(String url) {
    String normalized = url.trim();

    // Remove protocol if present
    if (normalized.startsWith('http://')) {
      normalized = normalized.substring(7);
    } else if (normalized.startsWith('https://')) {
      normalized = normalized.substring(8);
    }

    // Remove www if present
    if (normalized.startsWith('www.')) {
      normalized = normalized.substring(4);
    }

    return normalized;
  }

  /// Extract category ID from URL patterns like:
  /// - alkirtas.com/627-voitures
  /// - alkirtas.com/13-livres-arabes
  /// Category URLs don't have .html extension
  static Map<String, dynamic>? _extractCategoryId(String url) {
    // Pattern: alkirtas.com/{categoryId}-{categoryName}
    // Category URLs don't end with .html
    // Use negative lookahead to reject .html URLs
    final categoryPattern = RegExp(r'^alkirtas\.com/(\d+)-([^/]+?)(?<!\.html)/?$');
    final match = categoryPattern.firstMatch(url);

    if (match != null) {
      final id = int.parse(match.group(1)!);
      if (_isValidId(id)) {
        return {
          'type': 'category',
          'id': id,
        };
      }
    }

    return null;
  }

  /// Extract product ID from URL patterns like:
  /// - alkirtas.com/77075-voiture-télécommandée-off-road-réfbk24683-2468300000003.html
  /// - alkirtas.com/12345-product-name.html
  /// Product URLs always end with .html extension
  static Map<String, dynamic>? _extractProductId(String url) {
    // Pattern: alkirtas.com/{productId}-{productName}.html
    // Product URLs end with .html
    final productPattern = RegExp(r'^alkirtas\.com/(\d+)-[^/]+\.html$');
    final match = productPattern.firstMatch(url);

    if (match != null) {
      final id = int.parse(match.group(1)!);
      if (_isValidId(id)) {
        return {
          'type': 'product',
          'id': id,
        };
      }
    }

    return null;
  }

  /// Validate if the extracted ID is a reasonable number
  static bool _isValidId(int id) {
    // Assuming IDs are positive integers with reasonable upper limit
    return id > 0 && id < 999999;
  }

  /// Check if URL is from alkirtas.com domain
  static bool isAlkirtasUrl(String url) {
    final normalizedUrl = _normalizeUrl(url).toLowerCase();
    return normalizedUrl.startsWith('alkirtas.com');
  }

  /// Get user-friendly error message for invalid URLs
  static String getErrorMessage(String url) {
    if (!isAlkirtasUrl(url)) {
      return 'Ce QR code ne provient pas de Alkirtas';
    }

    final parsed = parseAlkirtasUrl(url);
    if (parsed == null) {
      return 'Format de QR code non reconnu';
    }

    return 'QR code invalide';
  }

  /// Extract clean URL for debugging purposes
  static String getCleanUrl(String url) {
    return _normalizeUrl(url);
  }
}