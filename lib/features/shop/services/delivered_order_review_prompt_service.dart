import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
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

      await prefs.setString(
        _lastPromptKey(order),
        DateTime.now().toIso8601String(),
      );
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

    if (prefs.getBool(_dismissedKey(order)) == true) return false;

    final lastPrompt = prefs.getString(_lastPromptKey(order));
    if (lastPrompt == null || lastPrompt.isEmpty) return true;

    final lastPromptDate = DateTime.tryParse(lastPrompt);
    if (lastPromptDate == null) return true;

    return DateTime.now().difference(lastPromptDate).inDays >= 3;
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

  static Future<void> dismissOrder(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey(order), true);
  }

  static String _lastPromptKey(Map<String, dynamic> order) =>
      'review_prompt_last_${UserData.id}_${order['orderId']}';

  static String _dismissedKey(Map<String, dynamic> order) =>
      'review_prompt_dismissed_${UserData.id}_${order['orderId']}';

  static String _reviewedProductKey(String productId) =>
      'review_product_${UserData.id}_$productId';
}
