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
import 'package:provider/provider.dart'; // Import Provider
import 'package:qr_flutter/qr_flutter.dart'; // Import QR Flutter

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

  // Generate QR code data from cart
  String generateCartQRData(CartProvider cartProvider) {
    final cartData = {
      'cartItems': cartProvider.cartItems.map((item) {
        // Only include essential data - Odoo will get name/brand from its database
        return {
          'productReference': item['productReference']?.toString() ?? '',
          'productPrice': item['productPrice']?.toString() ?? '0',
          'productQuantity': item['productQuantity']?.toString() ?? '1',
          'productDiscount': item['productDiscount']?.toString() ?? '0',
        };
      }).toList(),
      'totalPrice': getTotalPrice(cartProvider),
    };

    // Encode to JSON
    final jsonString = jsonEncode(cartData);

    // Log for debugging
    print('📦 QR Data Generated (Simplified):');
    print('   Items: ${cartProvider.cartItems.length}');
    print('   Total: ${getTotalPrice(cartProvider)}');
    if (cartProvider.cartItems.isNotEmpty) {
      final firstRef = cartProvider.cartItems[0]['productReference'] ?? 'N/A';
      print('   First Product Reference: $firstRef');
    }
    print('   JSON Length: ${jsonString.length} characters');
    print('   JSON: $jsonString');

    return jsonString;
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

  // Show QR code in a dialog
  void showQRCodeDialog(BuildContext context, CartProvider cartProvider) {
    final qrData = generateCartQRData(cartProvider);

    // Get screen size for responsive QR code
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final qrSize = (screenWidth * 0.5).clamp(200.0, 350.0);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
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
                          color: Colors.purple[700],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code with enhanced visibility - Clickable for fullscreen
                  GestureDetector(
                    onTap: () {
                      showFullscreenQR(context, qrData);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple[300]!,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple[100]!,
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: qrSize,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H, // Highest error correction
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
                                size: 20,
                                color: Colors.purple[600],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Appuyez pour agrandir',
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 32,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scannez ce code pour créer\nle panier dans le point de vente',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.purple[900],
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                              '${cartProvider.cartItems.length}',
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
                              '${getTotalPrice(cartProvider).toStringAsFixed(3)} TND',
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

        print("Cart placed successfully!");
      } catch (e) {
        print("Error during checkout: $e");
      }
    }
  }

  // Send a POST request to create a cart
  Future<String> createCart(List<Map<String, String>> cartItems) async {
    String url =
        "https://www.alkirtas.com/api/carts?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";

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
      body: xmlBody.trim(), // Ensure no extra spaces
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

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

    print("🛒 Cart Items in CartScreen:");
    for (var item in cartProvider.cartItems) {
      print(
          "Product ID: ${item['productId']}, Quantity: ${item['productQuantity']}, Price: ${item['productPrice']}");
    }

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
                Text(
                  "Total: ${getTotalPriceWithDelivery(cartProvider).toStringAsFixed(3)} TND (Livraison 9.000 TND)",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AlkColors.darkGrey,
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
                        backgroundColor: Colors.purple[400],
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
