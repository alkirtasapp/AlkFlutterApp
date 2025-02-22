import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/products/cart/cartItem.dart';
import 'package:test/features/shop/screens/checkout/checkout.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/providers/product_provider.dart';
import '../../../../utils/constants/colors.dart';
import '../product_details/product_details.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Retrieve ProductProvider using GetX
  final productProvider = Get.find<ProductProvider>();

  // ✅ Updated: Function to calculate total price with quantity consideration
  double getTotalPrice() {
    return productProvider.cartItems.fold(0.0, (sum, product) {
      final price = double.tryParse(product['productPrice'].toString()) ?? 0.0;
      final quantity = int.tryParse(product['productQuantity'].toString()) ?? 1; // ✅ Ensure quantity is considered
      return sum + (price * quantity);
    }) + 8.0; // ✅ Add delivery charge (8.000 TND)
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
                            productQuantity: product['productQuantity']!, // ✅ Display correct quantity
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
                      onPressed: () {
                        Get.to(() => CheckoutScreen());
                      },
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
