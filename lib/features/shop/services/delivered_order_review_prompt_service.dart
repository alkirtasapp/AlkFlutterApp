import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/features/shop/services/product_review_service.dart';
import 'package:alkirtas/features/shop/widgets/delivered_order_review_dialog.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveredOrderReviewPromptService {
  DeliveredOrderReviewPromptService._();

  static const String _deliveredOrderStateId = '5';

  /// In-store purchases younger than this are offered for review. If none is,
  /// only the most recent in-store purchase is offered.
  static const int _storeOrderReviewWindowDays = 30;
  static bool _isChecking = false;
  static bool _isSheetOpen = false;

  static Future<void> checkAndPrompt({
    required BuildContext context,
    required CartProvider cartProvider,
  }) async {
    if (_isChecking || _isSheetOpen || UserData.id.isEmpty) return;

    _isChecking = true;
    try {
      final orders = await cartProvider.fetchCustomerCarts();
      if (!context.mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (!context.mounted) return;

      // Local memory is lost on reinstall: the server holds what was already
      // reviewed or dismissed. Without it, don't risk asking again.
      await _sendPendingDismissals(prefs);
      final serverState = await ProductReviewService().fetchPromptState();
      if (serverState == null || !context.mounted) return;
      for (final productId in serverState.reviewedProductIds) {
        await prefs.setBool(_reviewedProductKey(productId), true);
      }
      for (final orderId in serverState.dismissedOrderIds) {
        await prefs.setBool(_dismissedKey(orderId), true);
      }
      await _uploadLocalOnlyDismissals(prefs, serverState.dismissedOrderIds);
      if (!context.mounted) return;

      final storeOrderIds = _reviewableStoreOrderIds(orders);
      final order = orders.cast<Map<String, dynamic>?>().firstWhere(
            (order) =>
                order != null && _shouldPrompt(order, prefs, storeOrderIds),
            orElse: () => null,
          );

      if (order == null) return;

      _isSheetOpen = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (_) => DeliveredOrderReviewDialog(
          order: order,
          reviewedProductIds: _reviewedProductIds(order, prefs),
        ),
      );

      // Submitted, closed or swiped away: this order is never offered again.
      await dismissOrder(order);
    } catch (e) {
      AlkLoggerHelper.warning('Delivered order review prompt skipped: $e');
    } finally {
      _isChecking = false;
      _isSheetOpen = false;
    }
  }

  /// Store orders eligible for a review prompt: those of the last
  /// [_storeOrderReviewWindowDays] days, or else only the most recent one.
  static Set<String> _reviewableStoreOrderIds(
    List<Map<String, dynamic>> orders,
  ) {
    final storeOrders = orders
        .where((order) => order['isStoreOrder'] == true)
        .map((order) => (
              id: order['orderId']?.toString() ?? '',
              date: DateTime.tryParse(order['paidAt']?.toString() ?? ''),
            ))
        .where((order) => order.id.isNotEmpty && order.date != null)
        .toList()
      ..sort((a, b) => b.date!.compareTo(a.date!));
    if (storeOrders.isEmpty) return {};

    final limit = DateTime.now()
        .subtract(const Duration(days: _storeOrderReviewWindowDays));
    final recent = storeOrders.where((order) => order.date!.isAfter(limit));
    return recent.isNotEmpty
        ? recent.map((order) => order.id).toSet()
        : {storeOrders.first.id};
  }

  static bool _shouldPrompt(
    Map<String, dynamic> order,
    SharedPreferences prefs,
    Set<String> reviewableStoreOrderIds,
  ) {
    if (order['isStoreOrder'] == true) {
      // Paid in store = already received
      if (!reviewableStoreOrderIds.contains(order['orderId']?.toString())) {
        return false;
      }
    } else {
      if (order['isWebsiteOrder'] != true) return false;
      if (order['orderStateId']?.toString() != _deliveredOrderStateId) {
        return false;
      }
    }

    final orderId = order['orderId']?.toString() ?? '';
    if (orderId.isEmpty) return false;

    final items = (order['items'] as List?) ?? const [];
    final hasUnreviewedProducts = items.any((item) {
      if (item is! Map) return false;
      final productId = item['productId']?.toString() ?? '';
      return isReviewableProductId(productId) &&
          prefs.getBool(_reviewedProductKey(productId)) != true;
    });
    if (!hasUnreviewedProducts) return false;

    // Older versions only snoozed a closed sheet: treat that as dismissed too.
    if (prefs.getString(_lastPromptKey(orderId))?.isNotEmpty == true) {
      return false;
    }

    return prefs.getBool(_dismissedKey(orderId)) != true;
  }

  static Set<String> _reviewedProductIds(
    Map<String, dynamic> order,
    SharedPreferences prefs,
  ) {
    final items = (order['items'] as List?) ?? const [];
    return items.whereType<Map>().map((item) {
      return item['productId']?.toString() ?? '';
    }).where((productId) {
      return productId.isNotEmpty &&
          prefs.getBool(_reviewedProductKey(productId)) == true;
    }).toSet();
  }

  /// Store items not found in PrestaShop come with product id 0: they have no
  /// product page and cannot be reviewed.
  static bool isReviewableProductId(String productId) =>
      productId.isNotEmpty && productId != '0';

  static Future<void> markProductReviewed(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewedProductKey(productId), true);
  }

  /// Remembers locally and on the server that [order] must not be offered
  /// again. If the server can't be reached, it is retried on the next check.
  static Future<void> dismissOrder(Map<String, dynamic> order) async {
    final orderId = order['orderId']?.toString() ?? '';
    if (orderId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingDismissalsKey) ?? [];
    if (prefs.getBool(_dismissedKey(orderId)) == true &&
        !pending.contains(orderId)) {
      return; // already saved on the server
    }

    await prefs.setBool(_dismissedKey(orderId), true);
    if (!pending.contains(orderId)) {
      await prefs.setStringList(_pendingDismissalsKey, [...pending, orderId]);
    }
    await _sendPendingDismissals(prefs);
  }

  static Future<void> _sendPendingDismissals(SharedPreferences prefs) async {
    final pending = prefs.getStringList(_pendingDismissalsKey) ?? [];
    if (pending.isEmpty) return;

    final service = ProductReviewService();
    final stillPending = <String>[];
    for (final orderId in pending) {
      if (!await service.dismissOrder(orderId)) stillPending.add(orderId);
    }
    await prefs.setStringList(_pendingDismissalsKey, stillPending);
  }

  /// Orders closed before dismissals were saved on the server (older app
  /// versions) are sent once, so a later reinstall doesn't bring them back.
  static Future<void> _uploadLocalOnlyDismissals(
    SharedPreferences prefs,
    Set<String> serverDismissed,
  ) async {
    final prefixes = [_lastPromptKey(''), _dismissedKey('')];
    final pending = prefs.getStringList(_pendingDismissalsKey) ?? [];
    final localOnly = <String>{};
    for (final key in prefs.getKeys()) {
      for (final prefix in prefixes) {
        if (!key.startsWith(prefix)) continue;
        final orderId = key.substring(prefix.length);
        if (orderId.isNotEmpty &&
            !serverDismissed.contains(orderId) &&
            !pending.contains(orderId)) {
          localOnly.add(orderId);
        }
      }
    }
    if (localOnly.isEmpty) return;

    await prefs.setStringList(_pendingDismissalsKey, [...pending, ...localOnly]);
    await _sendPendingDismissals(prefs);
  }

  static String get _pendingDismissalsKey =>
      'review_prompt_pending_dismiss_${UserData.id}';

  static String _lastPromptKey(String orderId) =>
      'review_prompt_last_${UserData.id}_$orderId';

  static String _dismissedKey(String orderId) =>
      'review_prompt_dismissed_${UserData.id}_$orderId';

  static String _reviewedProductKey(String productId) =>
      'review_product_${UserData.id}_$productId';
}
