import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
            onPressed: onPressed, // Use the passed-in onPressed callback
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
                style: Theme.of(context).textTheme.labelLarge!.apply(
                    color: AlkColors.white, fontSizeFactor: 0.8),
              ),
            ),
          ),
        )
      ],
    );
  }
}

/// 1. Import the required libraries
/// 2. Create a personalized CartCounterIcon widget
/// 3. Retrieve the ProductProvider using GetX
/// 4. Show the number of items in the cart
/// 5. Use the onPressed callback to navigate to cart screen

 /// 1. Import the required libraries  
/// 2. Create a personalized CartCounterIcon widget
/// 3. Retrieve the ProductProvider using GetX  
/// 4. Show the number of items in the cart
/// 5. Show the CartScreen when the icon is pressed

