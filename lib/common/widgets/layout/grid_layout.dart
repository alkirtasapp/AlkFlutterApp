import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';
import '../products/product_cards/product_card_vertical.dart';

class AlkGridLayout extends StatelessWidget {
  const AlkGridLayout({
    super.key, 
    this.mainAxisExtent = 280, 
    
    required this.itemCount,
  });
  final int itemCount ;
  final double? mainAxisExtent;
  

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      
      itemCount: itemCount,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AlkSize.gridViewSpacing,
        crossAxisSpacing: AlkSize.gridViewSpacing,
        mainAxisExtent: mainAxisExtent,),
         itemBuilder: 
         (_,index)=> AlkProductCardVertical(productIndex: index,),
         );
  }
}

/// 1. Import the required libraries
/// 2. Create a personalized GridLayout widget
/// 3. Show the product card vertically
/// 4. Set the mainAxisExtent to 280 (product card height)
/// 5. Set the crossAxisCount to 2   (number of product cards per row)
/// 6. Set the mainAxisSpacing to 20 (vertical spacing between product cards)
/// 7. Set the crossAxisSpacing to 20 (horizontal spacing between product cards)
