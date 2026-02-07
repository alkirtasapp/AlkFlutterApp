import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';

/// CartQRDialog - Shows QR code for POS scanning
///
/// Flow (no polling):
/// 1. User generates QR → cart saved to history immediately
/// 2. Cashier scans QR → Odoo loads cart from PrestaShop
/// 3. Payment completed → Odoo sends pos_total to PrestaShop
/// 4. User checks history → fetches cart from PrestaShop (with pos_total if paid)
class CartQRDialog extends StatefulWidget {
  final String qrData;
  final String sessionId;
  final CartProvider cartProvider;

  const CartQRDialog({
    Key? key,
    required this.qrData,
    required this.sessionId,
    required this.cartProvider,
  }) : super(key: key);

  @override
  State<CartQRDialog> createState() => _CartQRDialogState();
}

class _CartQRDialogState extends State<CartQRDialog> {
  bool _savedToHistory = false;

  @override
  void initState() {
    super.initState();
    // Save cart to history immediately when QR is displayed
    _saveToHistoryOnce();
  }

  /// Note: Cart is NO LONGER cleared here.
  /// Cart will be cleared when user opens History page and a paid order
  /// with matching session_id is found (confirming payment was completed).
  ///
  /// PREVIOUS BEHAVIOR (kept for rollback reference):
  /// ```dart
  /// Future<void> _saveToHistoryOnce() async {
  ///   if (_savedToHistory) return;
  ///   _savedToHistory = true;
  ///   await widget.cartProvider.clearCart();
  ///   print('🧹 Cart cleared - history will be available in PrestaShop after payment');
  /// }
  /// ```
  Future<void> _saveToHistoryOnce() async {
    if (_savedToHistory) return;
    _savedToHistory = true;
    // Cart is kept - will be cleared when payment is confirmed via History page
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
          boxShadow: const [
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
                        color: AlkColors.AppSecColor,
                      ),
                ),
                const SizedBox(height: 16),

                // Status indicator - Cart ready
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Prêt à scanner',
                          style: TextStyle(
                            color: Colors.blue[700],
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
                        color: AlkColors.AppSecColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AlkColors.AppSecColor,
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
                              color: AlkColors.AppSecColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Appuyez pour agrandir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AlkColors.AppSecColor,
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
                        '4. Consultez l\'historique pour voir vos achats',
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
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AlkColors.AppFirstColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
