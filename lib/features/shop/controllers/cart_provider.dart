import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, String>> _cartItems = [];

  List<Map<String, String>> get cartItems => _cartItems;

  void addToCart({
    required String productId,
    required String productName,
    String? productBrand,
    required String productPrice,
    String? productDiscount,
    String? productOldPrice,
    String? productNewPrice,
    String? productImage,
    String? productReference,
    String? productStock,
    String? productDescription,
    String? productBrandId,
    List<String>? productImageList,
    List<String>? productFeatures,
    required int quantity,
  }) {
    // Check if the product already exists in the cart
    int existingIndex = _cartItems.indexWhere((item) => item['productId'] == productId);

    if (existingIndex != -1) {
      // If product exists, update its quantity
      int currentQuantity = int.parse(_cartItems[existingIndex]['productQuantity'] ?? '0');
      _cartItems[existingIndex]['productQuantity'] = (currentQuantity + quantity).toString();
    } else {
      // If product doesn't exist, add it as a new item
      _cartItems.add({
        'productId': productId,
        'productName': productName,
        'productBrand': productBrand ?? '',
        'productPrice': productPrice,
        'productDiscount': productDiscount ?? '',
        'productOldPrice': productOldPrice ?? '',
        'productNewPrice': productNewPrice ?? '',
        'productImage': productImage ?? '',
        'productReference': productReference ?? '',
        'productStock': productStock ?? '',
        'productDescription': productDescription ?? '',
        'productBrandId': productBrandId ?? '',
        'productImageList': productImageList?.join(',') ?? '',
        'productFeatures': productFeatures?.join(',') ?? '',
        'productQuantity': quantity.toString(),
      });
    }

    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear(); // Clear the cart items
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Remove an item from the cart
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['productId'] == productId);
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Calculate the total price of the products in the cart
  double cartTotal() {
    double total = 0.0;

    for (var item in _cartItems) {
      final price = double.tryParse(item['productPrice'] ?? '0') ?? 0.0;
      final quantity = int.tryParse(item['productQuantity'] ?? '1') ?? 1;

      total += price * quantity;
    }

    return total;
  }
}

/// This is the provider for the cart screen
/// It contains the cart items and methods to add and remove items from the cart
/// It also contains a method to calculate the total price of the cart

