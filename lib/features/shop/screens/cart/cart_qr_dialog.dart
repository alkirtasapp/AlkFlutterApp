import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';

class CartQRDialog extends StatefulWidget {
  final String qrData;
  final String sessionId;
  final CartProvider cartProvider;

  // IMPORTANT: Change this URL for production!
  // For local testing: 'http://192.168.1.X:8069'  (replace X with your local IP)
  // For production: 'https://www.odoo.alkirtas.com'
  final String odooBaseUrl;

  const CartQRDialog({
    Key? key,
    required this.qrData,
    required this.sessionId,
    required this.cartProvider,
    this.odooBaseUrl = 'http://10.130.193.63:8069', // Physical device on local Wi-Fi network
  }) : super(key: key);

  @override
  State<CartQRDialog> createState() => _CartQRDialogState();
}

class _CartQRDialogState extends State<CartQRDialog> {
  Timer? _pollTimer;
  bool _isSyncing = false;
  bool _syncComplete = false;
  String _syncMessage = 'En attente de vérification...';
  int _pollCount = 0;
  static const int _maxPolls = 100; // 5 minutes (100 * 3 seconds)

  @override
  void initState() {
    super.initState();
    // Start polling after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    print('🔄 Starting to poll for session: ${widget.sessionId}');
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _pollCount++;

      // Stop after max polls (5 minutes)
      if (_pollCount >= _maxPolls) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _syncMessage = 'Délai d\'attente dépassé. Fermez et réessayez.';
          });
        }
        return;
      }

      await _checkForVerifiedCart();
    });
  }

  Future<void> _checkForVerifiedCart() async {
    if (_isSyncing || _syncComplete) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final url = '${widget.odooBaseUrl}/pos/api/verified_cart/${widget.sessionId}';
      print('📡 Polling: $url (Attempt $_pollCount)');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        // Cart verified! Parse and update
        final verifiedData = jsonDecode(response.body);
        print('✅ Cart verified! Data: $verifiedData');

        await _updateCartFromVerified(verifiedData);

        // Stop polling
        _pollTimer?.cancel();

        if (mounted) {
          setState(() {
            _syncComplete = true;
            _syncMessage = '✓ Panier synchronisé avec succès!';
          });

          // Show confirmation dialog
          await _showSyncCompleteConfirmation();
        }

        // Note: Session is automatically marked as 'synced' in Odoo when retrieved
        // It will be auto-deleted after 30 days by Odoo's scheduled cleanup job
        // No need to delete manually - this keeps traceability records

      } else if (response.statusCode == 404) {
        // Not ready yet, keep polling
        print('⏳ Cart not verified yet...');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Polling error: $e');
      // Continue polling on error (network might be temporarily unavailable)
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _updateCartFromVerified(Map<String, dynamic> verifiedData) async {
    try {
      // Get cartItems from the verified data
      final cartItems = verifiedData['cartItems'] as List?;

      if (cartItems == null || cartItems.isEmpty) {
        print('❌ No cart items in verified data');
        throw Exception('No cart items found in verified data');
      }

      print('📦 Processing ${cartItems.length} verified items');

      // IMPORTANT: Save original cart items BEFORE clearing
      final originalCartItems = List<Map<String, String>>.from(widget.cartProvider.cartItems);

      // Clear current cart
      await widget.cartProvider.clearCart();

      // Add verified items back with updated quantities
      for (var item in cartItems) {
        final productRef = (item['productReference'] ?? '').toString();
        final verifiedQty = int.tryParse(item['productQuantity']?.toString() ?? '1') ?? 1;
        final price = (item['productPrice'] ?? '0').toString();
        final productNameFromOdoo = item['productName']?.toString();
        final productIdFromOdoo = item['productId']?.toString();

        print('📦 Processing item: Ref: $productRef, Name: $productNameFromOdoo, Qty: $verifiedQty, Price: $price');

        // Skip items with 0 quantity
        if (verifiedQty <= 0) {
          print('⏭️ Skipping item (quantity: $verifiedQty)');
          continue;
        }

        // Find the original cart item to get full product data
        final originalItem = originalCartItems.firstWhere(
          (cartItem) => cartItem['productReference'] == productRef,
          orElse: () => {},
        );

        if (originalItem.isNotEmpty) {
          // Existing product from original cart - restore with verified quantity and price
          // Use Odoo price in case cashier adjusted it at POS
          await widget.cartProvider.addToCart(
            productId: originalItem['productId'] ?? '',
            productName: originalItem['productName'] ?? '',
            productBrand: originalItem['productBrand'],
            productPrice: price, // Use verified Odoo price (may be adjusted by cashier)
            productDiscount: '0', // Discount already applied in Odoo price
            productOldPrice: originalItem['productOldPrice'],
            productNewPrice: price, // Use verified Odoo price
            productImage: originalItem['productImage'],
            productReference: originalItem['productReference'],
            productStock: originalItem['productStock'],
            productDescription: originalItem['productDescription'],
            productBrandId: originalItem['productBrandId'],
            productImageList: originalItem['productImageList']?.split(','),
            productFeatures: originalItem['productFeatures']?.split(','),
            quantity: verifiedQty, // Use verified quantity from Odoo
          );
          print('✅ Updated existing product: ${originalItem['productName']} (qty: $verifiedQty, price: $price TND)');
        } else {
          // New product added during Odoo verification
          // Try to fetch full details from PrestaShop, but use Odoo data as fallback
          print('🔍 Fetching details for new product: $productNameFromOdoo (Ref: $productRef)');

          final fullProductData = await _fetchProductDetailsByReference(productRef);

          if (fullProductData != null) {
            // Add with full product data from PrestaShop
            // IMPORTANT: Use Odoo price (includes mobile app discounts), not PrestaShop price
            await widget.cartProvider.addToCart(
              productId: fullProductData['productId'] ?? productIdFromOdoo ?? productRef,
              productName: fullProductData['productName'] ?? productNameFromOdoo ?? 'Product',
              productBrand: fullProductData['productBrand'],
              productPrice: price, // Use Odoo price (verified and includes discounts)
              productDiscount: '0', // Discount already applied in Odoo price
              productOldPrice: fullProductData['productOldPrice'],
              productNewPrice: price, // Use Odoo price as the new price
              productImage: fullProductData['productImage'],
              productReference: productRef,
              productStock: fullProductData['productStock'],
              productDescription: fullProductData['productDescription'],
              productBrandId: fullProductData['productBrandId'],
              productImageList: fullProductData['productImageList'],
              productFeatures: fullProductData['productFeatures'],
              quantity: verifiedQty,
            );
            print('✅ Added new product from PrestaShop: ${fullProductData['productName']} (qty: $verifiedQty, price: $price TND)');
          } else {
            // Fallback: Use Odoo data if PrestaShop fetch fails
            final productName = productNameFromOdoo ?? 'Product $productRef';
            await widget.cartProvider.addToCart(
              productId: productIdFromOdoo ?? productRef,
              productName: productName,
              productBrand: null,
              productPrice: price,
              productDiscount: null,
              productOldPrice: null,
              productNewPrice: null,
              productImage: null,
              productReference: productRef,
              productStock: null,
              productDescription: null,
              productBrandId: null,
              productImageList: null,
              productFeatures: null,
              quantity: verifiedQty,
            );
            print('✅ Added new product from Odoo data: $productName (qty: $verifiedQty)');
          }
        }
      }

      print('✅ Cart updated successfully with ${cartItems.length} items');
    } catch (e) {
      print('❌ Error updating cart: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchProductDetailsByReference(String productReference) async {
    // Use the more complete method that has UTF-8 support
    return await _fetchProductDetails('', productReference);
  }

  Future<Map<String, dynamic>?> _fetchProductDetails(String productId, String productReference) async {
    try {
      // Fetch product by REFERENCE (barcode) - more reliable than ID since Odoo ID might differ from PrestaShop ID
      String url = 'https://www.alkirtas.com/api/products?display=full&filter[reference]=$productReference&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU&output_format=JSON';

      print('🌐 Fetching product by reference: $productReference');
      print('   URL: $url');

      var response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // IMPORTANT: Use utf8.decode for proper Arabic text encoding
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Check if response is valid JSON object (not array)
        if (data is! Map) {
          print('❌ Invalid API response format (expected Map, got ${data.runtimeType})');
          return null;
        }

        print('📦 PrestaShop API Response keys: ${data.keys}');

        // Handle null or empty products
        if (data['products'] == null) {
          print('❌ No products field in response');
          return null;
        }

        // Get the product - handle both array and map formats
        dynamic product;
        if (data['products'] is List) {
          if ((data['products'] as List).isEmpty) {
            print('❌ Empty products array - no product found with reference: $productReference');
            return null;
          }
          product = data['products'][0];
          print('✅ Found product in array format');
        } else if (data['products'] is Map) {
          // Products is a map - get first value
          final productsMap = data['products'] as Map;
          if (productsMap.isEmpty) {
            print('❌ Empty products map - no product found with reference: $productReference');
            return null;
          }
          product = productsMap.values.first;
          print('✅ Found product in map format (key: ${productsMap.keys.first})');
        } else {
          print('❌ Unexpected products format: ${data['products'].runtimeType}');
          return null;
        }

        // IMPORTANT: Use the PrestaShop product ID, not the Odoo ID
        final String prestashopProductId = product['id']?.toString() ?? productId;

        // Extract product details with UTF-8 support
        final String productName = _extractValue(product['name']) ?? '';
        final String productDescription = _extractValue(product['description']) ?? '';
        final String productRef = product['reference']?.toString() ?? productReference;

        // Get base price
        final double basePrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;

        // Format price with 3 decimal places
        final String productPrice = basePrice.toStringAsFixed(3);

        // Get stock quantity
        final String productStock = product['quantity']?.toString() ?? '0';

        // Get manufacturer/brand
        String? brandId = product['id_manufacturer']?.toString();
        String? brandName;

        // Try to get manufacturer name if available in response
        // Note: PrestaShop API might need separate call to get brand name
        // For now, we'll use empty string and rely on brand images/features
        if (brandId != null && brandId != '0') {
          // Brand exists but name needs separate API call
          // TODO: Fetch brand name from manufacturers API if needed
          brandName = ''; // Will be empty for now
        }

        // Get images using the same method as ProductControllerStore
        List<String>? imageList;
        String? mainImage;

        try {
          final associations = product['associations'];
          if (associations != null && associations['images'] != null) {
            final images = associations['images'];
            final imagesList = images is List ? images : [images];

            imageList = [];
            for (var img in imagesList) {
              if (img != null && img['id'] != null) {
                final imgId = img['id'].toString();
                // Use the same image URL construction as ProductControllerStore
                final path = imgId.split('').join('/');
                imageList.add('https://www.alkirtas.com/img/p/$path/$imgId.jpg');
              }
            }
            mainImage = imageList.isNotEmpty ? imageList[0] : null;
          }
        } catch (e) {
          print('⚠️ Error parsing images: $e');
          imageList = null;
          mainImage = null;
        }

        // Get features
        List<String>? features;
        try {
          final associations = product['associations'];
          if (associations != null && associations['product_features'] != null) {
            final productFeatures = associations['product_features'];
            final featuresList = productFeatures is List ? productFeatures : [productFeatures];

            features = [];
            for (var f in featuresList) {
              if (f != null && f['id'] != null) {
                features.add(f['id'].toString());
              }
            }
          }
        } catch (e) {
          print('⚠️ Error parsing features: $e');
          features = null;
        }

        print('✅ Product details fetched successfully for: $productName');
        print('   PrestaShop ID: $prestashopProductId, Price: $productPrice, Images: ${imageList?.length ?? 0}');

        return {
          'productId': prestashopProductId,  // Use PrestaShop ID, not Odoo ID
          'productName': productName,
          'productBrand': brandName,
          'productBrandId': brandId,
          'productPrice': productPrice,
          'productDiscount': '0',
          'productOldPrice': productPrice,
          'productNewPrice': productPrice,
          'productImage': mainImage,
          'productReference': productRef,
          'productStock': productStock,
          'productDescription': productDescription,
          'productImageList': imageList,
          'productFeatures': features,
        };
      } else {
        print('❌ Failed to fetch product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching product details: $e');
      return null;
    }
  }

  // Helper method to extract value from PrestaShop API language arrays
  String? _extractValue(dynamic field) {
    if (field == null) return null;

    if (field is List && field.isNotEmpty) {
      // It's a language array, get first value
      final firstItem = field[0];
      if (firstItem is Map && firstItem['value'] != null) {
        return firstItem['value'].toString();
      }
    } else if (field is Map && field['value'] != null) {
      // Single language object
      return field['value'].toString();
    } else if (field is String) {
      // Direct string value
      return field;
    }

    return null;
  }

  // Show sync complete confirmation dialog
  Future<void> _showSyncCompleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Synchronisation Réussie!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre panier a été vérifié et synchronisé avec succès!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.cartProvider.cartItems.length} articles - ${_calculateTotal().toStringAsFixed(3)} TND',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Confirmer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        );
      },
    );

    // Close the QR dialog after confirmation
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // Calculate total price from cart
  double _calculateTotal() {
    return widget.cartProvider.cartItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['productPrice']?.toString() ?? '0') ?? 0.0;
      final quantity = int.tryParse(item['productQuantity']?.toString() ?? '1') ?? 1;
      return sum + (price * quantity);
    });
  }

  // Show QR code in fullscreen
  void _showFullscreenQR(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'QR Code - Plein Écran',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: MediaQuery.of(context).size.width * 0.95,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                padding: const EdgeInsets.all(20),
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final qrSize = (screenWidth * 0.5).clamp(200.0, 350.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9,
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'QR Code du Panier',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _syncComplete ? Colors.green[700] : Colors.purple[700],
                      ),
                ),
                const SizedBox(height: 16),

                // Sync status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _syncComplete ? Colors.green[50] : Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _syncComplete ? Colors.green[300]! : Colors.purple[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_syncComplete)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
                          ),
                        )
                      else
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _syncMessage,
                          style: TextStyle(
                            color: _syncComplete ? Colors.green[700] : Colors.purple[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cart Summary - Product count and total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${widget.cartProvider.cartItems.length}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Articles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[400],
                      ),
                      Column(
                        children: [
                          Text(
                            '${_calculateTotal().toStringAsFixed(3)} TND',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code - Tappable for fullscreen
                GestureDetector(
                  onTap: () => _showFullscreenQR(context),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _syncComplete ? Colors.green[300]! : Colors.purple[300]!,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _syncComplete ? Colors.green[100]! : Colors.purple[100]!,
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: widget.qrData,
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          padding: const EdgeInsets.all(16),
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fullscreen,
                              size: 16,
                              color: Colors.purple[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Appuyez pour agrandir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Montrez ce QR code au caissier\n'
                        '2. Le caissier vérifiera les articles\n'
                        '3. Votre panier sera automatiquement mis à jour',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons - Save and Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Save to History button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final savedCart = await widget.cartProvider.saveCartToHistory(widget.qrData);
                            if (savedCart != null && mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Panier sauvegardé dans l\'historique'),
                                  backgroundColor: Colors.green[600],
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur lors de la sauvegarde'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error saving cart: $e');
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text(
                          '',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Close button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
