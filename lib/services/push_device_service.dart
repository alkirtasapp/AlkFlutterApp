import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Links this phone to the logged-in customer on the server
/// (/module/alkirtas_push/device), so the back office can send a
/// notification to one customer instead of everyone. Removed on logout.
///
/// Every call is fire-and-forget and silently skipped when there is no
/// customer, no Firebase, or no network.
class PushDeviceService {
  PushDeviceService._();

  static const String _url = 'https://www.alkirtas.com/module/alkirtas_push/device';

  /// "customer|token" last sent, so one app session registers only once.
  static String? _registered;

  static Future<String?> _token() async {
    if (Firebase.apps.isEmpty) return null;
    try {
      return await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null; // iOS before the APNs token, offline, …
    }
  }

  static Future<bool> _post(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse(_url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'ws_key': AppConfig.prestashopApiKey, ...body}))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      AlkLoggerHelper.warning('Push device ${body['action']} failed: $e');
      return false;
    }
  }

  /// Call after login, on app start and when the FCM token changes.
  static Future<void> register({String? token}) async {
    final customerId = int.tryParse(UserData.id) ?? 0;
    if (customerId <= 0) return;
    token ??= await _token();
    if (token == null || token.isEmpty) return;
    final key = '$customerId|$token';
    if (_registered == key) return;
    final ok = await _post({
      'action': 'register',
      'customer_id': customerId,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
    if (ok) _registered = key;
  }

  /// Call on logout, before the customer id is cleared.
  static Future<void> unregister() async {
    final token = await _token();
    _registered = null;
    if (token == null || token.isEmpty) return;
    await _post({'action': 'unregister', 'token': token});
  }
}
