import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/products/cart/cartItem.dart';
import 'package:test/features/shop/screens/product_details/widgets/product_features.dart';
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

  // Function to calculate total price
  double getTotalPrice() {
    return productProvider.cartItems.fold(0.0, (sum, product) {
      return sum + 8 + double.tryParse(product['productPrice'].toString())!;
    });
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
                            print(
                                "Raw productImageList: ${product['productImageList']}");

                            Get.to(() => ProductDetails(
                                  productBrand: product['productBrand']?? '',
                                  productName: product['productName']?? '',
                                  productImage: product['productImage']?? '',
                                  
                                  productDiscount: product['productDiscount']?? '',
                                  productOldPrice: product['productOldPrice']?? '',
                                  
                                  productNewPrice: product['productNewPrice']?? '',
                                  productReference: product['productReference']?? '',
                                  productStock: product['productStock']?? '',
                                  productDescription: product['productDescription']?? '',
                                  productBrandId: product['productBrandId']?? '',
                                  productId: product['productId']?? '',
                                  productImageList: product['productImageList']?.split(',') ?? [],
                                  //forced add 
                                   productFeatures: product['productFeatures']?.split(',') ?? [],
                                  
                                ));
                                print("product Features : ");
                          },
                          child: AlkCartItem(
                            productName: product['productName']!,
                            productBrand: product['productBrand']!,
                            productImage: product['productImage']!,
                            productPrice: product['productPrice']!,
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
                        // Implement order logic here
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
                              // fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Text(
                  " total: ${getTotalPrice().toStringAsFixed(3)} TND (Livraison 8.000 TND)",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AlkColors.darkGrey,
                      ),
                ),
              ],
            ),
    );
  }
}
