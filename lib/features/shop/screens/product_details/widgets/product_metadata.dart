import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:test/common/widgets/images/AlkCircularImage.dart';
import 'package:test/common/widgets/roundedContainer.dart';
import 'package:test/common/widgets/texts/brand__title_text_verif_icon.dart';
import 'package:test/common/widgets/texts/product_title_text.dart';
import 'package:test/utils/constants/enums.dart';
import 'package:test/utils/constants/images_strings.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';

class AlkProductMetadata extends StatelessWidget {
  final String productName;
  final String? productDiscount;
  final String productBrand;
  final String productOldPrice;
  final String productNewPrice;
  final String productStock;
 
  final String productBrandId;

  const AlkProductMetadata({
    super.key,
    required this.productName,
    this.productDiscount,
    required this.productBrand,
    required this.productOldPrice,
    required this.productNewPrice,

    required this.productBrandId,
     required this.productStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        AlkProductTitleText(title: productName, smallSize: false),
        SizedBox(height: AlkSize.spaceBtwItems),

        Row(
          children: [
            // Discount tag (only if there is a discount)
            if (productDiscount != null && productDiscount!.isNotEmpty)
              AlkRoundedContainer(
                radius: AlkSize.sm,
                backgroundColor: AlkColors.secondary.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(
                  horizontal: AlkSize.sm,
                  vertical: AlkSize.xs,
                ),
                child: Text(
                  productDiscount!,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .apply(color: Colors.black),
                ),
              ),
            SizedBox(width: AlkSize.spaceBtwItems),

            // Original price (strikethrough)
            if (productDiscount != null && productDiscount!.isNotEmpty)
              Text(
                '$productOldPrice TND',
                style: Theme.of(context).textTheme.titleSmall!.apply(
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
            SizedBox(width: AlkSize.spaceBtwItems),

            // New price
            Text(
              '$productNewPrice TND',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .apply(color: AlkColors.dark),
            ),
          ],
        ),

        SizedBox(height: AlkSize.spaceBtwItems),

        // Stock
        Row(
          children: [
            // const AlkProductTitleText(title: 'Disponibilité :'),
            SizedBox(width: AlkSize.spaceBtwItems),
            // Text('En Stock', style: Theme.of(context).textTheme.titleMedium),
            productStock != '0'
                ? AlkRoundedContainer(
                    radius: AlkSize.sm,
                    backgroundColor: Colors.green.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlkSize.sm,
                      vertical: AlkSize.xs,
                    ),
                    child: Text(
                      'En Stock',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .apply(color: Colors.white),
                    ),
                  )
                : AlkRoundedContainer(
                    radius: AlkSize.sm,
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlkSize.sm,
                      vertical: AlkSize.xs,
                    ),
                    child: Text(
                      'hors stock',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .apply(color: Colors.white),
                    ),
                  ),
          ],
        ),
        SizedBox(height: AlkSize.spaceBtwItems),

        // Brand
        Row(
          children: [
          
             productBrandId != '0' ?
            AlkCircularImage(

              image:
                   'https://www.alkirtas.com/img/m/${productBrandId}.jpg', // logo brand li jebneh bessif
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
              title: productBrand == 'False' ? 'A L K I R T A S' : productBrand,
              brandTextSize: TextSizes.medium,
            ),
            SizedBox(height: AlkSize.spaceBtwSections),
          ],
        ),
      ],
    );
  }
}
