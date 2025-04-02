import 'dart:ffi';

import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/backendData/productDetailData.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:provider/provider.dart';
import '../../../../features/shop/controllers/product_card_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../styles/shadows.dart';
import '../../roundedContainer.dart';

class AlkProductCardVertical extends StatefulWidget {
  // Index of the product to fetch
  final int productIndex;

  const AlkProductCardVertical({
    super.key,
    required this.productIndex,
  });

  @override
  State<AlkProductCardVertical> createState() => _AlkProductCardVerticalState();
}

class _AlkProductCardVerticalState extends State<AlkProductCardVertical> {
  final ProductCardControllerTax controller = ProductCardControllerTax();
  // To store product details
  Map<String, dynamic>? productData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch product data during initialization
    _loadProductData();
  }

  // Fetch product data using the controller
  Future<void> _loadProductData() async {
    final data = await controller.fetchProductData(widget.productIndex);
    setState(() {
      productData = data;
      isLoading = false;
    });
  }

  // Convert the value to a string
  String _safeConvertToString(dynamic value, [String fallback = 'Unknown']) {
    if (value is String) return value;
    if (value is bool) return value ? 'True' : 'False';
    return value?.toString() ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Show a loading indicator while fetching data
      return const Center(child: CircularProgressIndicator());
    }
    // Show an error message if the product data is not available
    if (productData == null) {
      return const Center(child: Text('Failed to load product'));
    }

    // Fetch product details
    final title = _safeConvertToString(productData!['name']);
    final id = _safeConvertToString(productData!['id']);
    final reference = _safeConvertToString(productData!['reference']);
    final brandName = _safeConvertToString(productData!['manufacturer_name']);
    final description = _safeConvertToString(productData!['description_short']);
    final brandId = _safeConvertToString(productData!['id_manufacturer']);
    final productStock = _safeConvertToString(productData!['quantity']);
    final List<String> imageList =
        (productData!['image_urls'] as List<dynamic>).cast<String>();

    final rawTTCPrice =
        double.tryParse(_safeConvertToString(productData!['ttc_price'], '0.00'))
                ?.toStringAsFixed(2) ??
            '0.00';

    final taxRulesGroupId = productData!['id_tax_rules_group'] ?? 0;
    final rawPriceHT =
        double.tryParse(_safeConvertToString(productData!['price'], '0.00'))
                ?.toStringAsFixed(2) ??
            '0.00';
    final displayPrice = (taxRulesGroupId == 0) ? rawPriceHT : rawTTCPrice;

    // Ensure the discount is always a double
    final double discountValue =
        (productData!['discount'] as num?)?.toDouble() ?? 0;

    String? discountText;
    if (discountValue > 0) {
      discountText = '${discountValue.toStringAsFixed(0)}%';
      print(
          'Displaying discount for product ${productData!['id']}: $discountText');
    } else {
      print('No discount to display for product ${productData!['id']}');
    }

    final imageUrl =
        controller.constructImageUrl(productData!['id_default_image']);

    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetails(
            // Show the ProductDetails screen when the card is tapped

            productId: id,
            productName: title,
            productReference: reference,
            productDiscount: discountText ?? '',
            productBrand: brandName,
            productBrandId: brandId,
            productImage: imageUrl,
            productImageList: imageList,
            productStock: productStock,

            productDescription: description,
            productOldPrice: discountText != null ? displayPrice : '',
            productNewPrice: discountValue > 0
                ? (double.parse(displayPrice) * (1 - discountValue / 100))
                    .toStringAsFixed(2)
                : displayPrice,
          )),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [AlkShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
          color: dark ? AlkColors.darkerGrey : AlkColors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Thumbnail
            AlkRoundedContainer(
              height: 160,
              padding: const EdgeInsets.all(AlkSize.sm),
              backgroundColor: dark ? AlkColors.dark : AlkColors.white,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AlkSize.productImageRadius),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                            child: Icon(Icons.image_not_supported));
                      },
                    ),
                  ),

                  /// Discount Tag
                  if (discountText != null)
                    Positioned(
                      top: 1,
                      left: 1,
                      child: AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: Colors.purple.shade300,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlkSize.sm,
                          vertical: AlkSize.xs,
                        ),
                        child: Text(
                          discountText,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .apply(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AlkSize.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Product Title
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      // Product Brand
                      brandName != 'False' ? brandName : 'A L K I R T A S ',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),

                    ///original price mfassa5
                    Text(
                      discountText != null ? '$displayPrice TND' : '',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AlkColors.black),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: AlkSize.sm),

                          /// prix ken fama discount
                          child: Text(
                            discountValue > 0
                                ? '${(double.parse(displayPrice) * (1 - discountValue / 100)).toStringAsFixed(2)} TND'
                                : '$displayPrice TND',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.apply(
                                    color:
                                        AlkHelperFunctions.isDarkMode(context)
                                            ? AlkColors.white
                                            : AlkColors.black),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AlkColors.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AlkSize.cardRadiusMd),
                              bottomRight:
                                  Radius.circular(AlkSize.productImageRadius),
                            ),
                          ),
                          child: SizedBox(
                            width: AlkSize.iconLg * 1.2,
                            height: AlkSize.iconLg * 1.2,
                            child: Center(
                                child: IconButton(
                                    color: AlkColors.white,
                                    onPressed: () {
                                      final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                      cartProvider.addToCart(
                                        productId: id,
                                        productName: title,
                                        productBrand: brandName,
                                        productImage: imageUrl,
                                        productPrice: displayPrice,
                                        productDiscount: discountText ?? '',
                                        productBrandId: brandId,
                                        productOldPrice: discountText != null ? displayPrice : '',
                                        productNewPrice: discountValue > 0
                                            ? (double.parse(displayPrice) * (1 - discountValue / 100))
                                                .toStringAsFixed(2)
                                            : displayPrice,
                                        productStock: productStock,
                                        productDescription: description,
                                        productReference: reference,
                                        productImageList: imageList,
                                        productFeatures: [], // Add features if available
                                        quantity: 1, // Default quantity
                                      );

                                      Get.snackbar(
                                        "Produit ajouté",
                                        "$title a été ajouté au panier",
                                        snackPosition: SnackPosition.TOP,
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    },
                                    icon: const Icon(Iconsax.add))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Import the required libraries
///  Create a personalized ProductCardVertical widget
/// Fetch product data using the ProductCardController
/// Display the product details
/// Show the ProductDetails screen when the card is tapped
/// Show the discount tag if available
/// Show the original and discounted prices
/// Add the product to the cart when the add icon is pressed
/// Show the add icon and the product price
/// Show the product image, title, brand, and price
/// Show a loading indicator while fetching data
/// Show an error message if the product data is not available
/// aaplied on both products on HomeScreen and StoreDrawer
