// d:\flutter\test\lib\common\widgets\products\product_cards\category_product_card.dart (Updated with Caching)
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:provider/provider.dart';
import '../../../../features/shop/controllers/category_product_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../styles/shadows.dart';
import '../../roundedContainer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;

  const CategoryProductCard({
    super.key,
    required this.productData,
  });

  // Helper methods (Unchanged)
  String _getString(String key, [String fallback = '']) {
    return productData[key]?.toString() ?? fallback;
  }

  double _getDouble(String key, [double fallback = 0.0]) {
    final value = productData[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  List<String> _getStringList(String key) {
    final value = productData[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  @override
  Widget build(BuildContext context) {
    // Data extraction 
    final title = _getString('name', 'No Name');
    final id = _getString('id');
    final reference = _getString('reference');
    final brandName = _getString('manufacturer_name', 'A L K I R T A S');
    final descriptionShort = CategoryProductController.cleanDescription(
        _getString('description_short'));
    final brandId = _getString('id_manufacturer');
    final productStock = _getString('quantity');
    final List<String> imageList = _getStringList('image_urls');
    final imageUrl = _getString(
        'default_image_url', 'https://via.placeholder.com/150?text=No+Image');

    final double ttcPrice = _getDouble('ttc_price');
    final double priceHT = _getDouble('price');
    final int taxRulesGroupId =
        int.tryParse(_getString('id_tax_rules_group', '0')) ?? 0;

    final displayPriceValue = (taxRulesGroupId == 0) ? priceHT : ttcPrice;
    final displayPrice = displayPriceValue.toStringAsFixed(2);

    final double discountValue = _getDouble('discount');

    String? discountText;
    if (discountValue > 0) {
      discountText = '${discountValue.toStringAsFixed(0)}%';
    }

    final double finalPriceValue = discountValue > 0
        ? (displayPriceValue * (1 - discountValue / 100))
        : displayPriceValue;
    final finalPrice = finalPriceValue.toStringAsFixed(2);

    final dark = AlkHelperFunctions.isDarkMode(context);

    // Check if product is in stock by parsing the productStock string
    final int? realStock = int.tryParse(productStock);
    final bool isInStock = realStock != null && realStock > 0;




    // Widget Structure (GestureDetector, Container, Column are unchanged)
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetails(
            // ... (unchanged parameters)
            productId: id,
            productName: title,
            productReference: reference,
            productDiscount: discountText ?? '',
            productBrand: brandName == 'False' ? 'A L K I R T A S ' : brandName,
            productBrandId: brandId,
            productImage: imageUrl,
            productImageList: imageList,
            productStock: productStock,
            productDescription: descriptionShort,
            productOldPrice: discountText != null ? displayPrice : '',
            productNewPrice: finalPrice,
          )),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [AlkShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
          color: dark ? AlkColors.darkerGrey : AlkColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Container ---
            AlkRoundedContainer(
              height: 160,
              padding: const EdgeInsets.all(AlkSize.sm),
              backgroundColor: dark ? AlkColors.dark : AlkColors.light,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- Image with Caching ---
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AlkSize.productImageRadius),
                    // *** Replace Image.network with CachedNetworkImage ***
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      // Show a placeholder while loading
                      placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      // Show an error icon if loading fails
                      errorWidget: (context, url, error) {
                        print("Error loading cached image $url: $error");
                        return const Center(
                            child: Icon(Icons.broken_image,
                                color: AlkColors.grey, size: 40));
                      },
                    ),
                  ),
                  // --- Discount Tag (Unchanged) ---
                  if (discountText != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: Colors.purple.shade300, // Use theme color
                        padding: const EdgeInsets.symmetric(
                            horizontal: AlkSize.sm, vertical: AlkSize.xs),
                        child: Text(discountText,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .apply(color: AlkColors.white)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwItems / 2),

            // --- Details Section (Unchanged) ---
            Padding(
              padding: const EdgeInsets.only(left: AlkSize.sm, right: AlkSize.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AlkSize.spaceBtwItems / 4),
                  Text(brandName == 'false' ? 'A L K I R T A S ' : brandName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AlkSize.spaceBtwItems * 1.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discountText != null)
                            Text('$displayPrice TND',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AlkColors.darkGrey)),
                          Text('$finalPrice TND',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isInStock ? AlkColors.primaryColor : AlkColors.grey,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AlkSize.cardRadiusMd),
                              bottomRight: Radius.circular(
                                  AlkSize.productImageRadius)),
                        ),
                        child: SizedBox(
                          width: AlkSize.iconLg *1.2,
                          height: AlkSize.iconLg *1.2,
                          child: Center(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: AlkSize.iconMd,                              
                              color: isInStock ? AlkColors.white : AlkColors.grey,
                              onPressed: isInStock
                                  ? () {
                                      final cartProvider =
                                          Provider.of<CartProvider>(context,
                                              listen: false);
                                      cartProvider.addToCart(
                                        productId: id,
                                        productName: title,
                                        productBrand: brandName,
                                        productImage: imageUrl,
                                        productPrice: finalPrice,
                                        productDiscount: discountText ?? '',
                                        productBrandId: brandId,
                                        productOldPrice: discountText != null
                                            ? displayPrice
                                            : '',
                                        productNewPrice: finalPrice,
                                        productStock: productStock, // Use the original string
                                        productDescription: descriptionShort,
                                        productReference: reference,
                                        productImageList: imageList,
                                        productFeatures: [],
                                        quantity: 1,
                                      );
                                      Get.snackbar("Produit ajouté",
                                          "$title a été ajouté au panier.",
                                          snackPosition: SnackPosition.TOP,
                                          isDismissible: true,
                                          dismissDirection: DismissDirection.horizontal,
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: Colors.purple.shade300,
                                          colorText: AlkColors.white,
                                          margin: const EdgeInsets.all(10),
                                          borderRadius: 8);
                                    }
                                  : null,
                              icon: const Icon(Iconsax.add),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlkSize.sm),
          ],
        ),
      ),
    );
  }
}
