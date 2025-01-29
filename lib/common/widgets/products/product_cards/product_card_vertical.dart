import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/utils/helpers/helper_functions.dart';
import '../../../../features/shop/controllers/product_card_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../styles/shadows.dart';
import '../../roundedContainer.dart';

class AlkProductCardVertical extends StatefulWidget {
  final int productIndex; // Index of the product to fetch

  const AlkProductCardVertical({
    super.key,
    required this.productIndex,
  });

  @override
  State<AlkProductCardVertical> createState() => _AlkProductCardVerticalState();
}

class _AlkProductCardVerticalState extends State<AlkProductCardVertical> {
  final ProductCardControllerTax controller = ProductCardControllerTax();
  Map<String, dynamic>? productData; // To store product details
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductData(); // Fetch product data during initialization
  }

  Future<void> _loadProductData() async {
    final data = await controller.fetchProductData(widget.productIndex);
    setState(() {
      productData = data;
      isLoading = false;
    });
  }

  String _safeConvertToString(dynamic value, [String fallback = 'Unknown']) {
    if (value is String) return value;
    if (value is bool) return value ? 'True' : 'False';
    return value?.toString() ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productData == null) {
      return const Center(child: Text('Failed to load product'));
    }

    final title = _safeConvertToString(productData!['name']);
    final brandName = _safeConvertToString(productData!['manufacturer_name']);
    final rawTTCPrice = double.tryParse(_safeConvertToString(productData!['ttc_price'], '0.00'))?.toStringAsFixed(2) ?? '0.00';
    final discountData = productData!['discount'] as Map<String, dynamic>?;
    final taxRulesGroupId = productData!['id_tax_rules_group'] ?? 0;
    final rawPriceHT = double.tryParse(_safeConvertToString(productData!['price'], '0.00'))?.toStringAsFixed(2) ?? '0.00';
    final displayPrice = (taxRulesGroupId == 0) ? rawPriceHT : rawTTCPrice;


    // If id_tax_rules_group is 0, use original price, otherwise use TTC price




    // Calculate discount percentage
    String? discountText;
    if (discountData != null && discountData['reduction_type'] == 'percentage') {
      final discountValue = double.tryParse(discountData['reduction'] ?? '0') ?? 0;
      discountText = '${(discountValue * 100).toStringAsFixed(0)}%';
    } else if (discountData != null && discountData['reduction_type'] == 'amount') {
      discountText = 'Promo';
    }


    final imageUrl = controller.constructImageUrl(productData!['id_default_image']);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [AlkShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
          color: dark ? AlkColors.darkerGrey : AlkColors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent column overflow
          children: [
            // Product Thumbnail
            AlkRoundedContainer(
              height: 180,
              padding: const EdgeInsets.all(AlkSize.sm),
              backgroundColor: dark ? AlkColors.dark : AlkColors.white,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.image_not_supported));
                      },
                    ),
                  ),
                  // Discount Tag
                  if (discountText != null)
                    Positioned(
                      top: 1,
                      left: 1,
                      child: AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: AlkColors.secondary.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlkSize.sm,
                          vertical: AlkSize.xs,
                        ),
                        child: Text(
                          discountText,
                          style: Theme.of(context).textTheme.labelLarge!.apply(color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AlkSize.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                 
                    Text(
                      brandName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                     Text(
                      brandName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding:  EdgeInsets.only(left: AlkSize.sm),
                          child: Text(
                            
                            '$displayPrice TND',
                            style: Theme.of(context).textTheme.headlineSmall?.apply(color: AlkHelperFunctions.isDarkMode(context) ? AlkColors.white : AlkColors.black),
                            
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AlkColors.dark,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AlkSize.cardRadiusMd),
                              bottomRight: Radius.circular(AlkSize.productImageRadius),
                            ),
                          ),
                          child: SizedBox(
                            width: AlkSize.iconLg *1.2,
                            height: AlkSize.iconLg *1.2,
                            child: Center(
                              child: IconButton ( color: AlkColors.white, 
                              onPressed:(){},
                               icon: const Icon(Iconsax.add))
                            
                            ),
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
