import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';
import '../products/product_cards/store_product_card.dart';

class AlkStoreGridDrawer extends StatelessWidget {
  const AlkStoreGridDrawer({
    super.key,
    this.mainAxisExtent = 260,
    required this.itemCount,
    required this.categoryId,
  });

  final int itemCount;
  final int categoryId;
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
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (_, index) => ProductCardStore(
        categoryId: categoryId,
        productIndex: index,
      ),
    );
  }
}
