import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/size.dart';
import '../../controllers/cart_provider.dart';
import 'package:alkirtas/utils/backendData/userData.dart';

class CartHistoryScreen extends StatefulWidget {
  const CartHistoryScreen({super.key});

  @override
  State<CartHistoryScreen> createState() => _CartHistoryScreenState();
}

class _CartHistoryScreenState extends State<CartHistoryScreen> {
  List<Map<String, dynamic>> _paidCarts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaidCarts();
  }

  Future<void> _loadPaidCarts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final carts = await cartProvider.fetchCustomerCarts();

      // Check if any paid order matches the active cart's session ID
      // If so, the payment was completed and we should clear the cart
      final activeCartId = cartProvider.activeCartId;
      print('🔍 Active cart ID from provider: $activeCartId');

      if (activeCartId != null && activeCartId.isNotEmpty) {
        // Debug: print all session IDs from orders
        for (var order in carts) {
          print('   Order ${order['posOrderName']}: sessionId=${order['sessionId']}, cartId=${order['cartId']}');
        }

        // Try to match with session_id (might have prestashop_ prefix)
        // or with cartId (raw cart ID)
        final matchingOrder = carts.firstWhere(
          (order) {
            final orderSessionId = order['sessionId']?.toString() ?? '';
            final orderCartId = order['cartId']?.toString() ?? '';

            // Match against activeCartId directly, or with prestashop_ prefix
            return orderSessionId == activeCartId ||
                   orderSessionId == 'prestashop_$activeCartId' ||
                   orderCartId == activeCartId;
          },
          orElse: () => {},
        );

        if (matchingOrder.isNotEmpty) {
          // Found a paid order matching the active cart - clear the cart!
          print('✅ Found paid order matching active cart ID: $activeCartId');
          print('   Order: ${matchingOrder['posOrderName']}');

          // Delete the PrestaShop cart first
          await cartProvider.deletePrestaShopCart(activeCartId);

          // Then clear the local cart
          await cartProvider.clearCart();
          print('🧹 Cart cleared - payment confirmed via History');
        } else {
          print('⚠️ No matching order found for activeCartId: $activeCartId');
        }
      }

      setState(() {
        _paidCarts = carts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Parse date string from PrestaShop
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Format date
  String formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  // Get French month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }

  // Generate QR data for a cart
  String _generateQrData(Map<String, dynamic> cart) {
    return jsonEncode({
      'cart_id': cart['cartId'],
      'customer_id': UserData.id,
    });
  }

  // Show QR code dialog for a paid cart
  void _showCartQR(BuildContext context, Map<String, dynamic> cart) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth * 0.5).clamp(200.0, 350.0);
    final qrData = _generateQrData(cart);
    final paidAt = _parseDate(cart['paidAt']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QR Code du Panier',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (cart['posOrderName'] != null && cart['posOrderName'].toString().isNotEmpty)
                    Text(
                      cart['posOrderName'].toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    formatDate(paidAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.purple[300]!,
                        width: 3,
                      ),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: qrSize,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cart Info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${cart['itemCount'] ?? 0}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                            ),
                            Text(
                              'Articles',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              '${(cart['posTotal'] as double).toStringAsFixed(3)} TND',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                            ),
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show order details - items are already included in the order data
  void _showCartDetails(BuildContext context, Map<String, dynamic> order) {
    // Items are now included directly in the order response from /orders endpoint
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = order['posTotal'] as double? ?? 0.0;
    final paidAt = _parseDate(order['paidAt']);
    final hasModifications = order['hasModifications'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return _buildCartDetailsContent(
            context,
            scrollController,
            items,
            total,
            paidAt,
            posOrderName: order['posOrderName']?.toString() ?? '',
            hasModifications: hasModifications,
          );
        },
      ),
    );
  }

  // Build cart details content
  Widget _buildCartDetailsContent(
    BuildContext context,
    ScrollController scrollController,
    List<Map<String, dynamic>> items,
    double totalAmount,
    DateTime? paidAt, {
    String posOrderName = '',
    bool hasModifications = false,
  }) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Détails du Panier',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Payé',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasModifications) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 12, color: Colors.orange[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Modifié',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (posOrderName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        posOrderName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      formatDate(paidAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Divider(),

        // Items List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Panier vide',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final quantity = int.tryParse(item['productQuantity']?.toString() ?? '1') ?? 1;
                    final unitPrice = item['productPrice'] as double? ?? 0.0;
                    final subtotal = item['subtotal'] as double? ?? (unitPrice * quantity);
                    final discountPercent = item['discountPercent'] as double? ?? 0.0;
                    final isAddedByCashier = item['isAddedByCashier'] as bool? ?? false;
                    final quantityChanged = item['quantityChanged'] as bool? ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                if (item['productImage'] != null && item['productImage'].toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['productImage'].toString(),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.shopping_bag, color: Colors.grey[400]),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.shopping_bag, color: Colors.grey[400]),
                                  ),

                                const SizedBox(width: 12),

                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['productName']?.toString() ?? 'Produit',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Price per unit
                                      Text(
                                        '${unitPrice.toStringAsFixed(3)} TND / unité',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                      // Modification badges
                                      if (isAddedByCashier || quantityChanged) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            if (isAddedByCashier)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Ajouté',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            if (quantityChanged)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Qté modifiée',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.orange[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Quantity and subtotal
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Quantity badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'x$quantity',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[700],
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Subtotal
                                    Text(
                                      '${subtotal.toStringAsFixed(3)} TND',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                    ),
                                    // Discount if any
                                    if (discountPercent > 0)
                                      Text(
                                        '-${discountPercent.toStringAsFixed(0)}%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.red[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Total
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(3)} TND',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlkAppBar(
        showBackArrow: true,
        title: Text(
          'Historique des Paniers',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: _loadPaidCarts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Check if user is logged in
    if (UserData.id.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour voir votre historique',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPaidCarts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_paidCarts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun panier payé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Vos paniers payés en magasin apparaîtront ici',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaidCarts,
      child: ListView.separated(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        itemCount: _paidCarts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cart = _paidCarts[index];
          final paidAt = _parseDate(cart['paidAt']);
          final posTotal = cart['posTotal'] as double? ?? 0.0;
          final posOrderName = cart['posOrderName']?.toString() ?? '';
          final itemCount = cart['itemCount'] ?? 0;
          final hasModifications = cart['hasModifications'] as bool? ?? false;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showCartDetails(context, cart),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // POS Order Name and Paid badge
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (posOrderName.isNotEmpty)
                                    Text(
                                      posOrderName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Payé',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasModifications)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 12, color: Colors.orange[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Modifié',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Date
                              Text(
                                formatDate(paidAt),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              // Items and Total
                              Row(
                                children: [
                                  Text(
                                    '$itemCount articles',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${posTotal.toStringAsFixed(3)} TND',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple[700],
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // QR button
                        IconButton(
                          onPressed: () => _showCartQR(context, cart),
                          icon: Icon(Icons.qr_code, color: Colors.purple[700], size: 28),
                          tooltip: 'Afficher QR Code',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
