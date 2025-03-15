import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/icons/circularIcons.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart'; // Import QuantityController

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
    required this.productFeatures,
    required this.productId,
  });

  @override
  _AlkBottomAddToCartState createState() => _AlkBottomAddToCartState();
}

class _AlkBottomAddToCartState extends State<AlkBottomAddToCart> {
  int quantity = 1; // Initial quantity
  int? productStock; // To store the fetched stock
  bool isLoadingStock = true; // Initially loading

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  // Function to fetch the stock
  Future<void> _fetchStock() async {
    final QuantityController quantityController = QuantityController();
    int? stock = await quantityController.fetchQuantity(int.parse(widget.productId));

    setState(() {
      productStock = stock;
      isLoadingStock = false;
    });
  }

  void _increaseQuantity() {
    // Only increase if there's stock available and the current quantity doesn't exceed the available stock
    if (productStock != null && productStock! > 0 && quantity < productStock!) {
      setState(() {
        quantity++;
      });
    }
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
    // If loading, show a loading indicator
    if (isLoadingStock) {
      return Container(
          height: 100,
          child: Center(child: CircularProgressIndicator())); // Or any loading indicator
    }

    // Check if product is in stock based on the fetched stock
    bool isInStock = productStock != null && productStock! > 0;

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
                backgroundColor: Colors.purple[400],
                height: 40,
                width: 40,
                color: Colors.white,
                onPressed: _decreaseQuantity,
              ),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AlkSize.spaceBtwItems),
              AlkCircularIcon(
                icon: Iconsax.add,
                size: 25,
                backgroundColor: Colors.purple[400],
                height: 40,
                width: 40,
                color: Colors.white,
                onPressed: _increaseQuantity,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: isInStock
                ? () {
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
                      productStock: productStock.toString(), // Use fetched stock
                      productDescription: widget.productDescription,
                      productReference: widget.productReference,
                      productImageList: widget.productImageList,
                      productFeatures: widget.productFeatures,
                      quantity: quantity,
                    );

                    Get.snackbar(
                      "Ajouté au Panier",
                      "${widget.productName} a été ajouté au panier en quantité: $quantity",
                      snackPosition: SnackPosition.TOP,
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.purple.shade300,
                      colorText: Colors.white,
                      onTap: (snack) => Get.to(() => CartScreen()),
                      isDismissible: true,
                    );
                  }
                : null, // Disable button when out of stock
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(AlkSize.md),
              backgroundColor: isInStock ? Colors.purple[400] : Colors.grey,
              side: const BorderSide(color: Colors.grey),
            ),
            child: Text(isInStock ? 'Ajouter au Panier' : 'Rupture de stock',style: Theme.of(context).textTheme.titleMedium!.apply(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}
