import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/layout/store_grid_drawer.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_product_grid.dart';
import 'package:alkirtas/data/controllers/author_service.dart';
import 'package:alkirtas/features/shop/controllers/product_controller_store.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Screen that displays all products (books) by a specific author.
/// Fetches author details and their products from the AuthorPages module.
class AuthorProductsScreen extends StatefulWidget {
  final String authorName;

  const AuthorProductsScreen({
    super.key,
    required this.authorName,
  });

  @override
  State<AuthorProductsScreen> createState() => _AuthorProductsScreenState();
}

class _AuthorProductsScreenState extends State<AuthorProductsScreen> {
  final ProductControllerStore _productController = ProductControllerStore();

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _isDescriptionExpanded = false;
  Map<String, dynamic>? _authorData;
  List<Map<String, dynamic>> _products = [];
  List<int> _allProductIds = [];
  int _currentOffset = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchAuthorAndProducts();
  }

  Future<void> _fetchAuthorAndProducts() async {
    setState(() => _isLoading = true);

    // Fetch author details and product IDs in parallel
    final results = await Future.wait([
      AuthorService.getAuthorByName(widget.authorName),
      AuthorService.getProductsByAuthor(widget.authorName),
    ]);

    _authorData = results[0] as Map<String, dynamic>?;
    _allProductIds = results[1] as List<int>;

    AlkLoggerHelper.debug('Author: ${_authorData?['name']}, Products: ${_allProductIds.length}');

    // Fetch first batch of products
    if (_allProductIds.isNotEmpty) {
      final firstBatchIds = _allProductIds.take(_limit).toList();
      final products = await _productController.fetchProductsByIds(firstBatchIds);
      if (products != null) {
        _products = products;
        _currentOffset = firstBatchIds.length;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isFetchingMore || _currentOffset >= _allProductIds.length) return;

    setState(() => _isFetchingMore = true);

    final nextBatchIds = _allProductIds.skip(_currentOffset).take(_limit).toList();
    if (nextBatchIds.isNotEmpty) {
      final moreProducts = await _productController.fetchProductsByIds(nextBatchIds);
      if (moreProducts != null && moreProducts.isNotEmpty) {
        _products.addAll(moreProducts);
        _currentOffset += nextBatchIds.length;
      }
    }

    if (mounted) {
      setState(() => _isFetchingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          widget.authorName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AlkSize.defaultSpace),
        child: AlkShimmerProductGrid(itemCount: 6),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun livre de cet auteur.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Author header with image and description
        _buildAuthorHeader(),

        // Product grid
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                  !_isFetchingMore) {
                _loadMoreProducts();
              }
              return false;
            },
            child: Stack(
              children: [
                AlkStoreGridDrawer(
                  itemCount: _products.length,
                  categoryId: -1,
                  preloadedProducts: _products,
                  onLoadMoreProducts: _loadMoreProducts,
                ),
                if (_isFetchingMore)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 10,
                          child: LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 10,
                            valueColor: AlwaysStoppedAnimation<Color>(AlkColors.AppSecColor),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorHeader() {
    final imageUrl = _authorData?['image_url']?.toString() ?? '';
    final description = _authorData?['description']?.toString() ?? '';
    // Strip HTML tags for plain text display
    final plainText = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AlkSize.defaultSpace),
      decoration: BoxDecoration(
        color: AlkColors.AppSecColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AlkColors.AppSecColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author image (rounded rectangle)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: AlkColors.AppSecColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AlkColors.AppSecColor,
                      ),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AlkColors.AppSecColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AlkColors.AppSecColor,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book count
                Text(
                  '${_allProductIds.length} livre${_allProductIds.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AlkColors.AppSecColor,
                  ),
                ),
                // Description (expandable)
                if (plainText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plainText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: _isDescriptionExpanded ? null : 2,
                          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDescriptionExpanded ? 'Voir moins' : 'Voir plus',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AlkColors.AppSecColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
