import 'package:flutter/material.dart';
import 'package:test/features/shop/screens/product_details/product_details.dart';


class ProductProvider extends ChangeNotifier { // ✅ Use ChangeNotifier
  final List<Map<String, String>> _cartItems = [];

  List<Map<String, String>> get cartItems => _cartItems;

  void addToCart({
    required String productName,
    required String productBrand,
    required String productImage,
    required String productPrice,
    required String productDiscount,
    required String  productBrandId,
    required String  productOldPrice,
    required String  productNewPrice,
    required String  productStock,
    required String  productDescription,
    required String productReference,
     required List<String> productImageList,
     required List<String>? productFeatures,
  
  }) {
    _cartItems.add({
      'productName': productName,
      'productBrand': productBrand,
      'productImage': productImage,
      'productPrice': productPrice,
      'productDiscount' : productDiscount,
      'productBrandId' : productBrandId,
      'productOldPrice': productOldPrice,
      'productNewPrice': productNewPrice,
      'productStock': productStock,
      'productDescription': productDescription,
      'productReference': productReference,
      'productImageList': productImageList.join(','),
      'productFeatures' : productFeatures?.join(',') ?? '',
   

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
