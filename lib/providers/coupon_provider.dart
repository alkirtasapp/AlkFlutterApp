import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';

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
}

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
    print('[CouponProvider] Attempting to add coupon: $code');
    final url = 'https://www.alkirtas.com/api/cart_rules?display=full&limit=1&filter[code]=$code&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
    print('[CouponProvider] API URL: $url');
    final response = await http.get(Uri.parse(url));
    print('[CouponProvider] API Response status:  [38;5;2m${response.statusCode} [0m');
    print('[CouponProvider] API Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['cart_rules'] != null && data['cart_rules'].isNotEmpty) {
        final rule = data['cart_rules'][0];
        DateTime expiry = DateTime.now().add(Duration(days: 30)); // Default 30 days
        if (rule['date_to'] != null && rule['date_to'].toString().isNotEmpty) {
          try {
            expiry = DateTime.parse(rule['date_to']);
          } catch (_) {}
        }
        final coupon = Coupon(
          id: int.tryParse(rule['id'].toString()) ?? 0,
          code: rule['code'],
          reductionPercent: double.tryParse(rule['reduction_percent'] ?? '0'),
          reductionAmount: double.tryParse(rule['reduction_amount'] ?? '0'),
          name: rule['name'] ?? '',
          expiryDate: expiry,
        );
        if (!_coupons.any((c) => c.code == coupon.code)) {
          if (coupon.expiryDate.isAfter(DateTime.now())) {
            _coupons.add(coupon);
            await _saveCoupons();
            print('[CouponProvider] Coupon added: ${coupon.code}');
            notifyListeners();
            return true;
          } else {
            print('[CouponProvider] Coupon expired: ${coupon.code}');
            return false;
          }
        } else {
          print('[CouponProvider] Coupon already exists: ${coupon.code}');
        }
        return true;
      } else {
        print('[CouponProvider] No valid cart_rules found for code: $code');
      }
    } else {
      print('[CouponProvider] API call failed with status: ${response.statusCode}');
    }
    return false;
  }

  void selectCoupon(Coupon? coupon) {
    _selectedCoupon = coupon;
    print('[CouponProvider] Coupon selected: ${coupon?.code}');
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
    print('[CouponProvider] Coupon removed: ${coupon.code}');
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