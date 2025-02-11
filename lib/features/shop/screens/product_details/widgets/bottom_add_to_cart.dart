import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/icons/circularIcons.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/providers/product_provider.dart';

import '../../cart/cart.dart';

class AlkBottomAddToCart extends StatelessWidget {
  final String productName;
  final String productBrand;
  final String productImage;
  final String productPrice;

  const AlkBottomAddToCart({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.productImage, 
    required this.productPrice,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Use GetX to retrieve ProductProvider
    final productProvider = Get.find<ProductProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AlkSize.defaultSpace, vertical: AlkSize.defaultSpace / 2),
      decoration: BoxDecoration(
        color: AlkColors.light,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AlkSize.cardRadiusLg),
          topRight: Radius.circular(AlkSize.cardRadiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AlkCircularIcon(
                icon: Iconsax.minus,
                size: 25,
                backgroundColor: Colors.purple,
                height: 40,
                width: 40,
                color: Colors.white,
              ),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text('1', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AlkSize.spaceBtwItems),
              AlkCircularIcon(
                icon: Iconsax.add,
                size: 25,
                backgroundColor: Colors.purple,
                height: 40,
                width: 40,
                color: Colors.white,
              ),
            ],
          ),
          ElevatedButton(
            
            onPressed: () {
              //  Use GetX to add product to cart
              productProvider.addToCart(
                productName: productName,
                productBrand: productBrand,
                productImage: productImage,
                productPrice: productPrice,
                
              );

              //  Show a GetX Snackbar
              Get.snackbar(
                "Ajouté au Panier",
                "$productName a été ajouté au panier, avec un prix de: $productPrice",
                snackPosition: SnackPosition.TOP,
              duration: Duration(seconds: 2),
              backgroundColor: Colors.purple.shade300,
              colorText: Colors.white,
              onTap: (snack) => Get.to(CartScreen()),
              isDismissible: true, 

              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(AlkSize.md),
              backgroundColor: AlkColors.primaryColor,
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text('Ajouter au Panier'),
          ),
        ],
      ),
    );
  }
}
