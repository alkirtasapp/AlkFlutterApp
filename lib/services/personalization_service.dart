import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Talks to /module/mobile_cart_api/personalize: the customer's wishlist on
/// the server, product-view history and "Pour vous" recommendations.
/// Every call is a no-op when no customer is logged in.
class PersonalizationService {
  PersonalizationService._();

  static const String _url =
      'https://www.alkirtas.com/module/mobile_cart_api/personalize';
  static const Duration _timeout = Duration(seconds: 15);

  static bool get isLoggedIn => UserData.id.isNotEmpty;

  static Future<Map<String, dynamic>?> _post(
      String action, Map<String, dynamic> body) async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ws_key': AppConfig.prestashopApiKey,
              'customer_id': int.tryParse(UserData.id) ?? 0,
              'action': action,
              ...body,
            }),
          )
          .timeout(_timeout);
      final decoded = _decode(response);
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        return decoded;
      }
      AlkLoggerHelper.info('personalize $action: ${response.statusCode}');
    } catch (e) {
      AlkLoggerHelper.error('personalize $action failed', e);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _get(
      String action, Map<String, String> params) async {
    if (!isLoggedIn) return null;
    try {
      final uri = Uri.parse(_url).replace(queryParameters: {
        'action': action,
        'customer_id': UserData.id,
        'ws_key': AppConfig.prestashopApiKey,
        ...params,
      });
      final response = await http.get(uri).timeout(_timeout);
      final decoded = _decode(response);
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        return decoded;
      }
      AlkLoggerHelper.info('personalize $action: ${response.statusCode}');
    } catch (e) {
      AlkLoggerHelper.error('personalize $action failed', e);
    }
    return null;
  }

  /// alkirtas.com answers start with a UTF-8 BOM, which jsonDecode rejects.
  static dynamic _decode(http.Response response) {
    var text = utf8.decode(response.bodyBytes);
    if (text.startsWith('﻿')) text = text.substring(1);
    return jsonDecode(text);
  }

  static List<int> _ids(Map<String, dynamic>? data) =>
      ((data?['product_ids'] as List?) ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();

  /// Uploads the ids saved on this phone and returns the customer's full
  /// server wishlist (phone + other devices). Null when offline/logged out.
  static Future<List<int>?> mergeWishlist(List<int> localIds) async {
    final data = await _post('wishlist_merge', {'product_ids': localIds});
    return data == null ? null : _ids(data);
  }

  static Future<void> addToWishlist(String productId) =>
      _post('wishlist_add', {'product_id': int.tryParse(productId) ?? 0});

  static Future<void> removeFromWishlist(String productId) =>
      _post('wishlist_remove', {'product_id': int.tryParse(productId) ?? 0});

  static Future<void> logProductView(String productId) =>
      _post('view', {'product_id': int.tryParse(productId) ?? 0});

  static Future<void> logProductTime(String productId, int seconds) =>
      _post('time', {
        'product_id': int.tryParse(productId) ?? 0,
        'seconds': seconds,
      });

  /// Product ids picked for the logged-in customer, best first.
  static Future<List<int>> recommendations({int limit = 12}) async =>
      _ids(await _get('recommendations', {'limit': '$limit'}));
}
