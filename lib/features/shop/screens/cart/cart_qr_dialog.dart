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
    this.odooBaseUrl = 'http://10.220.225.242:8069', // Physical device on local network
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

          // Auto-close after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true); // Return true to indicate success
            }
          });
        }

        // Cleanup session from Odoo
        _deleteSession();

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
      final items = verifiedData['items'] as List;

      // IMPORTANT: Save original cart items BEFORE clearing
      final originalCartItems = List<Map<String, String>>.from(widget.cartProvider.cartItems);

      // Clear current cart
      await widget.cartProvider.clearCart();

      // Add verified items back with updated quantities
      for (var item in items) {
        final productRef = (item['product_reference'] ?? '').toString();
        final verifiedQty = (item['verified_quantity'] is int)
            ? item['verified_quantity'] as int
            : int.tryParse(item['verified_quantity']?.toString() ?? '0') ?? 0;
        final productId = item['product_id']?.toString() ?? '';
        final productName = (item['product_name'] ?? '').toString();
        final price = item['price']?.toString() ?? '0';

        print('📦 Processing item: $productName, Ref: $productRef, Qty: $verifiedQty');

        // Skip items with 0 quantity (already filtered on Odoo side, but double-check)
        if (verifiedQty <= 0) {
          print('⏭️ Skipping $productName (quantity: $verifiedQty)');
          continue;
        }

        // Find the original cart item to get full product data from saved list
        final originalItem = originalCartItems.firstWhere(
          (cartItem) => cartItem['productReference'] == productRef,
          orElse: () => {},
        );

        if (originalItem.isNotEmpty) {
          // Existing product from original cart
          await widget.cartProvider.addToCart(
            productId: originalItem['productId'] ?? '',
            productName: originalItem['productName'] ?? '',
            productBrand: originalItem['productBrand'],
            productPrice: originalItem['productPrice'] ?? '0',
            productDiscount: originalItem['productDiscount'],
            productOldPrice: originalItem['productOldPrice'],
            productNewPrice: originalItem['productNewPrice'],
            productImage: originalItem['productImage'],
            productReference: originalItem['productReference'],
            productStock: originalItem['productStock'],
            productDescription: originalItem['productDescription'],
            productBrandId: originalItem['productBrandId'],
            productImageList: originalItem['productImageList']?.split(','),
            productFeatures: originalItem['productFeatures']?.split(','),
            quantity: verifiedQty, // Use verified quantity from Odoo
          );
          print('✅ Updated existing product: $productName (qty: $verifiedQty)');
        } else {
          // New product added during Odoo verification
          // Add it with minimal data from Odoo
          await widget.cartProvider.addToCart(
            productId: productId,
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
          print('✅ Added new product: $productName (qty: $verifiedQty) - Added by cashier');
        }
      }

      print('✅ Cart updated successfully with ${items.length} items');
    } catch (e) {
      print('❌ Error updating cart: $e');
    }
  }

  Future<void> _deleteSession() async {
    try {
      final url = '${widget.odooBaseUrl}/pos/api/verified_cart/${widget.sessionId}';
      await http.delete(Uri.parse(url));
      print('🗑️ Session deleted from Odoo');
    } catch (e) {
      print('⚠️ Error deleting session: $e');
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

                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
