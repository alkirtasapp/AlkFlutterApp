import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';
import '../products/product_cards/product_card_vertical.dart';

class AlkStoreGridLayout extends StatelessWidget {
  const AlkStoreGridLayout({
    super.key, 
    this.mainAxisExtent = 260, 
    /*required this.itemBuilder, */
    required this.itemCount,
  });
  final int itemCount ;
  final double? mainAxisExtent;
  /*final Widget? Function (BuildContext,int) itemBuilder;*/

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
        mainAxisExtent: mainAxisExtent),
         itemBuilder: 
         (_,index)=> AlkProductCardVertical(productIndex: index),
         );
  }
}
