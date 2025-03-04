import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/products/cart/cartItem.dart';
import 'package:test/features/shop/screens/product_details/product_details.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/providers/product_provider.dart';
import 'package:test/utils/backendData/userData.dart';
import 'package:test/utils/backendData/addressData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final productProvider = Get.find<ProductProvider>();

  double getTotalPrice() {
    return productProvider.cartItems.fold(0.0, (sum, product) {
      final price = double.tryParse(product['productPrice'].toString()) ?? 0.0;
      final quantity = int.tryParse(product['productQuantity'].toString()) ?? 1;
      return sum + (price * quantity);
    }) + 8.0; // Add delivery charge (8.000 TND)
  }

  Future<void> checkout() async {
    try {
      // Step 1: Create Cart
      String cartId = await createCart(productProvider.cartItems);

      // Step 2: Create Order using the generated cart ID
      await createOrder(cartId);

      // Step 3: Clear Local Cart
      productProvider.clearCart();

      print("Order placed successfully!");
    } catch (e) {
      print("Error during checkout: $e");
    }
  }

  Future<String> createCart(List<Map<String, String>> cartItems) async {
    String url = "https://www.alkirtas.com/api/carts?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
    
    String cartRowsXml = cartItems.map((item) {
      return """
      <cart_row>
        <id_product>${item['productId']}</id_product>
        <id_product_attribute><![CDATA[]]></id_product_attribute>
        <id_address_delivery>${AddressData.id}</id_address_delivery>
        <id_customization><![CDATA[]]></id_customization>
        <quantity>${item['productQuantity']}</quantity>
      </cart_row>
      """;
    }).join();

    String xmlBody = """
    <?xml version="1.0" encoding="UTF-8"?>
    <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
      <cart>
        <id_currency>1</id_currency>
        <id_lang>1</id_lang>
        <id_customer>${UserData.id}</id_customer>
        <associations>
          <cart_rows>
            $cartRowsXml
          </cart_rows>
        </associations>
      </cart>
    </prestashop>
    """;
    
    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/xml",
      },
      body: xmlBody,
    );
    
    if (response.statusCode == 201) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse["cart"]["id"].toString();
    } else {
      throw Exception("Failed to create cart: ${response.statusCode}, ${response.body}");
    }
  }

  Future<void> createOrder(String cartId) async {
    // Implement order creation logic using the cartId
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlkAppBar(
        showBackArrow: false,
        title: Text('Panier', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: productProvider.cartItems.isEmpty
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
                      itemCount: productProvider.cartItems.length,
                      itemBuilder: (context, index) {
                        final product = productProvider.cartItems[index];

                        return GestureDetector(
                          onTap: () {
                            Get.to(() => ProductDetails(
                                  productBrand: product['productBrand'] ?? '',
                                  productName: product['productName'] ?? '',
                                  productImage: product['productImage'] ?? '',
                                  productDiscount: product['productDiscount'] ?? '',
                                  productOldPrice: product['productOldPrice'] ?? '',
                                  productNewPrice: product['productNewPrice'] ?? '',
                                  productReference: product['productReference'] ?? '',
                                  productStock: product['productStock'] ?? '',
                                  productDescription: product['productDescription'] ?? '',
                                  productBrandId: product['productBrandId'] ?? '',
                                  productId: product['productId'] ?? '',
                                  productImageList: product['productImageList']?.split(',') ?? [],
                                  productFeatures: product['productFeatures']?.split(',') ?? [],
                                ));
                          },
                          child: AlkCartItem(
                            productName: product['productName']!,
                            productBrand: product['productBrand']!,
                            productImage: product['productImage']!,
                            productPrice: product['productPrice']!,
                            productQuantity: product['productQuantity']!, // Display correct quantity
                            onDelete: () {
                              setState(() {}); // Trigger rebuild on delete
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AlkSize.defaultSpace),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(
                            vertical: AlkSize.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Commander ",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Total: ${getTotalPrice().toStringAsFixed(3)} TND (Livraison 8.000 TND)",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AlkColors.darkGrey,
                      ),
                ),
                const SizedBox(height: AlkSize.spaceBtwSections),
              ],
            ),
    );
  }
}