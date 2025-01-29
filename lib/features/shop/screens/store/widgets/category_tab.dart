import 'package:flutter/material.dart';
import 'package:test/common/widgets/layout/grid_layout.dart';

import '../../../../../common/widgets/brands/brand_showcase.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/images_strings.dart';
import '../../../../../utils/constants/size.dart';

class AlkCategoryTab
 extends StatelessWidget {
  const AlkCategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return 
            ListView(
              shrinkWrap: false,
              physics: NeverScrollableScrollPhysics(),

              children: [
                Padding(
                padding: EdgeInsets.all(AlkSize.defaultSpace/2),
                child: Column(
                  children: [
                    //brands
                    AlkBrandShowcase(images: [AlkImages.darkAppLogo,AlkImages.darkAppLogo,AlkImages.darkAppLogo,],),
                    const SizedBox(height: AlkSize.spaceBtwItems),
                    // Products
                    // AlkSectionHeading(title: '' ,onPressed: (){}, showActionButton: false,),
                    const SizedBox(height:  AlkSize.spaceBtwItems),
              
                    AlkGridLayout(itemCount: 8,),
                    const SizedBox(height: AlkSize.spaceBtwSections,)
                 ],
                ),
               ),
           ] );
  }
}