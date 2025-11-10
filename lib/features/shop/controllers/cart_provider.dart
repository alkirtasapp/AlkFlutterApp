import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/saved_cart_model.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, String>> _cartItems = [];
  static const String _cartBoxName = 'cartBox';
  static const String _cartKey = 'cartItems';
  static const String _savedCartsBoxName = 'savedCartsBox';
  Box? _cartBox;
  Box<SavedCart>? _savedCartsBox;

  List<Map<String, String>> get cartItems => _cartItems;

  /// Initialize the cart provider and load saved cart data
  Future<void> initialize() async {
    try {
      _cartBox = await Hive.openBox(_cartBoxName);
      _savedCartsBox = await Hive.openBox<SavedCart>(_savedCartsBoxName);
      await _loadCartFromStorage();
      print('✅ Cart initialized with ${_cartItems.length} items');
    } catch (e) {
      print('❌ Error initializing cart: $e');
    }
  }

  /// Load cart data from Hive storage
  Future<void> _loadCartFromStorage() async {
    try {
      if (_cartBox != null && _cartBox!.containsKey(_cartKey)) {
        final String? savedCartJson = _cartBox!.get(_cartKey);

        if (savedCartJson != null && savedCartJson.isNotEmpty) {
          final List<dynamic> decodedList = jsonDecode(savedCartJson);
          _cartItems.clear();

          for (var item in decodedList) {
            if (item is Map) {
              final Map<String, String> cartItem = {};
              item.forEach((key, value) {
                cartItem[key.toString()] = value.toString();
              });
              _cartItems.add(cartItem);
            }
          }
          print('📦 Loaded ${_cartItems.length} items from cart storage');
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error loading cart from storage: $e');
    }
  }

  /// Save cart data to Hive storage
  Future<void> _saveCartToStorage() async {
    try {
      if (_cartBox != null) {
        // Convert cart items to JSON string
        final String cartJson = jsonEncode(_cartItems);
        await _cartBox!.put(_cartKey, cartJson);
        print('💾 Cart saved to storage (${_cartItems.length} items)');
      }
    } catch (e) {
      print('❌ Error saving cart to storage: $e');
    }
  }

  Future<void> addToCart({
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
  }) async {
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

    await _saveCartToStorage(); // Save to storage after adding
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear(); // Clear the cart items
    await _saveCartToStorage(); // Save to storage after clearing
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Remove an item from the cart
  Future<void> removeFromCart(String productId) async {
    _cartItems.removeWhere((item) => item['productId'] == productId);
    await _saveCartToStorage(); // Save to storage after removing
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

  // ==================== CART HISTORY METHODS ====================

  /// Save current cart to history with QR data
  Future<SavedCart?> saveCartToHistory(String qrData) async {
    try {
      if (_cartItems.isEmpty) {
        print('⚠️ Cannot save empty cart to history');
        return null;
      }

      if (_savedCartsBox == null) {
        print('❌ Saved carts box not initialized');
        return null;
      }

      // Create a unique ID based on timestamp
      final String cartId = DateTime.now().millisecondsSinceEpoch.toString();

      // Convert cart items to dynamic maps for storage
      final List<Map<String, dynamic>> itemsCopy = _cartItems.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      // Create saved cart object
      final savedCart = SavedCart(
        id: cartId,
        savedDate: DateTime.now(),
        items: itemsCopy,
        totalAmount: cartTotal(),
        qrData: qrData,
      );

      // Save to Hive
      await _savedCartsBox!.put(cartId, savedCart);
      print('✅ Cart saved to history with ${_cartItems.length} items - Total: ${savedCart.totalAmount}');

      return savedCart;
    } catch (e) {
      print('❌ Error saving cart to history: $e');
      return null;
    }
  }

  /// Get all saved carts from history (sorted by date, newest first)
  List<SavedCart> getSavedCarts() {
    try {
      if (_savedCartsBox == null) {
        print('❌ Saved carts box not initialized');
        return [];
      }

      final carts = _savedCartsBox!.values.toList();
      // Sort by date, newest first
      carts.sort((a, b) => b.savedDate.compareTo(a.savedDate));
      return carts;
    } catch (e) {
      print('❌ Error getting saved carts: $e');
      return [];
    }
  }

  /// Load a saved cart and replace current cart
  Future<void> loadSavedCart(SavedCart savedCart) async {
    try {
      _cartItems.clear();

      // Convert saved items back to Map<String, String>
      for (var item in savedCart.items) {
        final Map<String, String> cartItem = {};
        item.forEach((key, value) {
          cartItem[key] = value.toString();
        });
        _cartItems.add(cartItem);
      }

      await _saveCartToStorage();
      notifyListeners();
      print('✅ Loaded saved cart with ${_cartItems.length} items');
    } catch (e) {
      print('❌ Error loading saved cart: $e');
    }
  }

  /// Delete a saved cart from history
  Future<void> deleteSavedCart(String cartId) async {
    try {
      if (_savedCartsBox == null) {
        print('❌ Saved carts box not initialized');
        return;
      }

      await _savedCartsBox!.delete(cartId);
      notifyListeners();
      print('✅ Deleted saved cart: $cartId');
    } catch (e) {
      print('❌ Error deleting saved cart: $e');
    }
  }

  /// Clear all saved carts from history
  Future<void> clearCartHistory() async {
    try {
      if (_savedCartsBox == null) {
        print('❌ Saved carts box not initialized');
        return;
      }

      await _savedCartsBox!.clear();
      notifyListeners();
      print('✅ Cleared all saved carts from history');
    } catch (e) {
      print('❌ Error clearing cart history: $e');
    }
  }
}

/// This is the provider for the cart screen
/// It contains the cart items and methods to add and remove items from the cart
/// It also contains a method to calculate the total price of the cart

