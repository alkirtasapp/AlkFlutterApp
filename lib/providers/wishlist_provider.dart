import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import '../data/controllers/product_enriched_service.dart';
import '../utils/logging/logger.dart';

class WishlistItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double watchedPrice;
  final int taxRulesGroupId;
  final int lastKnownStock;
  final DateTime addedAt;

  WishlistItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.watchedPrice,
    required this.taxRulesGroupId,
    required this.lastKnownStock,
    required this.addedAt,
  });

  WishlistItem copyWith({
    double? watchedPrice,
    int? lastKnownStock,
  }) =>
      WishlistItem(
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        watchedPrice: watchedPrice ?? this.watchedPrice,
        taxRulesGroupId: taxRulesGroupId,
        lastKnownStock: lastKnownStock ?? this.lastKnownStock,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'imageUrl': imageUrl,
        'watchedPrice': watchedPrice,
        'taxRulesGroupId': taxRulesGroupId,
        'lastKnownStock': lastKnownStock,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        imageUrl: (json['imageUrl'] as String?) ?? '',
        watchedPrice: (json['watchedPrice'] as num).toDouble(),
        taxRulesGroupId: (json['taxRulesGroupId'] as int?) ?? 0,
        // Legacy entries (pre-stock-tracking) default to -1 = unknown.
        // First check after upgrade sets the baseline without firing.
        lastKnownStock: (json['lastKnownStock'] as int?) ?? -1,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class WishlistProvider extends ChangeNotifier {
  static const _boxName = 'priceAlertsBox';
  static const _hiveKey = 'alerts';

  // Set by NavigationMenu — called when a notification is tapped.
  static void Function(String productId)? onNotificationTap;

  List<WishlistItem> _items = [];
  bool _isChecking = false;

  List<WishlistItem> get items => List.unmodifiable(_items);
  // Backwards-compat alias for any existing callers that read `.alerts`.
  List<WishlistItem> get alerts => items;
  bool get isChecking => _isChecking;
  int get count => _items.length;

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
        _items = decoded
            .map((e) =>
                WishlistItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      AlkLoggerHelper.error('Error loading wishlist', e);
      _items = [];
    }
    notifyListeners();
  }

  Future<void> _saveToHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(
          _hiveKey, jsonEncode(_items.map((a) => a.toJson()).toList()));
    } catch (e) {
      AlkLoggerHelper.error('Error saving wishlist', e);
    }
  }

  bool isWatched(String productId) =>
      _items.any((a) => a.productId == productId);

  Future<void> addItem({
    required String productId,
    required String productName,
    required String imageUrl,
    required double effectivePrice,
    required int taxRulesGroupId,
    required int currentStock,
  }) async {
    if (isWatched(productId)) return;
    _items.add(WishlistItem(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      watchedPrice: effectivePrice,
      taxRulesGroupId: taxRulesGroupId,
      lastKnownStock: currentStock,
      addedAt: DateTime.now(),
    ));
    await _saveToHive();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((a) => a.productId == productId);
    await _saveToHive();
    notifyListeners();
  }

  /// Called on every app open. Fetches current prices + stock via enriched API
  /// and fires a local notification when either:
  ///   - price drops below the watched price, or
  ///   - stock comes back (was <= 0, now > 0).
  Future<void> checkUpdates() async {
    if (_items.isEmpty || _isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      final ids = _items
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

      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final id = int.tryParse(item.productId) ?? 0;
        final enriched = enrichedMap[id];
        if (enriched == null) continue;

        final newPrice = _calcEffectivePrice(enriched);
        final newStock = int.tryParse(enriched['quantity'].toString()) ?? 0;

        bool priceDropped = newPrice < item.watchedPrice - 0.01;
        // -1 = unknown baseline (legacy entries) — set without firing.
        bool stockCameBack =
            item.lastKnownStock != -1 && item.lastKnownStock <= 0 && newStock > 0;

        if (priceDropped) {
          await _firePriceNotification(item, newPrice);
        }
        if (stockCameBack) {
          await _fireStockNotification(item, newStock);
        }

        // Persist new values so we don't re-notify on next open.
        if (priceDropped ||
            newStock != item.lastKnownStock ||
            item.lastKnownStock == -1) {
          _items[i] = item.copyWith(
            watchedPrice: priceDropped ? newPrice : item.watchedPrice,
            lastKnownStock: newStock,
          );
          changed = true;
        }
      }

      if (changed) {
        await _saveToHive();
        notifyListeners();
      }
    } catch (e) {
      AlkLoggerHelper.error('Error checking wishlist updates', e);
    }

    _isChecking = false;
    notifyListeners();
  }

  double _calcEffectivePrice(Map<String, dynamic> enriched) {
    final taxGroup =
        int.tryParse(enriched['id_tax_rules_group'].toString()) ?? 0;
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

  Future<void> _firePriceNotification(
      WishlistItem item, double newPrice) async {
    final oldStr = item.watchedPrice.toStringAsFixed(2);
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
        contentTitle: item.productName,
        summaryText: 'Alerte prix',
      ),
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      item.productId.hashCode,
      item.productName,
      'Nouveau prix : $newStr TND  (avant : $oldStr TND)',
      details,
      payload: item.productId,
    );

    AlkLoggerHelper.info(
        'Price drop: ${item.productName} $oldStr → $newStr TND');
  }

  Future<void> _fireStockNotification(
      WishlistItem item, int newStock) async {
    final androidDetails = AndroidNotificationDetails(
      'stock_alerts',
      'Alertes Stock',
      channelDescription: 'Notifications de retour en stock',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Ce produit est à nouveau disponible.',
        contentTitle: item.productName,
        summaryText: 'Retour en stock',
      ),
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // +1 on hash so price + stock notifications for the same product
    // don't overwrite each other in the notification tray.
    await _notifications.show(
      item.productId.hashCode + 1,
      item.productName,
      'De retour en stock !',
      details,
      payload: item.productId,
    );

    AlkLoggerHelper.info(
        'Stock comeback: ${item.productName} (now $newStock available)');
  }
}
