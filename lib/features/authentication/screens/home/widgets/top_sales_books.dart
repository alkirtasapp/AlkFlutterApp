// d:\flutter\test\lib\features\authentication\screens\home\widgets\top_sales_books.dart (Updated)
import 'package:alkirtas/common/widgets/layout/category_product_grid_layout.dart';
import 'package:flutter/material.dart';

class TopSalesLivres extends StatelessWidget {
  const TopSalesLivres({
    super.key,
    required this.topSellingBooksCategoryId,
  });

  final int topSellingBooksCategoryId;

  @override
  Widget build(BuildContext context) {
    
    return CategoryProductGridLayout(
      key: ValueKey(topSellingBooksCategoryId), 
      categoryId: topSellingBooksCategoryId, 
      itemCount: 2, 
      crossAxisCount: 2, 
      mainAxisExtent: 280, 
    );
  }
}
