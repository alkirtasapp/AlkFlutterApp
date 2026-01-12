import 'package:flutter_test/flutter_test.dart';
import 'package:alkirtas/services/url_parser_service.dart';

void main() {
  group('UrlParserService', () {

    // ===== CATEGORY URL TESTS =====

    test('parses category URL correctly', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'https://www.alkirtas.com/627-voitures'
      );

      expect(result, isNotNull);
      expect(result!['type'], 'category');
      expect(result['id'], 627);
    });

    test('parses category URL without www', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'https://alkirtas.com/13-livres-arabes'
      );

      expect(result, isNotNull);
      expect(result!['type'], 'category');
      expect(result['id'], 13);
    });

    test('parses category URL without https', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'alkirtas.com/100-school-supplies'
      );

      expect(result, isNotNull);
      expect(result!['type'], 'category');
      expect(result['id'], 100);
    });

    // ===== PRODUCT URL TESTS =====

    test('parses product URL correctly', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'https://www.alkirtas.com/77075-voiture-telecommandee.html'
      );

      expect(result, isNotNull);
      expect(result!['type'], 'product');
      expect(result['id'], 77075);
    });

    test('parses product URL with long name', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'https://alkirtas.com/12345-this-is-a-very-long-product-name-here.html'
      );

      expect(result, isNotNull);
      expect(result!['type'], 'product');
      expect(result['id'], 12345);
    });

    // ===== INVALID URL TESTS =====

    test('returns null for invalid URL', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'https://google.com/search'
      );

      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = UrlParserService.parseAlkirtasUrl('');

      expect(result, isNull);
    });

    test('returns null for malformed URL', () {
      final result = UrlParserService.parseAlkirtasUrl(
        'not-a-valid-url'
      );

      expect(result, isNull);
    });

    // ===== HELPER METHOD TESTS =====

    test('isAlkirtasUrl returns true for valid domain', () {
      expect(
        UrlParserService.isAlkirtasUrl('https://alkirtas.com/123-test'),
        isTrue,
      );
    });

    test('isAlkirtasUrl returns false for other domains', () {
      expect(
        UrlParserService.isAlkirtasUrl('https://amazon.com/product'),
        isFalse,
      );
    });
  });
}
