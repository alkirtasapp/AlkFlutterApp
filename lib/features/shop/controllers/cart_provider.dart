import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
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

    notifyListeners(); // Notify widgets to rebuild
  }
}
