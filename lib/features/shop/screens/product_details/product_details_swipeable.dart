import 'package:flutter/material.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/features/shop/controllers/product_controller_store.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// A wrapper around [ProductDetails] that enables horizontal swiping
/// between products in a list. Uses [PageView.builder] so each page
/// is a full [ProductDetails] screen.
/// 
/// Supports pagination: when user reaches the last product and swipes,
/// calls [onLoadMoreProducts] to fetch the next batch.
class ProductDetailsSwipeable extends StatefulWidget {
  final List<Map<dynamic, dynamic>> products;
  final int initialIndex;
  final Future<void> Function()? onLoadMoreProducts; // Pagination callback

  const ProductDetailsSwipeable({
    super.key,
    required this.products,
    required this.initialIndex,
    this.onLoadMoreProducts,
  });

  @override
  State<ProductDetailsSwipeable> createState() =>
      _ProductDetailsSwipeableState();
}

class _ProductDetailsSwipeableState extends State<ProductDetailsSwipeable> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(ProductDetailsSwipeable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When products list size changes (pagination loaded more products),
    // PageView automatically rebuilds with new item count
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle pagination when user swipes to near the end of the list
  Future<void> _handlePaginationIfNeeded(int newIndex) async {
    // Trigger pagination if user is within the last 2 products (gives buffer)
    if (widget.onLoadMoreProducts != null &&
        newIndex >= widget.products.length - 2 &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      try {
        await widget.onLoadMoreProducts!();
      } catch (e) {
        AlkLoggerHelper.error('Error loading more products during swipe', e);
      } finally {
        if (mounted) {
          _isLoadingMore = false;
        }
      }
    }
  }

  // Helper to safely convert a dynamic value to String
  static String _safeString(dynamic value, [String fallback = '']) {
    if (value is String) return value;
    if (value is bool) return value ? 'True' : 'False';
    return value?.toString() ?? fallback;
  }

  /// Builds a [ProductDetails] widget from a raw product map.
  static ProductDetails buildProductDetails(Map<dynamic, dynamic> productData) {
    final id = _safeString(productData['id']);
    final name = _safeString(productData['name']);
    final reference = _safeString(productData['reference']);
    final brandName = _safeString(productData['manufacturer_name']);
    final brandId = _safeString(productData['id_manufacturer']);
    final description = _safeString(productData['description_short']);
    final productStock = _safeString(productData['quantity']);

    final List<String> imageList =
        (productData['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];

    final imageUrl =
        ProductControllerStore().constructImageUrl(productData['id_default_image']);

    final rawTTCPrice =
        double.tryParse(_safeString(productData['ttc_price'], '0.00'))
                ?.toStringAsFixed(2) ??
            '0.00';
    final taxRulesGroupId = productData['id_tax_rules_group'] ?? 0;
    final rawPriceHT =
        double.tryParse(_safeString(productData['price'], '0.00'))
                ?.toStringAsFixed(2) ??
            '0.00';
    final displayPrice = (taxRulesGroupId == 0) ? rawPriceHT : rawTTCPrice;

    final double discountValue =
        (productData['discount'] as num?)?.toDouble() ?? 0;

    String? discountText;
    if (discountValue > 0) {
      discountText = '${discountValue.toStringAsFixed(0)}%';
    }

    final newPrice = discountValue > 0
        ? (double.parse(displayPrice) * (1 - discountValue / 100))
            .toStringAsFixed(2)
        : displayPrice;

    return ProductDetails(
      productId: id,
      productName: name,
      productReference: reference,
      productDiscount: discountText ?? '',
      productBrand: brandName,
      productBrandId: brandId,
      productImage: imageUrl,
      productImageList: imageList,
      productStock: productStock,
      productDescription: description,
      productOldPrice: discountText != null ? displayPrice : '',
      productNewPrice: newPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.products.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Check if we need to load more products
            _handlePaginationIfNeeded(index);
          },
          itemBuilder: (context, index) {
            return buildProductDetails(widget.products[index]);
          },
        ),
        // Page indicator overlay
        if (widget.products.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.products.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ) ?? const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        // Loading indicator when fetching more products
        if (_isLoadingMore)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}