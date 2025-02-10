import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier { // ✅ Use ChangeNotifier
  final List<Map<String, String>> _cartItems = [];

  List<Map<String, String>> get cartItems => _cartItems;

  void addToCart({
    required String productName,
    required String productBrand,
    required String productImage,
  }) {
    _cartItems.add({
      'productName': productName,
      'productBrand': productBrand,
      'productImage': productImage,
    });

    notifyListeners(); // ✅ Notify the UI to update
  }

  void removeFromCart(String productName) {
    _cartItems.removeWhere((item) => item['productName'] == productName);
    notifyListeners(); // ✅ Notify the UI to update
  }
}
