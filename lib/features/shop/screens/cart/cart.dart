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

import 'dart:convert';

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
    return getTotalPrice(cartProvider) + 8.0; // Delivery fee is fixed at 8.0 TND
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

                        return GestureDetector(
                          onTap: () {
                            Get.to(() => ProductDetails(
                                  productBrand: product['productBrand'] ?? '',
                                  productName: product['productName'] ?? '',
                                  productImage: product['productImage'] ?? '',
                                  productDiscount:
                                      product['productDiscount'] ?? '',
                                  productOldPrice:
                                      product['productOldPrice'] ?? '',
                                  productNewPrice:
                                      product['productNewPrice'] ?? '',
                                  productReference:
                                      product['productReference'] ?? '',
                                  productStock: product['productStock'] ?? '',
                                  productDescription:
                                      product['productDescription'] ?? '',
                                  productBrandId:
                                      product['productBrandId'] ?? '',
                                  productId: product['productId'] ?? '',
                                  productImageList:
                                      product['productImageList']?.split(',') ??
                                          [],
                                ));
                          },
                          child: AlkCartItem(
                            productName: product['productName']!,
                            productBrand: product['productBrand']!,
                            productImage: product['productImage']!,
                            productPrice: product['productPrice']!,
                            productQuantity: product['productQuantity']!,
                            onDelete: () {
                              cartProvider.removeFromCart(product['productId']!); // Use removeFromCart
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  "Total: ${getTotalPriceWithDelivery(cartProvider).toStringAsFixed(3)} TND (Livraison 8.000 TND)",
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
                        Get.to(() => CheckoutScreen());
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
