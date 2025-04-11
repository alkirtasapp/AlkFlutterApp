// d:\flutter\test\lib\common\widgets\layout\category_carousel_layout.dart (Revised with LayoutBuilder)
import 'dart:async';
import 'package:alkirtas/common/widgets/shimmers/product_card_vertical_shimmer.dart';
import 'package:alkirtas/common/widgets/products/product_cards/category_product_card.dart';
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants/size.dart'; // Keep for vertical padding if needed

class AlkCategoryCarouselLayout extends StatefulWidget {
  const AlkCategoryCarouselLayout({
    super.key,
    required this.itemCount, // Target number of products to fetch
    required this.productsPerPage, // How many products to show per "page" view
    required this.categoryId,
    // horizontalPadding: Space BETWEEN items (or around if 1 item)
    // verticalPadding: Space ABOVE/BELOW items
    this.horizontalPadding = AlkSize.sm, // Default space between items
    this.verticalPadding = AlkSize.sm, // Default vertical space
    this.autoSwipeDuration = const Duration(seconds: 5),
  });

  final int itemCount;
  final int productsPerPage;
  final int categoryId;
  final double horizontalPadding; // Space between items
  final double verticalPadding; // Space above/below items
  final Duration autoSwipeDuration;

  @override
  _AlkCategoryCarouselLayoutState createState() =>
      _AlkCategoryCarouselLayoutState();
}

class _AlkCategoryCarouselLayoutState extends State<AlkCategoryCarouselLayout> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSwipeTimer;
  int _currentPageIndex = 0; // Tracks the current *page* index for auto-swipe

  late CategoryProductController _productController;
  List<Map<String, dynamic>>? _products;
  bool _isLoading = true;
  String? _error;

  // Calculate the maximum page index for scrolling
  int get maxPageIndex {
    if (_products == null ||
        _products!.isEmpty ||
        widget.productsPerPage <= 0) {
      return 0;
    }
    int totalProducts = _products!.length;
    // Calculate pages based on how many items fit per page
    int pages = (totalProducts / widget.productsPerPage).ceil();
    return pages > 0 ? pages - 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _productController = CategoryProductController(
      categoryId: widget.categoryId,
      limit: widget.itemCount, // Fetch up to itemCount products
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _productController.fetchCategoryProducts();
    if (!mounted) return;
    setState(() {
      _products = _productController.products;
      _isLoading = _productController.isLoading;
      _error = _productController.error;
      // Start timer only if there are products and multiple pages possible
      if (_products != null && _products!.isNotEmpty && maxPageIndex > 0) {
        _startAutoSwipeTimer();
      } else {
        _stopAutoSwipeTimer();
      }
    });
  }

  void _startAutoSwipeTimer() {
    _stopAutoSwipeTimer(); // Ensure no duplicate timers
    _autoSwipeTimer = Timer.periodic(widget.autoSwipeDuration, (timer) {
      if (!mounted ||
          _products == null ||
          _products!.isEmpty ||
          maxPageIndex == 0 || // Don't swipe if only one page
          !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      // Get the width available to the ListView from LayoutBuilder (passed implicitly)
      final double availableWidth = _scrollController.position.viewportDimension;

      // Increment page index or loop back
      if (_currentPageIndex < maxPageIndex) {
        _currentPageIndex++;
      } else {
        _currentPageIndex = 0;
      }

      // Calculate the target offset based on the page index and available width
      // Each "page" scrolls by the full viewport width
      double targetOffset = _currentPageIndex * availableWidth;

      // Clamp the offset to valid scroll range and animate
      targetOffset =
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600), // Smoother animation
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoSwipeTimer() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = null;
  }

  @override
  void dispose() {
    _stopAutoSwipeTimer();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define item height (can be dynamic later if needed)
    final double itemHeight = 280.0;
    // Total height includes the item height plus vertical padding (top & bottom)
    final double totalHeight = itemHeight + (widget.verticalPadding * 2);

    return SizedBox(
      height: totalHeight,
      // Use LayoutBuilder to get the available width for the ListView
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pass the available width and calculated height to _buildContent
          return _buildContent(constraints.maxWidth, itemHeight);
        },
      ),
    );
  }

  Widget _buildContent(double availableWidth, double itemHeight) {
    // --- Calculate Item Width based on Available Width ---
    double itemWidth;
    if (widget.productsPerPage <= 0) {
      itemWidth = 150.0; // Fallback
    } else {
      // Total space taken by padding between items
      // If productsPerPage is 1, there's no padding *between* items.
      // If productsPerPage is > 1, there are (productsPerPage - 1) gaps.
      final double totalPaddingSpace = widget.productsPerPage > 1
          ? widget.horizontalPadding * (widget.productsPerPage - 1)
          : 0;

      // Calculate width per item
      itemWidth = (availableWidth - totalPaddingSpace) / widget.productsPerPage;
    }
    // Ensure itemWidth is not negative or too small
    itemWidth = itemWidth > 50.0 ? itemWidth : 50.0;

    // --- Loading State ---
    if (_isLoading) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Disable scroll while loading
        itemCount: widget.productsPerPage, // Show placeholders
        // No padding on ListView itself, handled by separator and item padding
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) =>
            SizedBox(width: widget.horizontalPadding), // Space between items
        itemBuilder: (_, index) {
          return Padding(
            // Apply vertical padding around each item
            padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
            child: SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: const AlkProductCardVerticalShimmer(),
            ),
          );
        },
      );
    }

    // --- Error State ---
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $_error',
                  style: const TextStyle(color: Colors.red))));
    }

    // --- Empty State ---
    if (_products == null || _products!.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucun produit trouvé dans cette catégorie.')));
    }

    // --- Content Loaded State ---
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: _products!.length,
      // No padding on ListView itself, handled by separator and item padding
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) =>
          SizedBox(width: widget.horizontalPadding), // Space between items
      itemBuilder: (_, index) {
        final productData = _products![index];
        return Padding(
          // Apply vertical padding around each item
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
          child: SizedBox(
            width: itemWidth, // Use the calculated width
            height: itemHeight, // Use the fixed height
            child: CategoryProductCard(productData: productData),
          ),
        );
      },
    );
  }
}
