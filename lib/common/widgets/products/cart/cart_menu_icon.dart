import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/features/shop/screens/cart/cart.dart';

import '../../../../utils/constants/colors.dart';
import '../../providers/product_provider.dart';

class AlkCartCounterIcon extends StatelessWidget {
  const AlkCartCounterIcon({
    super.key,
    required this.onPressed,
    this.iconColor = Colors.white,
  });

  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
     // Retrieve ProductProvider using GetX
    final productProvider = Get.find<ProductProvider>();
    return Stack(
      children: [
        IconButton(
            onPressed: () => Get.to(() => const CartScreen()),
            icon: Icon(Iconsax.shopping_bag, color: iconColor)),
        Positioned(
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AlkColors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
             
                productProvider.cartItems.length.toString(),  
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .apply(color: AlkColors.white, fontSizeFactor: 0.8),
              ),
            ),
          ),
        )
      ],
    );
  }
}
