import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';

class AlkBrandGridLayout extends StatelessWidget {
  const AlkBrandGridLayout({
    super.key, 
    this.mainAxisExtent = 260, 
    required this.itemBuilder, 
    required this.itemCount,
  });
  final int itemCount ;
  final double? mainAxisExtent;
  final Widget? Function (BuildContext,int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AlkSize.gridViewSpacing,
        crossAxisSpacing: AlkSize.gridViewSpacing,
        mainAxisExtent: mainAxisExtent,),
         itemBuilder: itemBuilder,
         /*(_,index)=> AlkProductCardVertical(productIndex: index,), n7elha yetahsheli */ 
         );
  }
}
