// d:\flutter\test\lib\common\widgets\layout\category_product_grid_layout.dart (NEW FILE)
import 'package:flutter/material.dart';
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
import 'package:alkirtas/common/widgets/products/product_cards/category_product_card.dart';
import 'package:alkirtas/common/widgets/shimmers/product_card_vertical_shimmer.dart'; // Re-use shimmer
import 'package:alkirtas/utils/constants/size.dart';

class CategoryProductGridLayout extends StatefulWidget {
  const CategoryProductGridLayout({
    super.key,
    required this.categoryId,
    required this.itemCount, // How many items to fetch/display max
    this.mainAxisExtent = 250, // Default height for cards
    this.crossAxisCount = 2,   // Default to 2 columns
  });

  final int categoryId;
  final int itemCount;
  final double mainAxisExtent;
  final int crossAxisCount;

  @override
  State<CategoryProductGridLayout> createState() => _CategoryProductGridLayoutState();
}

class _CategoryProductGridLayoutState extends State<CategoryProductGridLayout> {
  late CategoryProductController _productController;
  List<Map<String, dynamic>>? _products;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use the limit from widget.itemCount for fetching
    _productController = CategoryProductController(
      categoryId: widget.categoryId,
      limit: widget.itemCount,
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Fetch products using the controller
    await _productController.fetchCategoryProducts();
    if (!mounted) return;
    setState(() {
     
      _products = _productController.products;
      _isLoading = _productController.isLoading; // Should be false now
      _error = _productController.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a grid of shimmers while loading
      return GridView.builder(
        itemCount: widget.crossAxisCount * 2, // Show a few rows of shimmers
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: AlkSize.gridViewSpacing,
          crossAxisSpacing: AlkSize.gridViewSpacing,
          mainAxisExtent: widget.mainAxisExtent,
        ),
        itemBuilder: (_, index) => const AlkProductCardVerticalShimmer(),
      );
    }

    if (_error != null) {
      // Show error message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_products == null || _products!.isEmpty) {
      // Show message if no products found
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun produit trouvé dans cette catégorie.'),
        ),
      );
    }

    // --- Build the actual Grid ---
    return GridView.builder(
      // Use the actual number of loaded products
      itemCount: _products!.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      // Make it non-scrollable as it's inside HomeScreen's SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: AlkSize.gridViewSpacing,
        crossAxisSpacing: AlkSize.gridViewSpacing,
        mainAxisExtent: widget.mainAxisExtent,
      ),
      itemBuilder: (_, index) {
        // Get the specific product data for this index
        final productData = _products![index];
        // Use CategoryProductCard (the stateless one)
        return CategoryProductCard(
          productData: productData,
          allProducts: _products,
          productIndex: index,
        );
      },
    );
  }
}
