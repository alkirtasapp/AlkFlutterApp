import 'package:flutter/material.dart';
import '../../../utils/constants/size.dart';
import '../products/product_cards/store_product_card.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class AlkStoreGridDrawer extends StatelessWidget {
  final int itemCount;
  final int categoryId;
  final double? mainAxisExtent;
  final List<Map<dynamic, dynamic>> preloadedProducts; //  Accepts all key-value types
  final Future<void> Function()? onLoadMoreProducts; // Pagination callback

  const AlkStoreGridDrawer({
    super.key,
    this.mainAxisExtent = 280,
    required this.itemCount,
    required this.categoryId,
    required this.preloadedProducts, //  Receive paginated products
    this.onLoadMoreProducts,
  });

  @override
  Widget build(BuildContext context) {
    
    return GridView.builder(
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
        final productData = preloadedProducts[index];

        return ProductCardStore(
          categoryId: categoryId,
          productIndex: index,
          // Pass product data to the card
          productData: productData,
          // Pass all products for swiping
          allProducts: preloadedProducts,
          // Pass pagination callback
          onLoadMoreProducts: onLoadMoreProducts,
        );
      },
    );
  }
}

/// 1. Import the required libraries
/// 2. Create a personalized StoreGridDrawer widget
/// 3. Show the product card vertically
/// 4. Set the mainAxisExtent to 280 (product card height)
/// 5. Set the crossAxisCount to 2   (number of product cards per row)
/// 6. Set the mainAxisSpacing to 20 (vertical spacing between product cards)
/// 7. Set the crossAxisSpacing to 20 (horizontal spacing between product cards)
/// 8. Accepts paginated products
/// 9. Display the category ID and number of products on the current page
/// 10. Display the product name and ID
/// 11. Pass product data to the card
/// 12. Return the product card
/// 13. Return the GridView
