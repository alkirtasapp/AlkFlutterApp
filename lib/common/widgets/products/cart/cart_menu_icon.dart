import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../features/shop/controllers/cart_provider.dart';
import '../../../../utils/constants/colors.dart';

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
    // Use Provider to listen to CartProvider
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed, // Navigate to the cart screen
          icon: Icon(Iconsax.shopping_bag, color: iconColor),
        ),
        Positioned(
          right: 0,
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final cartCount = cartProvider.cartItems.length;
              return Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AlkColors.AppSecColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    cartCount.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .apply(color: AlkColors.white, fontSizeFactor: 0.8),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

