import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/features/shop/screens/cart/cart.dart';
import 'package:test/features/shop/screens/product_details/product_details.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/images/AlkRoundedImages.dart';
import 'package:test/common/widgets/texts/brand__title_text_verif_icon.dart';
import 'package:test/common/widgets/texts/product_title_text.dart';
import 'package:test/common/widgets/providers/product_provider.dart';

class AlkCartItem extends StatelessWidget {
  final String productName;
  final String productBrand;
  final String productImage;
  final String productPrice;
  final VoidCallback? onDelete; // Callback for delete action
  final String productQuantity;

  const AlkCartItem({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.productImage,
    required this.productPrice,
    this.onDelete, 
    required this.productQuantity,
  });

  @override
  Widget build(BuildContext context) {
  //  print("AlkCartItem - productPrice: $productPrice");

    final productProvider = Get.find<ProductProvider>();

    return Row(
      children: [
        // Product Image
        AlkRoundedImage(
          imageUrl: productImage,
          width: 75,
          height: 75,
          padding: EdgeInsets.all(AlkSize.sm),
          backgroundColor: AlkColors.light,
          applyImageRadius: true,
          
         

        ),
        const SizedBox(width: AlkSize.spaceBtwItems),

        // Product Details (Brand, Name, Price)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlkBrandTitleTextVerifIcon(title: productBrand ),
              Flexible(
                child: AlkProductTitleText(
                  title: productName,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 5),
              // Product Price
              Text(
                "${productPrice.toString()} TND      x$productQuantity",
                style: TextStyle(
                 
                  color: AlkColors.dark,
                ),
              ),
            /*  //const SizedBox(width: 10),
                  Text(
                    "x$productQuantity", // ✅ Show quantity next to price
                   style: TextStyle(
                 
                  color: AlkColors.dark,
                ),
            )*/  ],
          ),
        ),

        // Delete Button
        IconButton(
          icon: Icon(Icons.delete_outlined, color: Colors.purple.shade300),
          onPressed: () {
            productProvider.removeFromCart(productName);

            // Show confirmation
            Get.snackbar(
              "Supprimé",
              "$productName a été retiré du panier",
              snackPosition: SnackPosition.TOP,
              duration: Duration(seconds: 2),
              backgroundColor: Colors.purple.shade300,
              colorText: Colors.white,
              isDismissible: true, 
              
            );

            // Trigger the callback to notify the parent widget
            if (onDelete != null) {
              onDelete!();
            }
          },
        ),
      ],
    );
  }
}
