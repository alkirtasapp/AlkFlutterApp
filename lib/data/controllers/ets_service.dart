import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// ETS rewards (the same balance as the loyalty card), like on alkirtas.com:
/// - "Achetez ce produit et gagnez X" on the product page (module alk_loyaltyhint);
/// - "Utiliser mes récompenses" at checkout (module alk_ets_odoo_bridge).
///
/// Spending needs a **ticket**: a signed proof of identity that alkirtas.com
/// hands out after checking the password (or the Google sign-in) itself
/// (module alk_ets_odoo_bridge). The shared app key alone can't spend anybody's money.
///
/// All calls are POST (Cloudflare blocks query-string URLs).
class EtsService {
  static const String _site = 'https://www.alkirtas.com/module';
  static const String _loginUrl = '$_site/alk_ets_odoo_bridge/applogin';
  static const String _rewardsUrl = '$_site/alk_loyaltyhint/rewards';
  static const String _appUrl = '$_site/alk_ets_odoo_bridge/app';
  static const String _ticketKey = 'ets_app_ticket';

  static String _ticket = '';

  // ─── Ticket ──────────────────────────────────────────────────────────────

  static Future<void> saveTicket(String ticket) async {
    _ticket = ticket;
    _rewardCache.clear();
    _cartMinCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ticketKey, ticket);
  }

  static Future<void> clearTicket() async {
    _ticket = '';
    _rewardCache.clear();
    _cartMinCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ticketKey);
  }

  /// The stored ticket; for an older classic-login session without one, asks
  /// for it once with the saved password. Empty = the customer must log in again.
  static Future<String> ensureTicket() async {
    if (UserData.id.isEmpty) return '';
    if (_ticket.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _ticket = prefs.getString(_ticketKey) ?? '';
    }
    if (_ticket.isEmpty && UserData.email.isNotEmpty && UserData.password.isNotEmpty) {
      await loginWithPassword(UserData.email, UserData.password);
    }
    return _ticket;
  }

  /// Password checked by alkirtas.com. Returns true when a ticket was stored.
  static Future<bool> loginWithPassword(String email, String password) async {
    try {
      final response = await http.post(Uri.parse(_loginUrl),
          body: {'email': email, 'password': password}).timeout(const Duration(seconds: 15));
      final data = _decode(response);
      if (response.statusCode == 200 && data?['success'] == true && data?['ticket'] != null) {
        await saveTicket(data!['ticket'].toString());
        return true;
      }
      AlkLoggerHelper.warning('EtsService.login HTTP ${response.statusCode}');
    } catch (e) {
      AlkLoggerHelper.error('EtsService.login error', e);
    }
    return false;
  }

  // ─── "Achetez ce produit et gagnez X" ────────────────────────────────────

  static final Map<String, double> _rewardCache = {};
  static final Map<String, double> _cartMinCache = {};
  static final Map<String, Completer<double>> _waiting = {};
  static Timer? _batchTimer;

  /// Reward for buying one [productId] (0 = no message). Calls made at the
  /// same time are grouped into one request.
  static Future<double> productReward(String productId) {
    if (productId.isEmpty) return Future.value(0);
    final cached = _rewardCache[productId];
    if (cached != null) return Future.value(cached);
    final pending = _waiting[productId];
    if (pending != null) return pending.future;
    final completer = Completer<double>();
    _waiting[productId] = completer;
    _batchTimer ??= Timer(const Duration(milliseconds: 120), _flushRewards);
    return completer.future;
  }

  /// Product alone under the ETS minimum: the cart total (products, without
  /// delivery) from which the reward is earned. 0 = none. Known once
  /// [productReward] has answered for this product.
  static double productCartMin(String productId) => _cartMinCache[productId] ?? 0;

  static Future<void> _flushRewards() async {
    _batchTimer = null;
    final batch = Map<String, Completer<double>>.from(_waiting);
    _waiting.clear();
    // With a ticket the site also hides the message from customers who can't earn.
    final ticket = await ensureTicket();
    final ids = batch.keys.toList();
    for (var i = 0; i < ids.length; i += 60) {
      final chunk = ids.sublist(i, i + 60 > ids.length ? ids.length : i + 60);
      Map<String, dynamic> rewards = {};
      Map<String, dynamic> cartMins = {};
      var ok = false;
      try {
        final response = await http.post(Uri.parse(_rewardsUrl), body: {
          'ids': chunk.join(','),
          'with_cart_min': '1',
          if (ticket.isNotEmpty) 'ticket': ticket,
        }).timeout(const Duration(seconds: 15));
        final data = _decode(response);
        if (data?['success'] == true && data?['rewards'] is Map) {
          rewards = Map<String, dynamic>.from(data!['rewards']);
          if (data['cart_min'] is Map) cartMins = Map<String, dynamic>.from(data['cart_min']);
          ok = true;
        }
      } catch (e) {
        AlkLoggerHelper.error('EtsService.productRewards error', e);
      }
      for (final id in chunk) {
        final value = _num(rewards[id]);
        if (ok) {
          _rewardCache[id] = value; // a failed call is retried next time
          _cartMinCache[id] = _num(cartMins[id]);
        }
        batch[id]!.complete(value);
      }
    }
  }

  // ─── "Utiliser mes récompenses" ──────────────────────────────────────────

  /// Balance, ETS limits and the vouchers converted earlier. null = box hidden
  /// (not logged in, no ticket, not in "Clients concernés", or site unreachable).
  static Future<EtsRewards?> getRewards() async {
    final data = await _callApp({'action': 'balance'}, const Duration(seconds: 10));
    if (data == null || data['success'] != true || data['visible'] != true) return null;
    final vouchers = (data['vouchers'] is List ? data['vouchers'] as List : const [])
        .whereType<Map>()
        .map((v) => EtsVoucher.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    return EtsRewards(
      balance: _num(data['balance']),
      min: _num(data['min']),
      max: _num(data['max']),
      combine: data['combine'] == true,
      vouchers: vouchers,
    );
  }

  /// Turns [amount] of the balance into a voucher (it waits in "Mes bons" until
  /// the order). [productsTotal] = products left to pay, without delivery.
  static Future<EtsResult> convert({
    required double amount,
    required double productsTotal,
    required bool hasCoupon,
  }) async {
    final data = await _callApp({
      'action': 'convert',
      'amount': amount.toStringAsFixed(3),
      'products_total': productsTotal.toStringAsFixed(3),
      'has_coupon': hasCoupon ? '1' : '0',
    }, const Duration(seconds: 25));
    if (data != null && data['success'] == true && data['voucher'] is Map) {
      return EtsResult.ok(EtsVoucher.fromJson(Map<String, dynamic>.from(data['voucher'])));
    }
    return EtsResult.failure(_message(data));
  }

  /// Puts the voucher in the PrestaShop cart, just before the order is created.
  static Future<EtsResult> attach({required String cartId, required int idCartRule}) async {
    final data = await _callApp({
      'action': 'attach',
      'cart_id': cartId,
      'id_cart_rule': '$idCartRule',
    }, const Duration(seconds: 15));
    return data?['success'] == true ? EtsResult.ok(null) : EtsResult.failure(_message(data));
  }

  /// Takes the voucher off an unused cart (order failed). It stays in "Mes bons".
  static Future<void> remove({required String cartId}) async {
    await _callApp({'action': 'remove', 'cart_id': cartId}, const Duration(seconds: 10));
  }

  static Future<Map<String, dynamic>?> _callApp(Map<String, String> body, Duration timeout) async {
    final ticket = await ensureTicket();
    if (ticket.isEmpty) return null;
    try {
      final response = await http
          .post(Uri.parse(_appUrl), body: {...body, 'ticket': ticket})
          .timeout(timeout);
      if (response.statusCode == 401) {
        await clearTicket();
        return null;
      }
      return _decode(response);
    } catch (e) {
      AlkLoggerHelper.error('EtsService.${body['action']} error', e);
      return null;
    }
  }

  static String _message(Map<String, dynamic>? data) {
    final error = (data?['error'] ?? '').toString();
    return error.isNotEmpty ? error : 'Erreur de connexion, réessayez.';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// alkirtas.com answers can start with a UTF-8 BOM, which jsonDecode rejects.
  static Map<String, dynamic>? _decode(http.Response response) {
    try {
      var text = utf8.decode(response.bodyBytes);
      if (text.startsWith('﻿')) text = text.substring(1);
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  /// Amounts like the website: 3 decimals, French comma ("1,250 TND").
  static String format(double v) => v.toStringAsFixed(3).replaceAll('.', ',');
}

class EtsRewards {
  final double balance;
  final double min;
  final double max; // ETS maximum per voucher, 0 = none
  final bool combine; // can be used together with a promo code
  final List<EtsVoucher> vouchers;

  EtsRewards({
    required this.balance,
    required this.min,
    required this.max,
    required this.combine,
    required this.vouchers,
  });
}

class EtsVoucher {
  final int idCartRule;
  final String code;
  final double amount;

  EtsVoucher({required this.idCartRule, required this.code, required this.amount});

  factory EtsVoucher.fromJson(Map<String, dynamic> json) => EtsVoucher(
        idCartRule: EtsService._num(json['id_cart_rule']).toInt(),
        code: (json['code'] ?? '').toString(),
        amount: EtsService._num(json['amount']),
      );
}

class EtsResult {
  final bool success;
  final EtsVoucher? voucher;
  final String error;

  EtsResult._(this.success, this.voucher, this.error);

  factory EtsResult.ok(EtsVoucher? voucher) => EtsResult._(true, voucher, '');
  factory EtsResult.failure(String error) => EtsResult._(false, null, error);
}
