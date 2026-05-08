import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/backendData/userData.dart';
import '../utils/logging/logger.dart';

class OdooAccountProvider extends ChangeNotifier {
  bool _isCreated = false;
  bool _isLoading = false;
  String? _error;

  bool get isCreated => _isCreated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Key is per-user so multiple accounts on the same device work correctly
  String get _prefKey => 'odoo_account_created_${UserData.id}';
  static const String _passwordKey = 'current_user_password';

  /// Load the "already created" flag and restore password into UserData if needed.
  Future<void> loadStatus() async {
    if (UserData.id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _isCreated = prefs.getBool(_prefKey) ?? false;

    // Restore plain-text password from storage if not already in memory
    if (UserData.password.isEmpty) {
      UserData.password = prefs.getString(_passwordKey) ?? '';
    }

    notifyListeners();
  }

  /// Persist password to SharedPreferences (called from login).
  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  /// Clear in-memory state on logout (SharedPreferences persists per-user flag).
  void clear() {
    _isCreated = false;
    _error = null;
    notifyListeners();
  }

  /// Create the Odoo portal account.
  /// [phone] is collected from the user via dialog.
  /// Uses [UserData.password] which must be set before calling.
  Future<bool> createOdooAccount({required String phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    const baseUrl = 'https://www.alkirtas.com/module/mobile_cart_api/loyalty';

    AlkLoggerHelper.info('[OdooAccount] GET $baseUrl?action=odooregister');
    AlkLoggerHelper.info('[OdooAccount] customer_id=${UserData.id}, phone=$phone, password_set=${UserData.password.isNotEmpty}');

    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'odooregister',
        'ws_key': AppConfig.prestashopApiKey,
        'customer_id': UserData.id,
        'phone': phone,
        'auth': UserData.password,
      });

      AlkLoggerHelper.info('[OdooAccount] Sending request...');

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      AlkLoggerHelper.info('[OdooAccount] HTTP ${response.statusCode} (GET)');
      AlkLoggerHelper.info('[OdooAccount] Response body: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (parseErr) {
        AlkLoggerHelper.error('[OdooAccount] JSON parse failed: $parseErr | raw: ${response.body}');
        _error = 'Réponse invalide du serveur (${response.statusCode})';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (data['success'] == true) {
        AlkLoggerHelper.info('[OdooAccount] Success! Account created.');
        _isCreated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKey, true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Treat HTTP 409 / already_exists as success: the user already has an
      // Odoo account, so the button has nothing more to do — hide it and let
      // the caller refresh loyalty data.
      final errBlock = data['error'];
      final errCode = (errBlock is Map) ? errBlock['code'] : null;
      final errMessage = (errBlock is Map) ? (errBlock['message']?.toString() ?? '') : (errBlock?.toString() ?? '');
      final isAlreadyExists = response.statusCode == 409 ||
          errCode == 409 ||
          errMessage.toLowerCase().contains('already') ||
          errMessage.toLowerCase().contains('existe déjà');

      if (isAlreadyExists) {
        AlkLoggerHelper.info('[OdooAccount] Account already exists — treating as success.');
        _isCreated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKey, true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = errMessage.isNotEmpty ? errMessage : 'Erreur inconnue';
      AlkLoggerHelper.error('[OdooAccount] Server error: $_error');

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stack) {
      AlkLoggerHelper.error('[OdooAccount] Exception: $e', stack);
      _error = 'Erreur: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
