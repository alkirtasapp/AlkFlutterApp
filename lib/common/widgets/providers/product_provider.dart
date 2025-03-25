import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final List<Map<String, String>> _cartItems = [];

  List<Map<String, String>> get cartItems => _cartItems;

  void addToCart({
    required String productId,
    required String productName,
    required String productBrand,
    required String productImage,
    required String productPrice,
    required String productDiscount,
    required String productBrandId,
    required String productOldPrice,
    required String productNewPrice,
    required String productStock,
    required String productDescription,
    required String productReference,
    required List<String> productImageList,
    required List<String>? productFeatures,
    required int quantity,
  }) {
    _cartItems.add({
      'productId': productId,
      'productName': productName,
      'productBrand': productBrand,
      'productImage': productImage,
      'productPrice': productPrice,
      'productDiscount': productDiscount,
      'productBrandId': productBrandId,
      'productOldPrice': productOldPrice,
      'productNewPrice': productNewPrice,
      'productStock': productStock,
      'productDescription': productDescription,
      'productReference': productReference,
      'productImageList': productImageList.join(','),
      'productFeatures': productFeatures?.join(',') ?? '',
      'productQuantity': quantity.toString(),
    });

    print("🛒 Product added to cart: $productName, Quantity: $quantity");
    print("🛒 Current cart items: $_cartItems");

    notifyListeners();
  }

  void removeFromCart(String productName) {
    _cartItems.removeWhere((item) => item['productName'] == productName);
    notifyListeners();
  }

  double get totalPrice {
    return _cartItems.fold(0, (sum, item) {
      final price = double.tryParse(item['productPrice'] ?? '0') ?? 0;
      final quantity = int.tryParse(item['productQuantity'] ?? '1') ?? 1;
      return sum + (price * quantity);
    });
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}