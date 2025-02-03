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
  const AlkProductMetadata({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // original price and discounted price if it exists

        // Title
        AlkProductTitleText(title: 'Product Tilte',smallSize: false,),
        SizedBox(height: AlkSize.spaceBtwItems ),
        Row(
          children: [
            // discount tag
            AlkRoundedContainer(
              radius: AlkSize.sm,
              backgroundColor: AlkColors.secondary.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(
                horizontal: AlkSize.sm,
                vertical: AlkSize.xs,
              ),
              child: Text(
                '10%',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .apply(color: Colors.black),
              ),
            ),
            SizedBox(width: AlkSize.spaceBtwItems),

            // price
            Text('100 TND  ',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .apply(decoration: TextDecoration.lineThrough)),
            SizedBox(height: AlkSize.spaceBtwItems),
            Text('90 TND ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .apply(color: AlkColors.dark)),
          ],
        ),
        SizedBox(height: AlkSize.spaceBtwItems),

        

        // Stock
        Row(
          children: [
            const AlkProductTitleText(title: 'Disponibilité :'),
            SizedBox(
              width: AlkSize.spaceBtwItems,
            ),
            Text('En Stock', style: Theme.of(context).textTheme.titleMedium)
          ],
        ),
        SizedBox(
          height: AlkSize.spaceBtwItems ,
        ),

        // Brand
        Row(
          children: [
            AlkCircularImage(
              isNetworkImage: false,
               image: AlkImages.darkAppLogo,
               width: 52,
               height: 52,
               overlayColor: AlkColors.black,
               ),
            AlkBrandTitleTextVerifIcon(title: 'Brand Title',brandTextSize: TextSizes.medium,),
            SizedBox(height: AlkSize.spaceBtwSections,),

            
          ],
          
        ),
     
      ],
    );
  }
}
