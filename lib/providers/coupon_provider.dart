import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

part 'coupon_provider.g.dart';

@HiveType(typeId: 0)
class Coupon {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final double? reductionPercent;
  @HiveField(3)
  final double? reductionAmount;
  @HiveField(4)
  final String name;
  @HiveField(5)
  final DateTime expiryDate;

  Coupon({
    required this.id,
    required this.code,
    this.reductionPercent,
    this.reductionAmount,
    required this.name,
    required this.expiryDate,
  });

  get percentage => null;

  bool get isPercent => reductionPercent != null && reductionPercent! > 0;
  bool get isAmount => !isPercent && reductionAmount != null && reductionAmount! > 0;

  /// Short discount label, e.g. "-20%" or "-5 TND". Empty when the rule has
  /// no percent/amount reduction (free shipping, gift product...).
  String get discountLabel {
    if (isPercent) return '-${_trim(reductionPercent!)}%';
    if (isAmount) return '-${_trim(reductionAmount!)} TND';
    return '';
  }

  /// Discount this coupon gives on [subtotal], never more than the subtotal.
  double discountOn(double subtotal) {
    double d = 0;
    if (isPercent) {
      d = subtotal * (reductionPercent! / 100);
    } else if (isAmount) {
      d = reductionAmount!;
    }
    return d.clamp(0, subtotal < 0 ? 0 : subtotal).toDouble();
  }

  /// Calendar days left before expiry (0 = expires today).
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiryDay.difference(today).inHours ~/ 24;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

enum CouponAddResult { added, alreadyAdded, invalid, expired, networkError }

class CouponProvider extends ChangeNotifier {
  final List<Coupon> _coupons = [];
  Coupon? _selectedCoupon;
  static const String _boxName = 'couponsBox';

  CouponProvider() {
    _loadCoupons();
  }

  List<Coupon> get coupons => List.unmodifiable(_coupons);
  Coupon? get selectedCoupon => _selectedCoupon;

  Future<void> _loadCoupons() async {
    final box = await Hive.openBox<Coupon>(_boxName);
    final now = DateTime.now();
    // Remove expired coupons
    final validCoupons = box.values.where((c) => c.expiryDate.isAfter(now)).toList();
    _coupons.clear();
    _coupons.addAll(validCoupons);
    // Remove expired from box
    final keys = box.keys.toList();
    final values = box.values.toList();
    for (int i = 0; i < values.length; i++) {
      if (values[i].expiryDate.isBefore(now)) {
        await box.delete(keys[i]);
      }
    }
    notifyListeners();
  }

  Future<void> _saveCoupons() async {
    final box = await Hive.openBox<Coupon>(_boxName);
    await box.clear();
    for (var coupon in _coupons) {
      await box.add(coupon);
    }
  }

  Future<bool> addCoupon(String code) async {
    final result = await redeemCoupon(code);
    return result == CouponAddResult.added || result == CouponAddResult.alreadyAdded;
  }

  /// Same as [addCoupon] but tells the caller *why* it failed.
  Future<CouponAddResult> redeemCoupon(String code) async {
    final trimmed = code.trim();
    if (_coupons.any((c) => c.code.toUpperCase() == trimmed.toUpperCase())) {
      return CouponAddResult.alreadyAdded;
    }
    final url = 'https://www.alkirtas.com/api/cart_rules?display=full&limit=1&filter[code]=${Uri.encodeQueryComponent(trimmed)}&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        AlkLoggerHelper.error("Coupon API failed: ${response.statusCode}");
        return CouponAddResult.networkError;
      }
      final data = json.decode(response.body);
      if (data is! Map || data['cart_rules'] is! List || (data['cart_rules'] as List).isEmpty) {
        return CouponAddResult.invalid;
      }
      final rule = data['cart_rules'][0];
      DateTime expiry = DateTime.now().add(Duration(days: 30)); // Default 30 days
      if (rule['date_to'] != null && rule['date_to'].toString().isNotEmpty) {
        try {
          expiry = DateTime.parse(rule['date_to'].toString());
        } catch (_) {}
      }
      final coupon = Coupon(
        id: int.tryParse(rule['id'].toString()) ?? 0,
        code: (rule['code'] ?? trimmed).toString(),
        reductionPercent: double.tryParse((rule['reduction_percent'] ?? '0').toString()),
        reductionAmount: double.tryParse((rule['reduction_amount'] ?? '0').toString()),
        name: (rule['name'] ?? '').toString(),
        expiryDate: expiry,
      );
      if (_coupons.any((c) => c.code == coupon.code)) {
        return CouponAddResult.alreadyAdded;
      }
      if (!coupon.expiryDate.isAfter(DateTime.now())) {
        AlkLoggerHelper.warning("Coupon expired: ${coupon.code}");
        return CouponAddResult.expired;
      }
      _coupons.add(coupon);
      await _saveCoupons();
      notifyListeners();
      return CouponAddResult.added;
    } catch (e) {
      AlkLoggerHelper.error("Coupon API error: $e");
      return CouponAddResult.networkError;
    }
  }

  void selectCoupon(Coupon? coupon) {
    _selectedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon(Coupon coupon) async {
    _coupons.removeWhere((c) => c.code == coupon.code);
    if (_selectedCoupon?.code == coupon.code) {
      _selectedCoupon = null;
    }
    final box = await Hive.openBox<Coupon>(_boxName);
    final toDelete = box.values.where((c) => c.code == coupon.code).toList();
    for (var c in toDelete) {
      final key = box.keyAt(box.values.toList().indexOf(c));
      await box.delete(key);
    }
    notifyListeners();
  }

  void clearCoupons() async {
    _coupons.clear();
    _selectedCoupon = null;
    final box = await Hive.openBox<Coupon>(_boxName);
    await box.clear();
    notifyListeners();
  }
} 