import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier { // ✅ Use ChangeNotifier
  final List<Map<String, String>> _cartItems = [];

  List<Map<String, String>> get cartItems => _cartItems;

  void addToCart({
    required String productName,
    required String productBrand,
    required String productImage,
    required String productPrice,
  }) {
    _cartItems.add({
      'productName': productName,
      'productBrand': productBrand,
      'productImage': productImage,
      'productPrice': productPrice,
    });

    notifyListeners(); // ✅ Notify the UI to update
  }

  void removeFromCart(String productName) {
    _cartItems.removeWhere((item) => item['productName'] == productName);
    notifyListeners(); // ✅ Notify the UI to update
  }

  // ✅ Calculate Total Price
  double get totalPrice {
    return _cartItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item['productPrice'] ?? '0') ?? 0);
    });
  }
}
