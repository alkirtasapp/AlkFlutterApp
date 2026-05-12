import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/providers/wishlist_provider.dart';
import 'package:alkirtas/features/shop/screens/product_details/widgets/wishlist_hint_overlay.dart';
import 'package:alkirtas/common/widgets/images/AlkCircularImage.dart';
import 'package:alkirtas/common/widgets/roundedContainer.dart';
import 'package:alkirtas/common/widgets/texts/brand__title_text_verif_icon.dart';
import 'package:alkirtas/common/widgets/texts/product_title_text.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
import 'package:alkirtas/features/shop/screens/brand/brand_products_screen.dart';
import 'package:alkirtas/utils/constants/enums.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';

class AlkProductMetadata extends StatefulWidget {
  final String productId;
  final String productName;
  final String? productDiscount;
  final String productBrand;
  final String productOldPrice;
  final String productNewPrice;
  final String productBrandId;
  final String productImage;

  const AlkProductMetadata({
    super.key,
    required this.productId,
    required this.productName,
    this.productDiscount,
    required this.productBrand,
    required this.productOldPrice,
    required this.productNewPrice,
    required this.productBrandId,
    required this.productImage,
  });

  @override
  State<AlkProductMetadata> createState() => _AlkProductMetadataState();
}

class _AlkProductMetadataState extends State<AlkProductMetadata> {
  int? productStock;
  bool isLoadingStock = true;
  final GlobalKey _bellKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  Future<void> _fetchStock() async {
    final QuantityController quantityController = QuantityController();
    int? stock = await quantityController.fetchQuantity(int.parse(widget.productId));

    if (!mounted) return;
    setState(() {
      productStock = stock;
      isLoadingStock = false;
    });

    // One-time hint when user lands on an out-of-stock product
    if (stock != null && stock <= 0) {
      if (!await WishlistHint.alreadyShown() && mounted) {
        // Delay slightly so the page settles before the overlay appears
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) WishlistHint.show(context, _bellKey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        AlkProductTitleText(title: widget.productName, smallSize: false),
        SizedBox(height: AlkSize.spaceBtwItems),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Only show discount badge if discount exists and is not 0
            if (widget.productDiscount != null &&
                widget.productDiscount!.isNotEmpty &&
                widget.productDiscount != '0')
              AlkRoundedContainer(
                radius: AlkSize.sm,
                backgroundColor: AlkColors.AppSecColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AlkSize.sm,
                  vertical: AlkSize.xs,
                ),
                child: Text(
                  widget.productDiscount!.contains('%')
                      ? widget.productDiscount!
                      : '${widget.productDiscount}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .apply(color: Colors.white),
                ),
              ),
            if (widget.productDiscount != null &&
                widget.productDiscount!.isNotEmpty &&
                widget.productDiscount != '0')
              SizedBox(width: AlkSize.spaceBtwItems),

            // Only show old price with strikethrough if discount exists
            if (widget.productDiscount != null &&
                widget.productDiscount!.isNotEmpty &&
                widget.productDiscount != '0')
              Text(
                '${widget.productOldPrice} TND',
                style: Theme.of(context).textTheme.titleSmall!.apply(
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
            if (widget.productDiscount != null &&
                widget.productDiscount!.isNotEmpty &&
                widget.productDiscount != '0')
              SizedBox(width: AlkSize.spaceBtwItems),

            // Price display (always shown)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               // Icon(Iconsax.coin1, color: Colors.purple.shade300, size: 25),
                Text(
                  '${widget.productNewPrice}  TND',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .apply(color: AlkColors.darkerGrey),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: AlkSize.spaceBtwItems),

        // Stock + Price Alert bell — same row
        Row(
          children: [
            // Stock badge
            isLoadingStock
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (productStock != null && productStock! > 0
                    ? AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: Colors.green.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlkSize.sm,
                          vertical: AlkSize.xs,
                        ),
                        child: const Text(
                          'En Stock',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : AlkRoundedContainer(
                        radius: AlkSize.sm,
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlkSize.sm,
                          vertical: AlkSize.xs,
                        ),
                        child: const Text(
                          'Hors Stock',
                          style: TextStyle(color: Colors.white),
                        ),
                      )),

            const Spacer(),

            // Bell icon — wishlist toggle (price drop + stock comeback)
            Consumer<WishlistProvider>(
              builder: (context, provider, _) {
                final watched = provider.isWatched(widget.productId);
                final effectivePrice = (widget.productDiscount != null &&
                        widget.productDiscount!.isNotEmpty &&
                        widget.productDiscount != '0')
                    ? double.tryParse(widget.productNewPrice) ?? 0.0
                    : double.tryParse(widget.productOldPrice.isNotEmpty
                            ? widget.productOldPrice
                            : widget.productNewPrice) ??
                        0.0;

                return GestureDetector(
                  key: _bellKey,
                  onTap: () async {
                    if (watched) {
                      await provider.removeItem(widget.productId);
                      Get.snackbar(
                        'Retiré de la liste',
                        'Vous ne serez plus notifié pour ${widget.productName}',
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      if (effectivePrice <= 0) return;
                      await provider.addItem(
                        productId: widget.productId,
                        productName: widget.productName,
                        imageUrl: widget.productImage,
                        effectivePrice: effectivePrice,
                        taxRulesGroupId: 0,
                        currentStock: productStock ?? 0,
                      );
                      Get.snackbar(
                        'Ajouté à votre liste',
                        'Vous serez notifié si le prix baisse ou si ce produit revient en stock',
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      watched
                          ? Iconsax.notification_bing5
                          : Iconsax.notification_bing,
                      key: ValueKey(watched),
                      color: watched ? Colors.amber.shade600 : AlkColors.darkerGrey,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        SizedBox(height: AlkSize.spaceBtwItems / 2),

        // Brand (tappable — navigates to brand products screen)
        GestureDetector(
          onTap: () {
            final brandId = int.tryParse(widget.productBrandId) ?? 0;
            if (brandId > 0) {
              Get.to(() => BrandProductsScreen(
                brandId: brandId,
                brandName: (widget.productBrand == 'False' || widget.productBrand == 'false' || widget.productBrand.isEmpty)
                    ? 'A L K I R T A S'
                    : widget.productBrand,
              ));
            }
          },
          child: Row(
            children: [
              widget.productBrandId != '0'
                  ? AlkCircularImage(
                      image:
                          'https://www.alkirtas.com/img/m/${widget.productBrandId}.jpg',
                      backgroundColor: Colors.transparent,
                      isNetworkImage: true,
                      fit: BoxFit.contain,
                    )
                  : AlkCircularImage(
                      isNetworkImage: false,
                      image: AlkImages.darkAppLogo,
                      width: 52,
                      height: 52,
                      overlayColor: AlkColors.AppSecColor,
                    ),
              Expanded(
                child: AlkBrandTitleTextVerifIcon(
                  title: (widget.productBrand == 'False' || widget.productBrand == 'false' || widget.productBrand.isEmpty)
                      ? 'A L K I R T A S'
                      : widget.productBrand,
                  brandTextSize: TextSizes.medium,
                ),
              ),
              if ((int.tryParse(widget.productBrandId) ?? 0) > 0)
                Icon(Iconsax.arrow_right_3, size: 18, color: AlkColors.darkerGrey),
              SizedBox(height: AlkSize.spaceBtwSections),
            ],
          ),
        ),
      ],
    );
  }
}
