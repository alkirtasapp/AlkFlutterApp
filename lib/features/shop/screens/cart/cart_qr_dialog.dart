import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    this.odooBaseUrl = 'http://10.52.97.188:8069', // Physical device on local Wi-Fi network
  }) : super(key: key);

  @override
  State<CartQRDialog> createState() => _CartQRDialogState();
}

class _CartQRDialogState extends State<CartQRDialog> {
  bool _syncShown = false;

  @override
  void initState() {
    super.initState();
    // Start background sync - will continue even if dialog is closed!
    _startBackgroundSync();
    // Listen for provider changes
    widget.cartProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.cartProvider.removeListener(_onProviderChanged);
    // Note: Don't stop background sync here - let it continue!
    super.dispose();
  }

  void _startBackgroundSync() {
    widget.cartProvider.startBackgroundSync(
      sessionId: widget.sessionId,
      odooBaseUrl: widget.odooBaseUrl,
      qrData: widget.qrData,
      onComplete: (success, message) {
        // This callback is called when sync completes (even if dialog is closed)
        print('🔔 Background sync callback: success=$success, message=$message');
      },
    );
  }

  void _onProviderChanged() {
    // Rebuild UI when provider changes
    if (mounted) {
      setState(() {});

      // Show sync complete confirmation when sync finishes
      if (widget.cartProvider.syncComplete && !_syncShown) {
        _syncShown = true;
        _showSyncCompleteConfirmation();
      }
    }
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[600], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Panier sauvegardé dans l\'historique',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
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

    // Get sync state from provider
    final isSyncing = widget.cartProvider.isSyncing;
    final syncComplete = widget.cartProvider.syncComplete;
    final syncStatus = widget.cartProvider.syncStatus;

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
                        color: syncComplete ? Colors.green[700] : Colors.purple[700],
                      ),
                ),
                const SizedBox(height: 16),

                // Sync status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: syncComplete ? Colors.green[50] : Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: syncComplete ? Colors.green[300]! : Colors.purple[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSyncing && !syncComplete)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
                          ),
                        )
                      else if (syncComplete)
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20)
                      else
                        Icon(Icons.hourglass_empty, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          syncStatus.isNotEmpty ? syncStatus : 'En attente...',
                          style: TextStyle(
                            color: syncComplete ? Colors.green[700] : Colors.purple[700],
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
                        color: syncComplete ? Colors.green[300]! : Colors.purple[300]!,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: syncComplete ? Colors.green[100]! : Colors.purple[100]!,
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
                        '3. Procédez au paiement au terminal\n'
                        '4. La synchronisation se fait automatiquement!',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      syncComplete ? 'Terminé' : 'Fermer',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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
