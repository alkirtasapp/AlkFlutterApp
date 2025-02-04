import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/images_strings.dart';
import '../../../../../utils/constants/size.dart';

class AlkProductImageslider extends StatelessWidget {
  final String productImage ;
  const AlkProductImageslider({
    super.key, required this.productImage,
  });

  @override
  Widget build(BuildContext context) {
    return AlkCurvedEdgeswidget(
      child: Container(
        color: AlkColors.white,
        child: Stack(
          children: [
            // main Large image
            SizedBox(
              height: 450,
              child: Padding(
                padding:
                    const EdgeInsets.all(AlkSize.productImageRadius * 2),
                child: Center(
                  child:  Image.network(
                    // product image 
                      productImage,
                      
                      fit: BoxFit.cover,
                      
                    
                    
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
