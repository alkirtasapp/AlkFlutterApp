import 'package:flutter/material.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Controller for brand products screen
/// Manages fetching, pagination, and state for products of a specific brand
class BrandProductController extends ChangeNotifier {
  final int brandId;
  final String brandName;

  // State
  bool isLoading = true;
  bool isFetchingMore = false;
  List<Map<String, dynamic>> products = [];
  Set<int> fetchedProductIds = {};
  int offset = 0;
  final int limit = 10;

  BrandProductController({
    required this.brandId,
    required this.brandName,
  });

  /// Initial fetch of brand products
  Future<void> fetchBrandProducts() async {
    isLoading = true;
    products.clear();
    fetchedProductIds.clear();
    offset = 0;
    notifyListeners();

    final enrichedProducts = await ProductEnrichedService.fetchEnrichedByManufacturer(
      brandId,
      limit: limit,
      offset: 0,
    );

    if (enrichedProducts.isNotEmpty) {
      for (var enriched in enrichedProducts) {
        final product = ProductEnrichedService.buildProductFromEnriched(enriched);
        final productId = product['id'] as int;
        if (!fetchedProductIds.contains(productId)) {
          products.add(product);
          fetchedProductIds.add(productId);
        }
      }
      offset += enrichedProducts.length;
      AlkLoggerHelper.debug('Fetched ${products.length} products for brand $brandId ($brandName)');
    } else {
      AlkLoggerHelper.warning('No products found for brand $brandId ($brandName)');
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load more products (pagination) — called on scroll
  Future<void> loadMoreProducts() async {
    if (isFetchingMore) return;

    isFetchingMore = true;
    notifyListeners();

    final moreProducts = await ProductEnrichedService.fetchEnrichedByManufacturer(
      brandId,
      limit: limit,
      offset: offset,
    );

    if (moreProducts.isNotEmpty) {
      for (var enriched in moreProducts) {
        final product = ProductEnrichedService.buildProductFromEnriched(enriched);
        final productId = product['id'] as int;
        if (!fetchedProductIds.contains(productId)) {
          products.add(product);
          fetchedProductIds.add(productId);
        }
      }
      offset += moreProducts.length;
      AlkLoggerHelper.debug('Loaded ${moreProducts.length} more products for brand $brandId');
    }

    isFetchingMore = false;
    notifyListeners();
  }
}
