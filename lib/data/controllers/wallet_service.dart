import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Client for the PrestaShop `alkirtas_wallet_payment` module endpoints.
///
/// All three endpoints use ws_key + customer_id authentication when called from
/// the mobile app (no PrestaShop login session is available).
class WalletService {
  static const String _moduleBase =
      'https://www.alkirtas.com/module/alkirtas_wallet_payment';

  static String get _wsKey => AppConfig.prestashopApiKey;

  /// Get the customer's wallet balance.
  ///
  /// Returns null on failure. `notEligible` means the customer isn't whitelisted —
  /// in that case the UI should hide the wallet block entirely.
  static Future<WalletBalance?> getBalance() async {
    if (UserData.id.isEmpty) return null;

    try {
      final url = '$_moduleBase/balance'
          '?ws_key=$_wsKey'
          '&customer_id=${UserData.id}'
          '&email=${Uri.encodeComponent(UserData.email)}';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        AlkLoggerHelper.warning(
            'WalletService.getBalance HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['success'] != true) {
        final err = data is Map ? data['error']?.toString() : null;
        return WalletBalance(
          balance: 0,
          currency: 'TND',
          eligible: err != 'not_eligible',
          testMode: false,
        );
      }
      return WalletBalance(
        balance: (data['balance'] as num?)?.toDouble() ?? 0,
        currency: data['currency']?.toString() ?? 'TND',
        eligible: true,
        testMode: data['test_mode'] == true,
      );
    } catch (e) {
      AlkLoggerHelper.error('WalletService.getBalance error', e);
      return null;
    }
  }

  /// Apply [amount] of wallet credit to the PrestaShop cart [cartId].
  ///
  /// Creates a one-time voucher on the cart, reducing its total by [amount].
  /// On success returns the new cart total + the voucher amount.
  static Future<WalletApplyResult> applyToCart({
    required String cartId,
    required double amount,
  }) async {
    if (UserData.id.isEmpty) {
      return WalletApplyResult.failure('not_logged_in');
    }

    try {
      final url = '$_moduleBase/apply';
      final body = {
        'ws_key': _wsKey,
        'customer_id': UserData.id,
        'cart_id': cartId,
        'amount': amount.toString(),
        'email': UserData.email,
      };

      final response = await http
          .post(Uri.parse(url), body: body)
          .timeout(const Duration(seconds: 15));

      AlkLoggerHelper.debug('WalletService.apply -> ${response.statusCode}: '
          '${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map) {
        return WalletApplyResult.failure('bad_response');
      }
      if (data['success'] == true) {
        return WalletApplyResult.success(
          appliedAmount: (data['applied_amount'] as num?)?.toDouble() ?? amount,
          newCartTotal: (data['new_cart_total'] as num?)?.toDouble() ?? 0,
          voucherCode: data['voucher_code']?.toString() ?? '',
          cartRuleId: (data['cart_rule_id'] as num?)?.toInt() ?? 0,
        );
      }
      return WalletApplyResult.failure(
        data['error']?.toString() ?? 'unknown_error',
        extra: data is Map ? Map<String, dynamic>.from(data) : null,
      );
    } catch (e) {
      AlkLoggerHelper.error('WalletService.apply error', e);
      return WalletApplyResult.failure('network_error');
    }
  }

  /// Remove the wallet voucher from the cart (if any).
  static Future<bool> removeFromCart({required String cartId}) async {
    if (UserData.id.isEmpty) return false;

    try {
      final url = '$_moduleBase/remove';
      final body = {
        'ws_key': _wsKey,
        'customer_id': UserData.id,
        'cart_id': cartId,
        'email': UserData.email,
      };

      final response = await http
          .post(Uri.parse(url), body: body)
          .timeout(const Duration(seconds: 10));

      final data = json.decode(utf8.decode(response.bodyBytes));
      return data is Map && data['success'] == true;
    } catch (e) {
      AlkLoggerHelper.error('WalletService.remove error', e);
      return false;
    }
  }
}

class WalletBalance {
  final double balance;
  final String currency;
  final bool eligible;
  final bool testMode;

  WalletBalance({
    required this.balance,
    required this.currency,
    required this.eligible,
    required this.testMode,
  });
}

class WalletApplyResult {
  final bool success;
  final double appliedAmount;
  final double newCartTotal;
  final String voucherCode;
  final int cartRuleId;
  final String? error;
  final Map<String, dynamic>? extra;

  WalletApplyResult._({
    required this.success,
    this.appliedAmount = 0,
    this.newCartTotal = 0,
    this.voucherCode = '',
    this.cartRuleId = 0,
    this.error,
    this.extra,
  });

  factory WalletApplyResult.success({
    required double appliedAmount,
    required double newCartTotal,
    required String voucherCode,
    required int cartRuleId,
  }) =>
      WalletApplyResult._(
        success: true,
        appliedAmount: appliedAmount,
        newCartTotal: newCartTotal,
        voucherCode: voucherCode,
        cartRuleId: cartRuleId,
      );

  factory WalletApplyResult.failure(String error, {Map<String, dynamic>? extra}) =>
      WalletApplyResult._(success: false, error: error, extra: extra);
}
