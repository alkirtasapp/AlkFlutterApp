import 'package:flutter/material.dart';
import '../../../utils/constants/size.dart';
import '../products/product_cards/store_product_card.dart';

class AlkStoreGridDrawer extends StatelessWidget {
  final int itemCount;
  final int categoryId;
  final double? mainAxisExtent;
  final List<Map<String, dynamic>> preloadedProducts; // ✅ Accept paginated products

  const AlkStoreGridDrawer({
    super.key,
    this.mainAxisExtent = 280,
    required this.itemCount,
    required this.categoryId,
    required this.preloadedProducts, // ✅ Receive paginated products
  });

  @override
  Widget build(BuildContext context) {
    print("🛒 Building Grid for Category ID: $categoryId with ${preloadedProducts.length} products on current page");

    return Expanded(
      child: GridView.builder(
        itemCount: preloadedProducts.length,
        padding: EdgeInsets.all(6.0),
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AlkSize.gridViewSpacing,
          crossAxisSpacing: AlkSize.gridViewSpacing,
          mainAxisExtent: mainAxisExtent,
        ),
        itemBuilder: (_, index) {
          print("🛍️ Rendering Product: ${preloadedProducts[index]['name']} (ID: ${preloadedProducts[index]['id']})");

          return ProductCardStore(
            categoryId: categoryId,
            productIndex: index,
          );
        },
      ),
    );
  }
}
