import 'package:flutter/material.dart';
import '../../../utils/constants/size.dart';
import '../products/product_cards/store_product_card.dart';

class AlkStoreGridDrawer extends StatelessWidget {
  const AlkStoreGridDrawer({
    super.key,
    this.mainAxisExtent = 280,
    required this.itemCount,
    required this.categoryId,
  });

  final int itemCount;
  final int categoryId;
  final double? mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    print("🛒 Building Grid for Category ID: $categoryId with $itemCount products");

    return Expanded(
      child: GridView.builder(
        itemCount: itemCount,
        padding: EdgeInsets.all(6.0),
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AlkSize.gridViewSpacing,
          crossAxisSpacing: AlkSize.gridViewSpacing,
          mainAxisExtent: mainAxisExtent,
        ),
        itemBuilder: (_, index) {
          print("🛍️ Rendering Product #$index for Category ID: $categoryId");

          return ProductCardStore(
            categoryId: categoryId,
            productIndex: index,
          );
        },
      ),
    );
  }
}