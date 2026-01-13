import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/saved_cart_model.dart';
import 'product_controller_store.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/config/app_config.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, String>> _cartItems = [];
  static const String _cartBoxName = 'cartBox';
  static const String _cartKey = 'cartItems';
  static const String _savedCartsBoxName = 'savedCartsBox';
  Box? _cartBox;
  Box<SavedCart>? _savedCartsBox;

  // Background sync state
  Timer? _syncTimer;
  String? _syncSessionId;
  String? _syncOdooBaseUrl;
  String? _syncQrData;
  bool _isSyncing = false;
  bool _syncComplete = false;
  String _syncStatus = '';
  Function(bool success, String message)? _onSyncComplete;

  // Global key for showing snackbars from anywhere
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  List<Map<String, String>> get cartItems => _cartItems;
  bool get isSyncing => _isSyncing;
  bool get syncComplete => _syncComplete;
  String get syncStatus => _syncStatus;
  String? get activeSyncSessionId => _syncSessionId;

  /// Safe notify listeners - avoids calling during build
  void _safeNotifyListeners() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Show global notification when sync completes (works even if dialog is closed)
  void _showSyncCompleteNotification() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'Synchronisation Réussie',
        'Votre panier a été synchronisé avec succès!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    });
  }

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

  /// Save current cart to history with QR data and PrestaShop cart ID
  Future<SavedCart?> saveCartToHistory(String qrData, {String? prestashopCartId}) async {
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

      // Create saved cart object with PrestaShop cart ID for traceability
      final savedCart = SavedCart(
        id: cartId,
        savedDate: DateTime.now(),
        items: itemsCopy,
        totalAmount: cartTotal(),
        qrData: qrData,
        prestashopCartId: prestashopCartId,
      );

      // Save to Hive
      await _savedCartsBox!.put(cartId, savedCart);
      print('✅ Cart saved to history with ${_cartItems.length} items - Total: ${savedCart.totalAmount} - PrestashopCartId: $prestashopCartId');

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

  /// Find existing PrestaShop cart ID for current cart items
  /// This enables reusing the same cart_id when rescanning a cart
  /// to maintain traceability in Odoo
  String? findExistingPrestashopCartId() {
    try {
      if (_savedCartsBox == null || _cartItems.isEmpty) {
        return null;
      }

      // Get current cart product references for comparison
      final currentRefs = _cartItems
          .map((item) => item['productReference'] ?? '')
          .where((ref) => ref.isNotEmpty)
          .toSet();

      if (currentRefs.isEmpty) {
        return null;
      }

      // Search through saved carts for a matching one
      final savedCarts = _savedCartsBox!.values.toList();

      for (var savedCart in savedCarts) {
        if (savedCart.prestashopCartId == null) continue;

        // Get saved cart product references
        final savedRefs = savedCart.items
            .map((item) => item['productReference']?.toString() ?? '')
            .where((ref) => ref.isNotEmpty)
            .toSet();

        // Check if the cart items match (same products)
        if (currentRefs.length == savedRefs.length &&
            currentRefs.containsAll(savedRefs)) {
          print('🔗 Found existing PrestaShop cart ID: ${savedCart.prestashopCartId}');
          return savedCart.prestashopCartId;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding existing PrestaShop cart ID: $e');
      return null;
    }
  }

  // ==================== BACKGROUND SYNC METHODS ====================

  /// Start background polling for cart sync
  /// This will continue even if QR dialog is closed
  void startBackgroundSync({
    required String sessionId,
    required String odooBaseUrl,
    required String qrData,
    Function(bool success, String message)? onComplete,
  }) {
    // Stop any existing sync
    stopBackgroundSync();

    _syncSessionId = sessionId;
    _syncOdooBaseUrl = odooBaseUrl;
    _syncQrData = qrData;
    _syncComplete = false;
    _isSyncing = true;
    _syncStatus = 'En attente de vérification...';
    _onSyncComplete = onComplete;

    print('🔄 Starting background sync for session: $sessionId');

    // Start polling every 3 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollForVerifiedCart();
    });

    _safeNotifyListeners();
  }

  /// Stop background polling
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _syncSessionId = null;
    _isSyncing = false;
    print('🛑 Background sync stopped');
    _safeNotifyListeners();
  }

  /// Poll for verified cart data
  Future<void> _pollForVerifiedCart() async {
    if (_syncSessionId == null || _syncOdooBaseUrl == null || _syncComplete) {
      return;
    }

    try {
      // Use simplified route that works better with external IPs
      final url = '$_syncOdooBaseUrl/pos/mobile/sync/$_syncSessionId?db=alkirtas_backup';
      print('📡 Background polling: $url');

      // Create HTTP client with explicit connection timeout
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Accept'] = 'application/json';
        request.headers['Connection'] = 'keep-alive';

        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 10),
        );
        final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        // Cart verified! Parse and update
        final verifiedData = jsonDecode(response.body);
        print('✅ Background sync: Cart verified! Data: $verifiedData');

        // Stop polling
        _syncTimer?.cancel();
        _syncTimer = null;

        // Update cart from verified data (temporarily to get correct data for history)
        await _updateCartFromVerifiedData(verifiedData);

        // Auto-save to history with PrestaShop cart ID for traceability
        if (_syncQrData != null && _syncSessionId != null) {
          await saveCartToHistory(_syncQrData!, prestashopCartId: _syncSessionId);
          print('💾 Cart auto-saved to history with prestashopCartId: $_syncSessionId');
        }

        // Clear the current cart after successful sync
        await clearCart();
        print('🧹 Cart cleared after successful sync');

        _syncComplete = true;
        _isSyncing = false;
        _syncStatus = '✓ Panier synchronisé!';

        // Notify callback
        _onSyncComplete?.call(true, 'Panier synchronisé avec succès!');

        // Show global notification (works even if dialog is closed)
        _showSyncCompleteNotification();

        _safeNotifyListeners();

      } else if (response.statusCode == 404) {
        // Not ready yet, keep polling
        print('⏳ Background sync: Not ready yet...');
        _syncStatus = 'En attente du paiement...';
        _safeNotifyListeners();
      } else {
        print('⚠️ Unexpected status: ${response.statusCode}');
        print('   Body: ${response.body}');
      }
      } finally {
        client.close();
      }
    } catch (e) {
      print('⚠️ Background sync error: $e');
      _syncStatus = 'Erreur: ${e.toString().split(':').last.trim()}';
      _safeNotifyListeners();
      // Continue polling on error
    }
  }

  /// Update cart from verified data (background sync version)
  Future<void> _updateCartFromVerifiedData(Map<String, dynamic> verifiedData) async {
    try {
      final cartItems = verifiedData['cartItems'] as List?;

      if (cartItems == null || cartItems.isEmpty) {
        print('❌ No cart items in verified data');
        return;
      }

      print('📦 Updating cart with ${cartItems.length} verified items');

      // Save original items for reference
      final originalItems = List<Map<String, String>>.from(_cartItems);

      // Clear current cart
      _cartItems.clear();

      // PrestaShop controller for fetching new products
      final productController = ProductControllerStore();

      // Add verified items
      for (var item in cartItems) {
        final productRef = (item['productReference'] ?? '').toString();
        final verifiedQty = int.tryParse(item['productQuantity']?.toString() ?? '1') ?? 1;
        final price = (item['productPrice'] ?? '0').toString();
        final productName = item['productName']?.toString() ?? 'Product';

        if (verifiedQty <= 0) continue;

        // Find original item to get full product data
        final originalItem = originalItems.firstWhere(
          (cartItem) => cartItem['productReference'] == productRef,
          orElse: () => {},
        );

        if (originalItem.isNotEmpty) {
          // Use original data with updated quantity and price
          _cartItems.add({
            ...originalItem,
            'productPrice': price,
            'productQuantity': verifiedQty.toString(),
          });
        } else {
          // New product from Odoo - fetch full details from PrestaShop
          print('🔍 Fetching new product from PrestaShop: $productRef');

          Map<String, dynamic>? prestashopProduct;
          if (productRef.isNotEmpty) {
            prestashopProduct = await productController.searchProductByReference(productRef);
          }

          if (prestashopProduct != null) {
            // Use PrestaShop data for full product details
            final name = prestashopProduct['name'];
            final productNameStr = name is Map ? (name['language']?['value'] ?? name.toString()) : (name?.toString() ?? productName);

            final description = prestashopProduct['description_short'];
            final descriptionStr = description is Map ? (description['language']?['value'] ?? '') : (description?.toString() ?? '');

            final imageUrls = prestashopProduct['image_urls'] as List? ?? [];

            _cartItems.add({
              'productId': prestashopProduct['id']?.toString() ?? productRef,
              'productName': productNameStr,
              'productPrice': price, // Use Odoo price
              'productQuantity': verifiedQty.toString(),
              'productReference': productRef,
              'productBrand': prestashopProduct['brand']?.toString() ?? '',
              'productDiscount': prestashopProduct['discount']?.toString() ?? '',
              'productOldPrice': prestashopProduct['price']?.toString() ?? '',
              'productNewPrice': prestashopProduct['ttc_price']?.toString() ?? '',
              'productImage': imageUrls.isNotEmpty ? imageUrls[0] : '',
              'productStock': prestashopProduct['quantity']?.toString() ?? '',
              'productDescription': descriptionStr,
              'productBrandId': prestashopProduct['id_manufacturer']?.toString() ?? '',
              'productImageList': imageUrls.join(','),
              'productFeatures': '',
            });
            print('✅ Added product from PrestaShop: $productNameStr');
          } else {
            // Fallback: use basic Odoo data
            print('⚠️ Product not found in PrestaShop, using Odoo data: $productRef');
            _cartItems.add({
              'productId': item['productId']?.toString() ?? productRef,
              'productName': productName,
              'productPrice': price,
              'productQuantity': verifiedQty.toString(),
              'productReference': productRef,
              'productBrand': '',
              'productDiscount': '',
              'productOldPrice': '',
              'productNewPrice': '',
              'productImage': '',
              'productStock': '',
              'productDescription': '',
              'productBrandId': '',
              'productImageList': '',
              'productFeatures': '',
            });
          }
        }
      }

      await _saveCartToStorage();
      print('✅ Cart updated with ${_cartItems.length} items');
      _safeNotifyListeners();

    } catch (e) {
      print('❌ Error updating cart from verified data: $e');
    }
  }

  // ==================== PRESTASHOP CART CREATION ====================

  // ==================== PRESTASHOP CART FETCH ====================

  /// Fetch cart details from PrestaShop by cart ID
  /// This is used to get the latest cart state after it was modified by the cashier
  Future<Map<String, dynamic>?> fetchPrestaShopCart(String cartId) async {
    try {
      // Remove 'prestashop_' prefix if present
      String cleanCartId = cartId;
      if (cartId.startsWith('prestashop_')) {
        cleanCartId = cartId.substring('prestashop_'.length);
      }

      print('🔍 Fetching PrestaShop cart: $cleanCartId');

      final url = AppConfig.prestashopUrl('carts/$cleanCartId', params: {'display': 'full'});
      print('📡 URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('❌ Failed to fetch cart: ${response.statusCode}');
        return null;
      }

      // Use utf8.decode for proper Arabic/special character support
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      Map<String, dynamic>? cartData;

      if (data['cart'] != null) {
        cartData = data['cart'] as Map<String, dynamic>;
      } else if (data['carts'] != null && (data['carts'] as List).isNotEmpty) {
        cartData = (data['carts'] as List).first as Map<String, dynamic>;
      }

      if (cartData == null) {
        print('❌ No cart data found');
        return null;
      }

      print('✅ Cart fetched: ${cartData['id']}');

      // Get customer info from cart
      String customerName = '';
      String customerEmail = '';
      final customerId = cartData['id_customer']?.toString();
      if (customerId != null && customerId.isNotEmpty && customerId != '0') {
        print('👤 Fetching customer info for ID: $customerId');
        try {
          final customerUrl = AppConfig.prestashopUrl('customers/$customerId');
          final customerResponse = await http.get(Uri.parse(customerUrl));
          if (customerResponse.statusCode == 200) {
            // Use utf8.decode for proper Arabic/special character support
            final customerData = jsonDecode(utf8.decode(customerResponse.bodyBytes));
            Map<String, dynamic>? customer;
            if (customerData['customer'] != null) {
              customer = customerData['customer'] as Map<String, dynamic>;
            } else if (customerData['customers'] != null && (customerData['customers'] as List).isNotEmpty) {
              customer = (customerData['customers'] as List).first as Map<String, dynamic>;
            }
            if (customer != null) {
              final firstname = customer['firstname']?.toString() ?? '';
              final lastname = customer['lastname']?.toString() ?? '';
              customerName = '$firstname $lastname'.trim();
              customerEmail = customer['email']?.toString() ?? '';
              print('👤 Customer: $customerName ($customerEmail)');
            }
          }
        } catch (e) {
          print('⚠️ Error fetching customer: $e');
        }
      }

      // Get cart rows (products in the cart)
      List<dynamic> cartRows = [];
      if (cartData['associations'] != null &&
          cartData['associations']['cart_rows'] != null) {
        cartRows = cartData['associations']['cart_rows'] as List;
      }

      print('📦 Cart has ${cartRows.length} products');

      // Fetch product details for each cart row
      List<Map<String, dynamic>> items = [];
      final productController = ProductControllerStore();

      for (var row in cartRows) {
        final productId = row['id_product']?.toString() ?? '';
        final quantity = int.tryParse(row['quantity']?.toString() ?? '1') ?? 1;

        if (productId.isEmpty || quantity <= 0) continue;

        // Fetch product details from PrestaShop
        final productUrl = AppConfig.prestashopUrl('products/$productId', params: {'display': 'full'});
        try {
          final productResponse = await http.get(Uri.parse(productUrl));

          if (productResponse.statusCode == 200) {
            // Use utf8.decode for proper Arabic/special character support
            final productData = jsonDecode(utf8.decode(productResponse.bodyBytes));
            Map<String, dynamic>? product;

            if (productData['product'] != null) {
              product = productData['product'] as Map<String, dynamic>;
            } else if (productData['products'] != null && (productData['products'] as List).isNotEmpty) {
              product = (productData['products'] as List).first as Map<String, dynamic>;
            }

            if (product != null) {
              // Extract product name (handle language structure)
              String productName = 'Product';
              if (product['name'] is Map) {
                productName = product['name']['language']?['value']?.toString() ??
                              product['name'].toString();
              } else if (product['name'] is List && (product['name'] as List).isNotEmpty) {
                productName = (product['name'] as List).first['value']?.toString() ?? 'Product';
              } else {
                productName = product['name']?.toString() ?? 'Product';
              }

              // Get price
              final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;

              // Get product image
              String imageUrl = '';
              if (product['id_default_image'] != null) {
                final imageId = product['id_default_image'].toString();
                imageUrl = 'https://www.alkirtas.com/$imageId-large_default/${product['link_rewrite'] ?? 'product'}.jpg';
                // Alternative: use direct image API
                imageUrl = 'https://www.alkirtas.com/api/images/products/$productId/$imageId?ws_key=${AppConfig.prestashopApiKey}';
              }

              items.add({
                'productId': productId,
                'productName': productName,
                'productReference': product['reference']?.toString() ?? '',
                'productPrice': price.toString(),
                'productQuantity': quantity.toString(),
                'productImage': imageUrl,
                'productBrand': product['manufacturer_name']?.toString() ?? '',
                'productDiscount': '0',
              });

              print('  ✅ Product $productId: $productName x$quantity @ $price');
            }
          }
        } catch (e) {
          print('  ❌ Error fetching product $productId: $e');
        }
      }

      // Calculate total
      double total = 0;
      for (var item in items) {
        final price = double.tryParse(item['productPrice'] ?? '0') ?? 0;
        final qty = int.tryParse(item['productQuantity'] ?? '1') ?? 1;
        total += price * qty;
      }

      return {
        'cartId': cleanCartId,
        'items': items,
        'totalAmount': total,
        'itemCount': items.fold<int>(0, (sum, item) => sum + (int.tryParse(item['productQuantity'] ?? '1') ?? 1)),
        'customerName': customerName,
        'customerEmail': customerEmail,
      };
    } catch (e) {
      print('❌ Error fetching PrestaShop cart: $e');
      return null;
    }
  }

  // ==================== PRESTASHOP CART CREATION ====================

  /// Create a cart on PrestaShop after successful sync
  /// This records the verified purchase in PrestaShop
  Future<String?> createPrestaShopCart() async {
    try {
      // Check if user is logged in
      if (UserData.id.isEmpty) {
        print('⚠️ Cannot create PrestaShop cart: User not logged in');
        return null;
      }

      // Check if cart has items
      if (_cartItems.isEmpty) {
        print('⚠️ Cannot create PrestaShop cart: Cart is empty');
        return null;
      }

      print('🛒 Creating PrestaShop cart for user ${UserData.id}...');

      final String url = 'https://www.alkirtas.com/api/carts?ws_key=${AppConfig.prestashopApiKey}';

      // Build cart rows XML
      String cartRowsXml = _cartItems.map((item) {
        final productId = item['productId'] ?? '';
        final quantity = item['productQuantity'] ?? '1';
        final addressId = AddressData.id.isNotEmpty ? AddressData.id : '0';

        return '''
        <cart_row>
          <id_product><![CDATA[$productId]]></id_product>
          <id_product_attribute><![CDATA[]]></id_product_attribute>
          <id_address_delivery><![CDATA[$addressId]]></id_address_delivery>
          <id_customization><![CDATA[]]></id_customization>
          <quantity><![CDATA[$quantity]]></quantity>
        </cart_row>
        ''';
      }).join();

      // Build full XML body
      // IMPORTANT: id_shop and id_shop_group must be set to 1 for PrestaShop to properly recognize the cart
      String xmlBody = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <cart>
    <id_currency>1</id_currency>
    <id_lang>1</id_lang>
    <id_shop>1</id_shop>
    <id_shop_group>1</id_shop_group>
    <id_customer><![CDATA[${UserData.id}]]></id_customer>
    <associations>
      <cart_rows>
        $cartRowsXml
      </cart_rows>
    </associations>
  </cart>
</prestashop>''';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/xml',
          'Accept': 'application/xml',
        },
        body: xmlBody.trim(),
      );

      print('📡 PrestaShop response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse XML response to get cart ID
        final document = xml.XmlDocument.parse(response.body);
        final cartIdElement = document.findAllElements('id').first;
        final cartId = cartIdElement.text;

        print('✅ PrestaShop cart created successfully! ID: $cartId');
        return cartId;
      } else {
        print('❌ Failed to create PrestaShop cart: ${response.statusCode}');
        print('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating PrestaShop cart: $e');
      return null;
    }
  }
}

/// This is the provider for the cart screen
/// It contains the cart items and methods to add and remove items from the cart
/// It also contains a method to calculate the total price of the cart

