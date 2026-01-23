import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../../../features/shop/controllers/product_controller_store.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../styles/shadows.dart';
import '../../roundedContainer.dart';

class ProductCardStore extends StatelessWidget {
  final int categoryId;
  final int productIndex;
  final Map<dynamic, dynamic> productData; // Accepts all key-value types

  const ProductCardStore({
    super.key,
    required this.categoryId,
    required this.productIndex,
    required this.productData,
  });

  String _safeConvertToString(dynamic value, [String fallback = 'Unknown']) {
    if (value is String) return value;
    if (value is bool) return value ? 'True' : 'False';
    return value?.toString() ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final id = _safeConvertToString(productData['id']);
    final reference = _safeConvertToString(productData['reference']);
    final title = _safeConvertToString(productData['name']);
    final List<String> imageList =
        (productData['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final Map<String, String> productFeatures = productData['details_table'] != null
        ? Map<String, String>.from(
            (productData['details_table'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          )
        : {};

    final productStock = _safeConvertToString(productData['quantity']);
    final brandName = _safeConvertToString(productData['manufacturer_name']);
    final brandId = _safeConvertToString(productData['id_manufacturer']);
    final description = _safeConvertToString(productData['description_short']);
    final rawTTCPrice =
        double.tryParse(_safeConvertToString(productData['ttc_price'], '0.00'))
                ?.toStringAsFixed(2) ?? '0.00';
    final taxRulesGroupId = productData['id_tax_rules_group'] ?? 0;
    final rawPriceHT =
        double.tryParse(_safeConvertToString(productData['price'], '0.00'))
                ?.toStringAsFixed(2) ?? '0.00';
    final displayPrice = (taxRulesGroupId == 0) ? rawPriceHT : rawTTCPrice;

    final double discountValue =
        (productData['discount'] as num?)?.toDouble() ?? 0;

    String? discountText;
    if (discountValue > 0) {
      discountText = '${discountValue.toStringAsFixed(0)}%';
    }
    final imageUrl =
        ProductControllerStore().constructImageUrl(productData['id_default_image']);
    final dark = Theme.of(context).brightness == Brightness.dark;

      // Check if product is in stock by parsing the productStock string
    final int? realStock = int.tryParse(productStock);
    final bool isInStock = realStock != null && realStock > 0;


    return GestureDetector(
      onTap: () => Get.to(() => ProductDetails(
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
            AlkRoundedContainer(
              height: 180,
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
                  if (discountText != null)
                    Positioned(
                      top: 1,
                      left: 1,
                      child: AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: AlkColors.AppSecColor,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AlkSize.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      brandName == 'False' ? 'A L K I R T A S' : brandName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
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
                            color: isInStock ? AlkColors.AppFirstColor : AlkColors.grey,
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
                                    color:isInStock ? AlkColors.white : AlkColors.grey,
                                    onPressed:isInStock? () {
                                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                        cartProvider.addToCart(
                                            productId: id,
                                            productName: title,
                                            productBrand: brandName,
                                            productImage: imageUrl,
                                            productPrice: discountValue > 0
                                                ? (double.parse(displayPrice) * (1 - discountValue / 100))
                                                    .toStringAsFixed(2)
                                                : displayPrice,
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
                                            productFeatures: [],
                                            quantity: 1,
                                        );
                                        
                                        Get.snackbar(
                                            "Produit ajouté",
                                            "$title a été ajouté au panier.",
                                            snackPosition: SnackPosition.TOP,
                                            isDismissible: true,
                                            dismissDirection: DismissDirection.horizontal,
                                            duration: const Duration(seconds: 2),
                                            backgroundColor: AlkColors.AppSecColor,
                                            colorText: AlkColors.white,
                                            margin: const EdgeInsets.all(10),
                                            borderRadius: 8
                                        );
                                    }:null,
                                    icon: const Icon(Iconsax.add),
                                )),
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

/// same documentation for ProductCardVertical
