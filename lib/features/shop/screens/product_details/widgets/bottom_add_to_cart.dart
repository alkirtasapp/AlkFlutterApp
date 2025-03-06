import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/icons/circularIcons.dart';
import 'package:test/features/shop/screens/product_details/product_details.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/common/widgets/providers/product_provider.dart';

import '../../cart/cart.dart';

class AlkBottomAddToCart extends StatefulWidget {
  final String productId;
  final String productName;
  final String productBrand;
  final String productImage;
  final String productPrice;
  final String productDiscount;
  final String productBrandId;
  final String productOldPrice;
  final String productNewPrice;
  final String productStock;
  final String productDescription;
  final String productReference;
  final List<String> productImageList;
  final List<String>? productFeatures;

  const AlkBottomAddToCart({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.productImage,
    required this.productPrice,
    required this.productDiscount,
    required this.productBrandId,
    required this.productOldPrice,
    required this.productNewPrice,
    required this.productStock,
    required this.productDescription, 
    required this.productReference,
    required this.productImageList, 
    required this.productFeatures, required this.productId,
  });

  @override
  _AlkBottomAddToCartState createState() => _AlkBottomAddToCartState();
}

class _AlkBottomAddToCartState extends State<AlkBottomAddToCart> {
  int quantity = 1; // Initial quantity

  void _increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _decreaseQuantity, // ✅ Dynamically update quantity
              ),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AlkSize.spaceBtwItems),
              AlkCircularIcon(
                icon: Iconsax.add,
                size: 25,
                backgroundColor: Colors.purple,
                height: 40,
                width: 40,
                color: Colors.white,
                onPressed: _increaseQuantity, // ✅ Dynamically update quantity
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              productProvider.addToCart(
                productId: widget.productId,
                productName: widget.productName,
                productBrand: widget.productBrand,
                productImage: widget.productImage,
                productPrice: widget.productPrice,
                productDiscount: widget.productDiscount,
                productBrandId: widget.productBrandId,
                productOldPrice: widget.productOldPrice,
                productNewPrice: widget.productNewPrice,
                productStock: widget.productStock,
                productDescription: widget.productDescription,
                productReference: widget.productReference,
                productImageList: widget.productImageList,
                productFeatures: widget.productFeatures,
                quantity: quantity, // ✅ Pass quantity to cart
              );

              Get.snackbar(
                "Ajouté au Panier",
                "${widget.productName} a été ajouté au panier en quantité: $quantity",
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
