import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/common/widgets/appbar/appbar.dart';
import 'package:alkirtas/common/widgets/products/cart/cartItem.dart';
import 'package:alkirtas/features/shop/screens/checkout/checkout.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:alkirtas/features/shop/screens/cart/cart_qr_dialog.dart';
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

import 'dart:convert';
import 'dart:typed_data';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Get the total price of the cart (product price * quantity)
  double getTotalPrice(CartProvider cartProvider) {
    return cartProvider.cartItems.fold(0.0, (sum, product) {
      final price = double.tryParse(product['productPrice'].toString()) ?? 0.0;
      final quantity = int.tryParse(product['productQuantity'].toString()) ?? 1;
      return sum + (price * quantity);
    });
  }

  // Get total price with delivery
  double getTotalPriceWithDelivery(CartProvider cartProvider) {
    return getTotalPrice(cartProvider) + 9.0; // Delivery fee is fixed at 9.0 TND
  }

  // Generate simple QR code data with PrestaShop cart_id + customer info
  // The cart_id is used by Odoo to fetch full cart details from PrestaShop API
  Map<String, dynamic> generateSimpleQRData(String prestashopCartId) {
    final qrData = {
      'cart_id': prestashopCartId,
      'customer_name': (UserData.firstname.isNotEmpty || UserData.lastname.isNotEmpty)
          ? '${UserData.firstname} ${UserData.lastname}'.trim()
          : null,
      'customer_email': UserData.email.isNotEmpty ? UserData.email : null,
    };

    return qrData;
  }

  // Create PrestaShop cart and return cart ID
  // Returns null if creation fails
  Future<String?> createPrestashopCartForQR(CartProvider cartProvider) async {
    try {
      // Check if we already have a PrestaShop cart ID for this cart
      final existingCartId = cartProvider.findExistingPrestashopCartId();
      if (existingCartId != null) {
        AlkLoggerHelper.info("QR cart ready: $existingCartId (reused)");
        return existingCartId;
      }

      // Create new cart on PrestaShop
      final cartId = await createCart(cartProvider.cartItems);
      AlkLoggerHelper.info("QR cart created: $cartId");
      return cartId;
    } catch (e) {
      AlkLoggerHelper.error("PrestaShop cart creation failed", e);
      return null;
    }
  }

  // Show QR code in fullscreen
  void showFullscreenQR(BuildContext context, String qrData) {
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
                data: qrData,
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

  // Show QR code dialog with automatic polling for cart sync
  // NEW FLOW: Creates PrestaShop cart first, then generates simple QR with cart_id
  void showQRCodeDialog(BuildContext context, CartProvider cartProvider) async {
    // Show loading indicator while creating PrestaShop cart
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Step 1: Create PrestaShop cart (or reuse existing)
      final prestashopCartId = await createPrestashopCartForQR(cartProvider);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (prestashopCartId == null) {
        // Show error with retry option
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text('Impossible de créer le panier. Vérifiez votre connexion et réessayez.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showQRCodeDialog(context, cartProvider); // Retry
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Step 2: Save the active cart ID for later matching with paid orders
      await cartProvider.setActiveCartId(prestashopCartId);

      // Step 3: Generate simple QR data with cart_id + customer info
      final qrDataMap = generateSimpleQRData(prestashopCartId);
      final qrData = jsonEncode(qrDataMap);

      // Step 4: Show QR dialog with polling (using cart_id as session_id for Odoo)
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CartQRDialog(
            qrData: qrData,
            sessionId: prestashopCartId, // Use PrestaShop cart_id for polling
            cartProvider: cartProvider,
          
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Checkout method will be activated once the button is clicked
  Future<void> checkout(CartProvider cartProvider) async {
    double cartTotal = getTotalPrice(cartProvider);
    if (cartTotal < 20.0) {
      // Show alert if the total of the cart is less than 20 TND
      Get.snackbar(
        'Commande Non Valide',
        'Un montant total de 20,000 TND HT minimum est requis pour valider votre commande ',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      );
    } else {
      // When pressing the button, trigger this
      try {
        // Create Cart
        String cartId = await createCart(cartProvider.cartItems);

        // Navigate to Checkout Screen with the generated cartId
        Get.to(() => CheckoutScreen());
      } catch (e) {
        AlkLoggerHelper.error("Checkout failed", e);
      }
    }
  }

  // Send a POST request to create a cart
  Future<String> createCart(List<Map<String, String>> cartItems) async {
    String url =
        "https://www.alkirtas.com/api/carts?ws_key=${AppConfig.prestashopApiKey}";

    // Generate XML for cart rows
    String cartRowsXml = cartItems.map((item) {
      return """
    <cart_row>
      <id_product><![CDATA[${item['productId']}]]></id_product>
      <id_product_attribute><![CDATA[]]></id_product_attribute>
      <id_address_delivery><![CDATA[${AddressData.id}]]></id_address_delivery>
      <id_customization><![CDATA[]]></id_customization>
      <quantity><![CDATA[${item['productQuantity']}]]></quantity>
    </cart_row>
    """;
    }).join();

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

    // Send POST request
    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/xml",
        "Accept": "application/xml",
      },
      body: xmlBody.trim(),
    );

    // Parse response
    if (response.statusCode == 201 || response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final cartIdElement = document.findAllElements("id").first;
      return cartIdElement.text;
    } else {
      throw Exception(
          "${UserData.id} USER Failed to create cart: ${response.statusCode}, ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AlkAppBar(
        showBackArrow: false,
        title: Text('Panier', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.qr_code, size: 28),
              onPressed: () => showQRCodeDialog(context, cartProvider),
              tooltip: 'Afficher le QR Code',
            ),
        ],
      ),
      body: cartProvider.cartItems.isEmpty
          ? Center(
              child: Text(
                "Votre panier est vide",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AlkSize.defaultSpace),
                    child: ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: AlkSize.spaceBtwSections,
                      ),
                      itemCount: cartProvider.cartItems.length,
                      itemBuilder: (context, index) {
                        final product = cartProvider.cartItems[index];

                        // Calculate productOldPrice and productNewPrice dynamically
                        final discountValue =
                            double.tryParse(product['productDiscount'] ?? '0') ??
                                0.0;
                        final displayPrice = product['productPrice'] ?? '0';
                        final productOldPrice =
                            discountValue > 0 ? displayPrice : '';
                        final productNewPrice = discountValue > 0
                            ? (double.parse(displayPrice) *
                                    (1 - discountValue / 100))
                                .toStringAsFixed(2)
                            : displayPrice;

                        return GestureDetector(
                          onTap: () {
                            Get.to(() => ProductDetails(
                                  productId: product['productId'] ?? '',
                                  productName: product['productName'] ?? '',
                                  productReference:
                                      product['productReference'] ?? '',
                                  productDiscount:
                                      product['productDiscount'] ?? '',
                                  productBrand: product['productBrand'] ?? '',
                                  productBrandId:
                                      product['productBrandId'] ?? '',
                                  productImage: product['productImage'] ?? '',
                                  productImageList:
                                      product['productImageList']
                                              ?.split(',') ??
                                          [],
                                  productStock: product['productStock'] ?? '',
                                  productDescription:
                                      product['productDescription'] ?? '',
                                  productOldPrice:
                                      product['productOldPrice'] ?? '',
                                  productNewPrice:
                                      product['productNewPrice'] ?? '',
                                ));
                          },
                          child: AlkCartItem(
                            productName: product['productName']!,
                            productBrand: product['productBrand']!,
                            productImage: product['productImage']!,
                            productPrice: product['productPrice']!,
                            productQuantity: product['productQuantity']!,
                            onDelete: () async {
                              await cartProvider.removeFromCart(product['productId']!);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Price breakdown section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sous-total',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${getTotalPrice(cartProvider).toStringAsFixed(3)} TND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Delivery fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Livraison',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '9.000 TND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 10, thickness: 1),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AlkColors.AppSecColor,
                            ),
                          ),
                          Text(
                            '${getTotalPriceWithDelivery(cartProvider).toStringAsFixed(3)} TND',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AlkColors.AppSecColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AlkSize.defaultSpace),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        checkout(cartProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AlkColors.AppSecColor,
                        padding: EdgeInsets.symmetric(
                            vertical: AlkSize.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Commander ",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
