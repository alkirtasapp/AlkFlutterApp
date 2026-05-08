import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import '../data/controllers/product_enriched_service.dart';
import '../utils/logging/logger.dart';

class WatchedProduct {
  final String productId;
  final String productName;
  final String imageUrl;
  final double watchedPrice;
  final int taxRulesGroupId;
  final DateTime addedAt;

  WatchedProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.watchedPrice,
    required this.taxRulesGroupId,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'imageUrl': imageUrl,
        'watchedPrice': watchedPrice,
        'taxRulesGroupId': taxRulesGroupId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WatchedProduct.fromJson(Map<String, dynamic> json) => WatchedProduct(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        imageUrl: (json['imageUrl'] as String?) ?? '',
        watchedPrice: (json['watchedPrice'] as num).toDouble(),
        taxRulesGroupId: (json['taxRulesGroupId'] as int?) ?? 0,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class PriceAlertProvider extends ChangeNotifier {
  static const _boxName = 'priceAlertsBox';
  static const _hiveKey = 'alerts';

  // Set by NavigationMenu — called when a price drop notification is tapped
  static void Function(String productId)? onNotificationTap;

  List<WatchedProduct> _alerts = [];
  bool _isChecking = false;

  List<WatchedProduct> get alerts => List.unmodifiable(_alerts);
  bool get isChecking => _isChecking;
  int get count => _alerts.length;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initNotifications();
    await _loadFromHive();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      },
    );
  }

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_hiveKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw as String);
        _alerts = decoded
            .map((e) => WatchedProduct.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      AlkLoggerHelper.error('Error loading price alerts', e);
      _alerts = [];
    }
    notifyListeners();
  }

  Future<void> _saveToHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_hiveKey, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
    } catch (e) {
      AlkLoggerHelper.error('Error saving price alerts', e);
    }
  }

  bool isWatched(String productId) =>
      _alerts.any((a) => a.productId == productId);

  Future<void> addAlert({
    required String productId,
    required String productName,
    required String imageUrl,
    required double effectivePrice,
    required int taxRulesGroupId,
  }) async {
    if (isWatched(productId)) return;
    _alerts.add(WatchedProduct(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      watchedPrice: effectivePrice,
      taxRulesGroupId: taxRulesGroupId,
      addedAt: DateTime.now(),
    ));
    await _saveToHive();
    notifyListeners();
  }

  Future<void> removeAlert(String productId) async {
    _alerts.removeWhere((a) => a.productId == productId);
    await _saveToHive();
    notifyListeners();
  }

  /// Called on every app open. Fetches current prices via enriched API
  /// and fires a local notification for any product that dropped in price.
  Future<void> checkPriceDrops() async {
    if (_alerts.isEmpty || _isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      final ids = _alerts
          .map((a) => int.tryParse(a.productId) ?? 0)
          .where((id) => id > 0)
          .toList();

      if (ids.isEmpty) {
        _isChecking = false;
        notifyListeners();
        return;
      }

      final enrichedMap = await ProductEnrichedService.fetchEnrichedByIds(ids);
      bool changed = false;

      for (int i = 0; i < _alerts.length; i++) {
        final alert = _alerts[i];
        final id = int.tryParse(alert.productId) ?? 0;
        final enriched = enrichedMap[id];
        if (enriched == null) continue;

        final newPrice = _calcEffectivePrice(enriched);

        // 0.01 tolerance to ignore floating-point noise
        if (newPrice < alert.watchedPrice - 0.01) {
          await _fireNotification(alert, newPrice);
          // Update stored price so the next open doesn't re-notify
          _alerts[i] = WatchedProduct(
            productId: alert.productId,
            productName: alert.productName,
            imageUrl: alert.imageUrl,
            watchedPrice: newPrice,
            taxRulesGroupId: alert.taxRulesGroupId,
            addedAt: alert.addedAt,
          );
          changed = true;
        }
      }

      if (changed) {
        await _saveToHive();
        notifyListeners();
      }
    } catch (e) {
      AlkLoggerHelper.error('Error checking price drops', e);
    }

    _isChecking = false;
    notifyListeners();
  }

  // Same formula used by product cards in the UI
  double _calcEffectivePrice(Map<String, dynamic> enriched) {
    final taxGroup = int.tryParse(enriched['id_tax_rules_group'].toString()) ?? 0;
    final basePrice = taxGroup == 0
        ? (double.tryParse(enriched['price_ht'].toString()) ?? 0.0)
        : (double.tryParse(enriched['price_ttc'].toString()) ?? 0.0);
    final hasDiscount =
        enriched['has_discount'] == 1 || enriched['has_discount'] == '1';
    final discount = hasDiscount
        ? (double.tryParse(enriched['discount_value'].toString()) ?? 0.0)
        : 0.0;
    return basePrice * (1 - discount / 100);
  }

  Future<void> _fireNotification(WatchedProduct alert, double newPrice) async {
    final oldStr = alert.watchedPrice.toStringAsFixed(2);
    final newStr = newPrice.toStringAsFixed(2);

    final androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Alertes Prix',
      channelDescription: 'Notifications de baisse de prix',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Nouveau prix : $newStr TND\nAncien prix : $oldStr TND',
        contentTitle: alert.productName,
        summaryText: 'Alerte prix',
      ),
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      alert.productId.hashCode,
      alert.productName,
      'Nouveau prix : $newStr TND  (avant : $oldStr TND)',
      details,
      payload: alert.productId,
    );

    AlkLoggerHelper.info(
        'Price drop: ${alert.productName} $oldStr → $newStr TND');
  }
}
