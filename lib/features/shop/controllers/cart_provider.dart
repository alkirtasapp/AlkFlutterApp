import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/saved_cart_model.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, String>> _cartItems = [];
  static const String _cartBoxName = 'cartBox';
  static const String _cartKey = 'cartItems';
  static const String _savedCartsBoxName = 'savedCartsBox';
  static const String _activeCartIdKey = 'activeCartId';  // Key to store active prestashop cart id
  Box? _cartBox;
  Box<SavedCart>? _savedCartsBox;

  // Global key for showing snackbars from anywhere
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  // Active PrestaShop cart ID (session_id) - used to match against paid orders
  String? _activeCartId;
  String? get activeCartId => _activeCartId;

  // Cache for order states (id -> name mapping)
  Map<String, String> _orderStatesCache = {};

  List<Map<String, String>> get cartItems => _cartItems;

  /// Initialize the cart provider and load saved cart data
  Future<void> initialize() async {
    try {
      _cartBox = await Hive.openBox(_cartBoxName);
      _savedCartsBox = await Hive.openBox<SavedCart>(_savedCartsBoxName);
      await _loadCartFromStorage();
      await _loadActiveCartId();
      AlkLoggerHelper.info('Cart initialized with ${_cartItems.length} items, activeCartId: $_activeCartId');
    } catch (e) {
      AlkLoggerHelper.error('Error initializing cart', e);
    }
  }

  /// Load the active cart ID from storage
  Future<void> _loadActiveCartId() async {
    try {
      if (_cartBox != null && _cartBox!.containsKey(_activeCartIdKey)) {
        _activeCartId = _cartBox!.get(_activeCartIdKey);
        AlkLoggerHelper.debug('Loaded active cart ID: $_activeCartId');
      }
    } catch (e) {
      AlkLoggerHelper.error('Error loading active cart ID', e);
    }
  }

  /// Save the active cart ID (PrestaShop cart ID used as session_id)
  Future<void> setActiveCartId(String? cartId) async {
    try {
      _activeCartId = cartId;
      if (_cartBox != null) {
        if (cartId != null) {
          await _cartBox!.put(_activeCartIdKey, cartId);
          AlkLoggerHelper.debug('Active cart ID saved: $cartId');
        } else {
          await _cartBox!.delete(_activeCartIdKey);
          AlkLoggerHelper.debug('Active cart ID cleared');
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Error saving active cart ID', e);
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
          AlkLoggerHelper.debug('Loaded ${_cartItems.length} items from cart storage');
          notifyListeners();
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Error loading cart from storage', e);
    }
  }

  /// Save cart data to Hive storage
  Future<void> _saveCartToStorage() async {
    try {
      if (_cartBox != null) {
        // Convert cart items to JSON string
        final String cartJson = jsonEncode(_cartItems);
        await _cartBox!.put(_cartKey, cartJson);
        AlkLoggerHelper.debug('Cart saved to storage (${_cartItems.length} items)');
      }
    } catch (e) {
      AlkLoggerHelper.error('Error saving cart to storage', e);
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
    await setActiveCartId(null); // Clear the active cart ID
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
        AlkLoggerHelper.warning('Cannot save empty cart to history');
        return null;
      }

      if (_savedCartsBox == null) {
        AlkLoggerHelper.error('Saved carts box not initialized');
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
      AlkLoggerHelper.info('Cart saved to history with ${_cartItems.length} items - Total: ${savedCart.totalAmount} - PrestashopCartId: $prestashopCartId');

      return savedCart;
    } catch (e) {
      AlkLoggerHelper.error('Error saving cart to history', e);
      return null;
    }
  }

  /// Get all saved carts from history (sorted by date, newest first)
  List<SavedCart> getSavedCarts() {
    try {
      if (_savedCartsBox == null) {
        AlkLoggerHelper.error('Saved carts box not initialized');
        return [];
      }

      final carts = _savedCartsBox!.values.toList();
      // Sort by date, newest first
      carts.sort((a, b) => b.savedDate.compareTo(a.savedDate));
      return carts;
    } catch (e) {
      AlkLoggerHelper.error('Error getting saved carts', e);
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
      AlkLoggerHelper.info('Loaded saved cart with ${_cartItems.length} items');
    } catch (e) {
      AlkLoggerHelper.error('Error loading saved cart', e);
    }
  }

  /// Delete a saved cart from history
  Future<void> deleteSavedCart(String cartId) async {
    try {
      if (_savedCartsBox == null) {
        AlkLoggerHelper.error('Saved carts box not initialized');
        return;
      }

      await _savedCartsBox!.delete(cartId);
      notifyListeners();
      AlkLoggerHelper.info('Deleted saved cart: $cartId');
    } catch (e) {
      AlkLoggerHelper.error('Error deleting saved cart', e);
    }
  }

  /// Clear all saved carts from history
  Future<void> clearCartHistory() async {
    try {
      if (_savedCartsBox == null) {
        AlkLoggerHelper.error('Saved carts box not initialized');
        return;
      }

      await _savedCartsBox!.clear();
      notifyListeners();
      AlkLoggerHelper.info('Cleared all saved carts from history');
    } catch (e) {
      AlkLoggerHelper.error('Error clearing cart history', e);
    }
  }

  /// Find existing PrestaShop cart ID for current cart items
  /// DISABLED: Always create fresh carts. Reusing cart IDs from paid carts
  /// causes issues because Odoo finds the old paid cart and returns it as "verified"
  /// immediately, skipping the actual payment flow.
  String? findExistingPrestashopCartId() {
    // Always return null to force creation of a new PrestaShop cart
    // Each QR generation should create a fresh cart
    return null;
  }

  // ==================== PRESTASHOP CART CREATION ====================

  // ==================== PRESTASHOP CART FETCH ====================

  /// Fetch cart details from PrestaShop by cart ID
  /// Uses the custom mobile_cart_api module to get CALCULATED prices
  /// (includes discounts, specific prices, catalog rules, etc.)
  Future<Map<String, dynamic>?> fetchPrestaShopCart(String cartId) async {
    try {
      // Remove 'prestashop_' prefix if present
      String cleanCartId = cartId;
      if (cartId.startsWith('prestashop_')) {
        cleanCartId = cartId.substring('prestashop_'.length);
      }

      AlkLoggerHelper.debug('Fetching PrestaShop cart with calculated prices: $cleanCartId');

      // Use the custom mobile_cart_api module endpoint for calculated prices
      final url = 'https://www.alkirtas.com/module/mobile_cart_api/details?cart_id=$cleanCartId&ws_key=${AppConfig.prestashopApiKey}';
      AlkLoggerHelper.debug('URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Failed to fetch cart: ${response.statusCode}');
        return null;
      }

      // Use utf8.decode for proper Arabic/special character support
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] != true) {
        AlkLoggerHelper.error('API error: ${data['error']?['message'] ?? 'Unknown error'}');
        return null;
      }

      final cartData = data['cart'] as Map<String, dynamic>?;
      if (cartData == null) {
        AlkLoggerHelper.error('No cart data found');
        return null;
      }

      AlkLoggerHelper.info('Cart fetched: ${cartData['id']}');

      // Get customer info from response
      String customerName = '';
      String customerEmail = '';
      final customer = cartData['customer'] as Map<String, dynamic>?;
      if (customer != null) {
        final firstname = customer['firstname']?.toString() ?? '';
        final lastname = customer['lastname']?.toString() ?? '';
        customerName = '$firstname $lastname'.trim();
        customerEmail = customer['email']?.toString() ?? '';
        AlkLoggerHelper.debug('Customer: $customerName');
      }

      // Get cart items with calculated prices
      final cartItems = cartData['items'] as List? ?? [];
      AlkLoggerHelper.debug('Cart has ${cartItems.length} products');

      // Convert items to our format
      List<Map<String, dynamic>> items = [];

      for (var item in cartItems) {
        final productId = item['id_product']?.toString() ?? '';
        final quantity = item['quantity'] ?? 1;

        // Use CALCULATED price from the module (unit_price_tax_incl)
        // This price already includes all discounts from PrestaShop
        final calculatedPrice = item['unit_price_tax_incl'] ?? 0.0;
        final originalPrice = item['original_price_tax_incl'] ?? calculatedPrice;
        final reductionPercent = item['reduction_percent'] ?? 0.0;

        final productName = item['name']?.toString() ?? 'Product';
        final reference = item['reference']?.toString() ?? '';
        final manufacturer = item['manufacturer_name']?.toString() ?? '';

        // Build image URL
        String imageUrl = '';
        if (item['image_url'] != null && item['image_url'].toString().isNotEmpty) {
          imageUrl = item['image_url'].toString();
          // Ensure URL is properly formatted
          if (!imageUrl.startsWith('http')) {
            imageUrl = 'https://$imageUrl';
          }
        }

        items.add({
          'productId': productId,
          'productName': productName,
          'productReference': reference,
          'productPrice': calculatedPrice.toString(),  // CALCULATED price with discounts
          'productOriginalPrice': originalPrice.toString(),  // Original price before discount
          'productDiscount': reductionPercent.toString(),  // Discount percentage
          'productQuantity': quantity.toString(),
          'productImage': imageUrl,
          'productBrand': manufacturer,
        });

        AlkLoggerHelper.debug('Product $productId: $productName x$quantity @ $calculatedPrice (original: $originalPrice, discount: $reductionPercent%)');
      }

      // Use totals from the module response
      final totals = cartData['totals'] as Map<String, dynamic>?;
      final total = totals?['products_tax_incl'] ?? 0.0;

      return {
        'cartId': cleanCartId,
        'items': items,
        'totalAmount': (total is num) ? total.toDouble() : double.tryParse(total.toString()) ?? 0.0,
        'itemCount': items.fold<int>(0, (sum, item) => sum + (int.tryParse(item['productQuantity'] ?? '1') ?? 1)),
        'customerName': customerName,
        'customerEmail': customerEmail,
      };
    } catch (e) {
      AlkLoggerHelper.error('Error fetching PrestaShop cart', e);
      return null;
    }
  }

  // ==================== FETCH CUSTOMER POS ORDERS ====================

  /// Fetch order state name by ID from PrestaShop
  /// Uses cache to avoid repeated API calls
  Future<String> _fetchOrderStateName(String stateId) async {
    // Check cache first
    if (_orderStatesCache.containsKey(stateId)) {
      return _orderStatesCache[stateId]!;
    }

    try {
      final url = 'https://www.alkirtas.com/api/order_states?filter[id]=$stateId&display=full&ws_key=${AppConfig.prestashopApiKey}&output_format=JSON';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final states = data['order_states'] as List?;
        if (states != null && states.isNotEmpty) {
          final stateName = states[0]['name']?.toString() ?? 'Inconnu';
          _orderStatesCache[stateId] = stateName;
          return stateName;
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Error fetching order state $stateId', e);
    }

    return 'Inconnu';
  }

  /// Fetch PrestaShop website orders from core API
  Future<List<Map<String, dynamic>>> _fetchPrestaShopOrders() async {
    try {
      if (UserData.id.isEmpty) {
        return [];
      }

      AlkLoggerHelper.debug('Fetching PrestaShop website orders for customer ${UserData.id}...');

      final url = 'https://www.alkirtas.com/api/orders?filter[id_customer]=${UserData.id}&display=full&ws_key=${AppConfig.prestashopApiKey}&output_format=JSON';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Failed to fetch PrestaShop orders: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final ordersData = data['orders'] as List? ?? [];
      AlkLoggerHelper.info('Found ${ordersData.length} PrestaShop website orders');

      List<Map<String, dynamic>> orders = [];

      for (var order in ordersData) {
        // Get order state name
        final stateId = order['current_state']?.toString() ?? '0';
        final stateName = await _fetchOrderStateName(stateId);

        // Parse order rows (products)
        final associations = order['associations'] as Map<String, dynamic>? ?? {};
        final orderRows = associations['order_rows'] as List? ?? [];

        List<Map<String, dynamic>> items = [];
        for (var row in orderRows) {
          items.add({
            'productId': row['product_id']?.toString() ?? '',
            'productName': row['product_name']?.toString() ?? '',
            'productReference': row['product_reference']?.toString() ?? '',
            'productPrice': double.tryParse(row['product_price']?.toString() ?? '0') ?? 0.0,
            'productQuantity': row['product_quantity']?.toString() ?? '1',
            'productImage': '', // Would need separate API call to get product image
            'subtotal': (double.tryParse(row['product_price']?.toString() ?? '0') ?? 0.0) *
                (int.tryParse(row['product_quantity']?.toString() ?? '1') ?? 1),
            'discountPercent': 0.0,
            'isAddedByCashier': false,
            'quantityChanged': false,
          });
        }

        // Calculate item count
        int itemCount = 0;
        for (var row in orderRows) {
          itemCount += int.tryParse(row['product_quantity']?.toString() ?? '1') ?? 1;
        }

        orders.add({
          'orderId': order['id']?.toString() ?? '',
          'cartId': order['id_cart']?.toString() ?? '',
          'sessionId': '', // No session for website orders
          'posOrderName': '', // No POS order name for website orders
          'prestashopOrderRef': order['reference']?.toString() ?? '',
          'customerName': '', // Could fetch from customer API if needed
          'posTotal': double.tryParse(order['total_paid']?.toString() ?? '0') ?? 0.0,
          'paidAt': order['date_add']?.toString() ?? '',
          'dateAdd': order['date_add']?.toString() ?? '',
          'itemCount': itemCount,
          'hasModifications': false,
          'items': items,
          // PrestaShop specific fields
          'isWebsiteOrder': true,
          'orderState': stateName,
          'orderStateId': stateId,
          'paymentMethod': order['payment']?.toString() ?? '',
          'invoiceNumber': order['invoice_number']?.toString() ?? '',
          'deliveryNumber': order['delivery_number']?.toString() ?? '',
        });
      }

      return orders;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching PrestaShop orders', e);
      return [];
    }
  }

  /// Fetch all orders for the current customer (POS orders + PrestaShop website orders)
  /// Uses the custom mobile_cart_api/orders endpoint for POS orders
  /// and core PrestaShop API for website orders
  Future<List<Map<String, dynamic>>> fetchCustomerCarts() async {
    try {
      // Check if user is logged in
      if (UserData.id.isEmpty) {
        AlkLoggerHelper.warning('Cannot fetch orders: User not logged in');
        return [];
      }

      AlkLoggerHelper.debug('Fetching POS orders for customer ${UserData.id}...');

      final url = 'https://www.alkirtas.com/module/mobile_cart_api/orders?customer_id=${UserData.id}&ws_key=${AppConfig.prestashopApiKey}';
      AlkLoggerHelper.debug('URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Failed to fetch orders: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] != true) {
        AlkLoggerHelper.error('API error: ${data['error']?['message'] ?? 'Unknown error'}');
        return [];
      }

      final ordersData = data['data']?['orders'] as List? ?? [];
      AlkLoggerHelper.info('Found ${ordersData.length} POS orders');

      List<Map<String, dynamic>> orders = [];
      for (var order in ordersData) {
        // Parse items from the order
        final items = (order['items'] as List? ?? []).map((item) {
          return {
            'productId': item['product_id']?.toString() ?? '',
            'productName': item['product_name']?.toString() ?? '',
            'productReference': item['product_reference']?.toString() ?? '',
            'productPrice': (item['unit_price'] is num)
                ? (item['unit_price'] as num).toDouble()
                : double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0,
            'productQuantity': item['quantity']?.toString() ?? '1',
            'productImage': item['product_image']?.toString() ?? '',
            'productBrand': '', // Not stored in POS orders
            'subtotal': (item['subtotal'] is num)
                ? (item['subtotal'] as num).toDouble()
                : double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0.0,
            'discountPercent': (item['discount_percent'] is num)
                ? (item['discount_percent'] as num).toDouble()
                : double.tryParse(item['discount_percent']?.toString() ?? '0') ?? 0.0,
            'isAddedByCashier': item['is_added_by_cashier'] ?? false,
            'quantityChanged': item['quantity_changed'] ?? false,
          };
        }).toList();

        orders.add({
          'orderId': order['order_id']?.toString() ?? '',
          'cartId': order['cart_id']?.toString() ?? '',
          'sessionId': order['session_id']?.toString() ?? '',  // For matching with active cart
          'posOrderName': order['pos_order_name']?.toString() ?? '',
          'customerName': order['customer_name']?.toString() ?? '',
          'posTotal': (order['total_amount'] is num)
              ? (order['total_amount'] as num).toDouble()
              : double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0,
          'paidAt': order['paid_at']?.toString() ?? '',
          'dateAdd': order['date_add']?.toString() ?? '',
          'itemCount': order['item_count'] ?? 0,
          'hasModifications': order['has_modifications'] ?? false,
          'items': items, // Items are included in the response
          'isWebsiteOrder': false, // POS order flag
          'orderState': 'Payé', // POS orders are always paid
        });
      }

      // Also fetch PrestaShop website orders
      final prestashopOrders = await _fetchPrestaShopOrders();
      orders.addAll(prestashopOrders);

      // Sort all orders by date (newest first)
      orders.sort((a, b) {
        final dateA = DateTime.tryParse(a['paidAt']?.toString() ?? a['dateAdd']?.toString() ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['paidAt']?.toString() ?? b['dateAdd']?.toString() ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA); // Descending order
      });

      AlkLoggerHelper.info('Total orders: ${orders.length} (POS: ${orders.where((o) => o['isWebsiteOrder'] != true).length}, Website: ${prestashopOrders.length})');

      return orders;
    } catch (e) {
      AlkLoggerHelper.error('Error fetching customer orders', e);
      return [];
    }
  }

  /// Fetch a specific order's details by order ID (if needed)
  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    try {
      AlkLoggerHelper.debug('Fetching order details for order $orderId...');

      final url = 'https://www.alkirtas.com/module/mobile_cart_api/orders?order_id=$orderId&ws_key=${AppConfig.prestashopApiKey}';
      AlkLoggerHelper.debug('URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error('Failed to fetch order: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] != true) {
        AlkLoggerHelper.error('API error: ${data['error']?['message'] ?? 'Unknown error'}');
        return null;
      }

      final order = data['order'] as Map<String, dynamic>?;
      if (order == null) {
        AlkLoggerHelper.error('No order data found');
        return null;
      }

      AlkLoggerHelper.info('Order fetched: ${order['pos_order_name']}');

      // Parse items
      final items = (order['items'] as List? ?? []).map((item) {
        return {
          'productId': item['product_id']?.toString() ?? '',
          'productName': item['product_name']?.toString() ?? '',
          'productReference': item['product_reference']?.toString() ?? '',
          'productPrice': (item['unit_price'] is num)
              ? (item['unit_price'] as num).toDouble()
              : double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0,
          'productQuantity': item['quantity']?.toString() ?? '1',
          'productImage': item['product_image']?.toString() ?? '',
          'subtotal': (item['subtotal'] is num)
              ? (item['subtotal'] as num).toDouble()
              : double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0.0,
        };
      }).toList();

      return {
        'orderId': order['order_id']?.toString() ?? '',
        'cartId': order['cart_id']?.toString() ?? '',
        'posOrderName': order['pos_order_name']?.toString() ?? '',
        'customerName': order['customer_name']?.toString() ?? '',
        'customerEmail': order['customer_email']?.toString() ?? '',
        'posTotal': (order['total_amount'] is num)
            ? (order['total_amount'] as num).toDouble()
            : double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0,
        'paidAt': order['paid_at']?.toString() ?? '',
        'itemCount': order['item_count'] ?? 0,
        'hasModifications': order['has_modifications'] ?? false,
        'items': items,
      };
    } catch (e) {
      AlkLoggerHelper.error('Error fetching order details', e);
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
        AlkLoggerHelper.warning('Cannot create PrestaShop cart: User not logged in');
        return null;
      }

      // Check if cart has items
      if (_cartItems.isEmpty) {
        AlkLoggerHelper.warning('Cannot create PrestaShop cart: Cart is empty');
        return null;
      }

      AlkLoggerHelper.debug('Creating PrestaShop cart for user ${UserData.id}...');

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

      AlkLoggerHelper.debug('PrestaShop response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse XML response to get cart ID
        final document = xml.XmlDocument.parse(response.body);
        final cartIdElement = document.findAllElements('id').first;
        final cartId = cartIdElement.text;

        AlkLoggerHelper.info('PrestaShop cart created successfully! ID: $cartId');
        return cartId;
      } else {
        AlkLoggerHelper.error('Failed to create PrestaShop cart: ${response.statusCode}');
        AlkLoggerHelper.debug('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      AlkLoggerHelper.error('Error creating PrestaShop cart', e);
      return null;
    }
  }

  /// Delete a cart from PrestaShop
  /// Called after payment is confirmed to clean up the cart
  Future<bool> deletePrestaShopCart(String cartId) async {
    try {
      if (cartId.isEmpty) {
        AlkLoggerHelper.warning('Cannot delete PrestaShop cart: Cart ID is empty');
        return false;
      }

      AlkLoggerHelper.debug('Deleting PrestaShop cart ID: $cartId...');

      final String url = 'https://www.alkirtas.com/api/carts/$cartId?ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/xml',
        },
      );

      AlkLoggerHelper.debug('PrestaShop delete response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        AlkLoggerHelper.info('PrestaShop cart $cartId deleted successfully!');
        return true;
      } else if (response.statusCode == 404) {
        // Cart doesn't exist - that's fine, might have been already deleted
        AlkLoggerHelper.debug('PrestaShop cart $cartId not found (already deleted or does not exist)');
        return true;
      } else {
        AlkLoggerHelper.error('Failed to delete PrestaShop cart: ${response.statusCode}');
        AlkLoggerHelper.debug('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      AlkLoggerHelper.error('Error deleting PrestaShop cart', e);
      return false;
    }
  }
}

/// This is the provider for the cart screen
/// It contains the cart items and methods to add and remove items from the cart
/// It also contains a method to calculate the total price of the cart

