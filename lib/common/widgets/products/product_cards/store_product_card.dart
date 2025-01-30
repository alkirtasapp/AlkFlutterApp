import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/utils/helpers/helper_functions.dart';
import '../../../../features/shop/controllers/product_controller_store.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../styles/shadows.dart';
import '../../roundedContainer.dart';

class ProductCardStore extends StatefulWidget {
  final int categoryId; // Category ID to fetch products from
  final int productIndex; // Index of the product to fetch

  const ProductCardStore({
    super.key,
    required this.categoryId,
    required this.productIndex,
  });

  @override
  State<ProductCardStore> createState() => _ProductCardStoreState();
}

class _ProductCardStoreState extends State<ProductCardStore> {
  final ProductControllerStore controller = ProductControllerStore();
  Map<String, dynamic>? productData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    final products = await controller.fetchRandomProducts();
    if (products.isNotEmpty) {
      setState(() {
  final int validIndex = widget.productIndex % products.length;
  productData = products[validIndex] as Map<String, dynamic>?; // Explicit casting
  isLoading = false;
});
    } else {
      setState(() {
        isLoading = false;
      });
    }
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
    final rawPrice = _safeConvertToString(productData!['price'], '0.00');
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Thumbnail
            AlkRoundedContainer(
              height: 180,
              padding: const EdgeInsets.all(AlkSize.sm),
              backgroundColor: dark ? AlkColors.dark : AlkColors.white,
              child: ClipRRect(
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
            ),

            // Product Details
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
                      brandName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: AlkSize.sm),
                          child: Text(
                            '$rawPrice TND',
                            style: Theme.of(context).textTheme.headlineSmall?.apply(
                              color: AlkHelperFunctions.isDarkMode(context)
                                  ? AlkColors.white
                                  : AlkColors.black,
                            ),
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
                            width: AlkSize.iconLg * 1.2,
                            height: AlkSize.iconLg * 1.2,
                            child: Center(
                              child: IconButton(
                                color: AlkColors.white,
                                onPressed: () {},
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
            ),
          ],
        ),
      ),
    );
  }
}
