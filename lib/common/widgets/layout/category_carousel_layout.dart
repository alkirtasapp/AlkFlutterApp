// d:\flutter\test\lib\common\widgets\layout\category_carousel_layout.dart (Corrected)
import 'dart:async';
// Corrected Import: Use the shimmer file provided (even if name is confusing)
import 'package:alkirtas/common/widgets/shimmers/product_card_vertical_shimmer.dart';
// Corrected Import: Use the category product card file provided
import 'package:alkirtas/common/widgets/products/product_cards/category_product_card.dart';
import 'package:alkirtas/features/shop/controllers/category_product_controller.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants/size.dart';

class AlkCategoryCarouselLayout extends StatefulWidget {
  const AlkCategoryCarouselLayout({
    super.key,
    required this.itemCount,
    required this.productsPerPage,
    required this.categoryId,
    this.horizontalPadding = AlkSize.gridViewSpacing,
    this.verticalPadding = AlkSize.gridViewSpacing,
    this.autoSwipeDuration = const Duration(seconds: 5),
  });

  final int itemCount;
  final int productsPerPage;
  final int categoryId;
  final double horizontalPadding;
  final double verticalPadding;
  final Duration autoSwipeDuration;

  @override
  _AlkCategoryCarouselLayoutState createState() =>
      _AlkCategoryCarouselLayoutState();
}

class _AlkCategoryCarouselLayoutState extends State<AlkCategoryCarouselLayout> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSwipeTimer;
  int _currentIndex = 0;

  late CategoryProductController _productController;
  List<Map<String, dynamic>>? _products;
  bool _isLoading = true;
  String? _error;

  int get maxScrollIndex {
    if (_products == null || _products!.isEmpty || widget.productsPerPage <= 0) {
      return 0;
    }
    int totalProducts = _products!.length;
    int pages = (totalProducts / widget.productsPerPage).ceil();
    return pages > 0 ? pages - 1 : 0;
  }

  @override
  void initState() {
    super.initState();
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
    await _productController.fetchCategoryProducts();
    if (!mounted) return;
    setState(() {
      _products = _productController.products;
      _isLoading = _productController.isLoading;
      _error = _productController.error;
      if (_products != null && _products!.isNotEmpty && maxScrollIndex > 0) {
        _startAutoSwipeTimer();
      } else {
        _stopAutoSwipeTimer();
      }
    });
  }

  void _startAutoSwipeTimer() {
    _stopAutoSwipeTimer();
    _autoSwipeTimer = Timer.periodic(widget.autoSwipeDuration, (timer) {
      if (!mounted ||
          _products == null ||
          _products!.isEmpty ||
          maxScrollIndex == 0) {
        timer.cancel();
        return;
      }
      final double screenWidth = MediaQuery.of(context).size.width;
      final double itemWidth = _calculateItemWidth(screenWidth);
      final double pageScrollWidth =
          (itemWidth * widget.productsPerPage) +
              (widget.horizontalPadding * widget.productsPerPage);
      if (_currentIndex < maxScrollIndex) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      double targetOffset = _currentIndex * pageScrollWidth;
      if (_scrollController.hasClients) {
        targetOffset =
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(targetOffset,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic);
      }
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

  double _calculateItemWidth(double screenWidth) {
    final double availableWidth = screenWidth - (widget.horizontalPadding * 2);
    final double totalSpacing =
        widget.horizontalPadding * (widget.productsPerPage - 1);
    final double itemWidth =
        (availableWidth - totalSpacing) / widget.productsPerPage;
    return itemWidth > 0 ? itemWidth : 150.0;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = _calculateItemWidth(screenWidth);
    final double itemHeight = 280.0; // Height for the new card
    final double totalHeight = itemHeight + (widget.verticalPadding * 2);

    return SizedBox(
      height: totalHeight,
      child: _buildContent(itemWidth, itemHeight),
    );
  }

  Widget _buildContent(double itemWidth, double itemHeight) {
    if (_isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.productsPerPage,
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding / 2),
        itemBuilder: (_, index) {
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding / 2,
                vertical: widget.verticalPadding),
            child: SizedBox(
                width: itemWidth,
                height: itemHeight,
                // Corrected Widget: Use the shimmer class name from the provided file
                child: const AlkProductCardVerticalShimmer()),
          );
        },
      );
    }

    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $_error',
                  style: const TextStyle(color: Colors.red))));
    }

    if (_products == null || _products!.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucun produit trouvé dans cette catégorie.')));
    }

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: _products!.length,
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding / 2),
      itemBuilder: (_, index) {
        final productData = _products![index];
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding / 2,
              vertical: widget.verticalPadding),
          child: SizedBox(
            width: itemWidth,
            height: itemHeight,
            // Corrected Widget: Use the category product card class name from the provided file
            child: CategoryProductCard(productData: productData),
          ),
        );
      },
    );
  }
}
