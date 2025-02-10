import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/products/cart/cartItem.dart';
import 'package:test/common/widgets/products/cart/add_remove_button.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/providers/product_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Retrieve ProductProvider using GetX
    final productProvider = Get.find<ProductProvider>();

    return Scaffold(
      appBar: AlkAppBar(
        showBackArrow: true,
        title: Text('Panier', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: productProvider.cartItems.isEmpty
          ? Center(
              child: Text(
                "Votre panier est vide",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(AlkSize.defaultSpace),
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (_, __) => const SizedBox(
                  height: AlkSize.spaceBtwSections,
                ),
                itemCount: productProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final product = productProvider.cartItems[index];

                  return Column(
                    children: [
                      AlkCartItem(
                        productName: product['productName']!,
                        productBrand: product['productBrand']!,
                        productImage: product['productImage']!,
                      ),
                      SizedBox(height: AlkSize.spaceBtwItems),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 70), // Extra space
                              AlkProductQuantityAddRemove(),
                            ],
                          ),
                          Text('Prix: 10 TND'), // Replace with actual price if needed
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
