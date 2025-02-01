import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import 'package:test/common/widgets/images/AlkRoundedImages.dart';
import 'package:test/features/shop/screens/product_details/widgets/product_metadata.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/images_strings.dart';

import '../../../../utils/constants/size.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/reference.dart';

class ProductDetails extends StatelessWidget {
  const ProductDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          /// Product Image Slider
          AlkProductImageslider(),

          /// Product Details
          Padding(
            padding:EdgeInsets.only(right: AlkSize.defaultSpace, left: AlkSize.defaultSpace, bottom: AlkSize.defaultSpace),
            child: Column(
              children: [
                // Reference
                AlkRef(),
                SizedBox(height: AlkSize.spaceBtwItems/2),
                //price , title , stock , brand
                AlkProductMetadata()
                //checkout button 
                //description 
                // Reviewsz
              ],
            ), ),
            
        ],
      ),
    ));
  }
}


