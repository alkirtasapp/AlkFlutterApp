import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import 'package:test/common/widgets/images/AlkRoundedImages.dart';
import 'package:test/common/widgets/texts/section_heading.dart';
import 'package:test/features/shop/controllers/product_card_controller.dart';
import 'package:test/features/shop/screens/product_details/widgets/bottom_add_to_cart.dart';
import 'package:test/features/shop/screens/product_details/widgets/product_metadata.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/images_strings.dart';

import '../../../../utils/constants/size.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/reference.dart';

class ProductDetails extends StatelessWidget {
   final String productName;
   final String productReference;
  final String productDiscount;
  final String productBrand;
  final String productOldPrice;
  final String productNewPrice;
  final String productStock;
  final String productDescription;
  final String productBrandId;
  final String productId;
  final String productImage;
  final List<String> productImageList;

  const ProductDetails({super.key, required  this.productName, required this.productDiscount, required this.productBrand, required this.productOldPrice, required this.productNewPrice, required this.productReference, required this.productStock, required this.productDescription, required this.productBrandId, required this.productId, required this.productImage, required this.productImageList });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AlkBottomAddToCart(),
        body: SingleChildScrollView(
      child: Column(
        children: [
          /// Product Image Slider
          AlkProductImageSlider(productImages: productImageList),


          /// Product Details
          Padding(
            
            padding:EdgeInsets.only(right: AlkSize.defaultSpace, left: AlkSize.defaultSpace, bottom: AlkSize.defaultSpace),
            child: Column(
              children: [
                // Reference
                AlkRef(productReference: productReference),
                SizedBox(height: AlkSize.spaceBtwItems),
                //price , title , stock , brand
                AlkProductMetadata( productName: productName,
                    productDiscount: productDiscount,
                    productBrand: productBrand,
                    productBrandId: productBrandId,
                    productOldPrice: productOldPrice,
                    productNewPrice: productNewPrice,
                    productStock : productStock ),
                SizedBox(height: AlkSize.spaceBtwItems,),
                //description 
                AlkSectionHeading(title:  'Déscription' , showActionButton: false,),
                SizedBox(width:AlkSize.spaceBtwItems  ),
               
                ReadMoreText(ProductCardControllerTax.cleanDescription(productDescription),
                trimLines: 2,
                trimMode: TrimMode.Line,
                trimCollapsedText: 'voir plus', 
                trimExpandedText: 'moins ',style: Theme.of(context).textTheme.labelMedium,
                moreStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                lessStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                
                ),

                // Reviews
              ],
            ), ),
            
        ],
      ),
    ));
  }
}


