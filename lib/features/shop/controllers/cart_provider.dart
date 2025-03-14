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



/// This is the provider for the cart screen
/// It contains the cart items and methods to add and remove items from the cart
/// It also contains a method to calculate the total price of the cart

