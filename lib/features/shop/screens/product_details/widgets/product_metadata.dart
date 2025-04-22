import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/images/AlkCircularImage.dart';
import 'package:alkirtas/common/widgets/roundedContainer.dart';
import 'package:alkirtas/common/widgets/texts/brand__title_text_verif_icon.dart';
import 'package:alkirtas/common/widgets/texts/product_title_text.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart';
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

  const AlkProductMetadata({
    super.key,
    required this.productId,
    required this.productName,
    this.productDiscount,
    required this.productBrand,
    required this.productOldPrice,
    required this.productNewPrice,
    required this.productBrandId,
  });

  @override
  State<AlkProductMetadata> createState() => _AlkProductMetadataState();
}

class _AlkProductMetadataState extends State<AlkProductMetadata> {
  int? productStock;
  bool isLoadingStock = true;

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  Future<void> _fetchStock() async {
    final QuantityController quantityController = QuantityController();
    int? stock = await quantityController.fetchQuantity(int.parse(widget.productId));

    setState(() {
      productStock = stock;
      isLoadingStock = false;
    });
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
            if (widget.productDiscount != null && widget.productDiscount!.isNotEmpty)
              AlkRoundedContainer(
                radius: AlkSize.sm,
                backgroundColor: Colors.purple.shade300,
                padding: const EdgeInsets.symmetric(
                  horizontal: AlkSize.sm,
                  vertical: AlkSize.xs,
                ),
                child: Text(
                  widget.productDiscount!,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .apply(color: Colors.white),
                ),
              ),
            SizedBox(width: AlkSize.spaceBtwItems),

            if (widget.productDiscount != null && widget.productDiscount!.isNotEmpty)
              Text(
                '${widget.productOldPrice} TND',
                style: Theme.of(context).textTheme.titleSmall!.apply(
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
            SizedBox(width: AlkSize.spaceBtwItems),

            // New price
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

        // Stock (Dynamically fetched)
        isLoadingStock
            ? const CircularProgressIndicator() // ✅ Show loading indicator
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

        SizedBox(height: AlkSize.spaceBtwItems / 2),

        // Brand
        Row(
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
                    overlayColor: Colors.purple,
                  ),
            AlkBrandTitleTextVerifIcon(
              title:( widget.productBrand == 'False')|| ( widget.productBrand == 'false') ? 'A L K I R T A S' : widget.productBrand,
              brandTextSize: TextSizes.medium,
            ),
            SizedBox(height: AlkSize.spaceBtwSections),
          ],
        ),
      ],
    );
  }
}
