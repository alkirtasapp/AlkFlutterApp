import 'package:flutter/widgets.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/images_strings.dart';
import '../../../../../utils/constants/size.dart';

class AlkProductImageslider extends StatelessWidget {
  const AlkProductImageslider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlkCurvedEdgeswidget(
      child: Container(
        color: AlkColors.light,
        child: Stack(
          children: [
            // main Large image
            SizedBox(
              height: 400,
              child: Padding(
                padding:
                    const EdgeInsets.all(AlkSize.productImageRadius * 2),
                child: Center(
                  child: Image(
                    image: AssetImage(AlkImages.lighAppLogo),
                  ),
                ),
              ),
            ),
            // Image Slider
            Positioned(
              right: 0,
              bottom: 30,
              left: AlkSize.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  separatorBuilder: (_, __) => const SizedBox(
                    width: AlkSize.spaceBtwItems,
                  ),
                  itemCount: 4,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics:  const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (_, index) => AlkRoundedImage(
                    imageUrl: AlkImages.lighAppLogo,
                    width: 80,
                    backgroundColor: AlkColors.white,
                    border: Border.all(color: AlkColors.primaryColor),
                    padding: EdgeInsets.all(AlkSize.sm),
                  ),
                ),
              ),
            ),
    
    
            //App Bar Icon 
            AlkAppBar(
              showBackArrow: true,
              
            )
          ],
        ),
      ),
    );
  }
}
