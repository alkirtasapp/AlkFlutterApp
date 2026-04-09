import 'package:alkirtas/features/shop/screens/brand/brand_products_screen.dart';
import 'package:alkirtas/features/shop/screens/author/author_products_screen.dart';
import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/images/AlkCircularImage.dart';
import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../../../common/widgets/qr_scanner/qr_scanner_widget.dart';
import '../../../../common/widgets/shimmer/shimmer_product_grid.dart';
import '../../../../controllers/qr_navigation_controller.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/size.dart';

import 'controllers/store_controller.dart';
import 'widgets/store_app_bar.dart';
import 'widgets/store_search_bar.dart';

class StoreDrawer extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;
  final List<String>? initialBreadcrumb;
  final String? initialSearchQuery;

  const StoreDrawer({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialBreadcrumb,
    this.initialSearchQuery,
  });

  @override
  State<StoreDrawer> createState() => _StorePageState();
}

class _StorePageState extends State<StoreDrawer> {
  bool isSearchVisible = false;
  Key productListKey = UniqueKey();
  bool _suggestionsCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with initial category if provided
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<StoreController>();
      await controller.initializeCategories(
            initialCategoryId: widget.initialCategoryId,
            initialCategoryName: widget.initialCategoryName,
            initialBreadcrumb: widget.initialBreadcrumb,
          );
      if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
        controller.searchProducts(widget.initialSearchQuery!);
      }
    });
  }

  @override
  void didUpdateWidget(StoreDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categoryChanged = widget.initialCategoryId != oldWidget.initialCategoryId ||
        widget.initialCategoryName != oldWidget.initialCategoryName;
    if (categoryChanged) {
      // Reset search UI state immediately
      setState(() {
        isSearchVisible = false;
        _suggestionsCollapsed = false;
        productListKey = UniqueKey();
      });
      // Reinitialize controller with the new category
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final controller = context.read<StoreController>();
        if (controller.isSearching) {
          controller.clearSearch();
        }
        await controller.initializeCategories(
          initialCategoryId: widget.initialCategoryId,
          initialCategoryName: widget.initialCategoryName,
          initialBreadcrumb: widget.initialBreadcrumb,
        );
        if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
          controller.searchProducts(widget.initialSearchQuery!);
        }
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearchVisible = !isSearchVisible;
    });
  }

  void _onSearchSubmitted() {
    setState(() {
      isSearchVisible = false;
      productListKey = UniqueKey();
      _suggestionsCollapsed = false;
    });
  }

  void _showQrScanner(BuildContext context) {
    NavigationController? navigationController;
    try {
      navigationController = Get.find<NavigationController>();
    } catch (e) {
      navigationController = null;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: AlkQrScannerWidget(
              onQrCodeScanned: (String qrCode) async {
                Navigator.of(context).pop();
                debugPrint('📱 QR Code scanned in Store: $qrCode');

                if (navigationController != null) {
                  final qrController = QrNavigationController(navigationController);
                  final success = await qrController.processScannedCode(qrCode);
                  debugPrint('📱 QR Processing result: ${success ? "Success" : "Failed"}');
                } else {
                  debugPrint('❌ NavigationController not available');
                  Get.snackbar(
                    'Erreur',
                    'Navigation non disponible',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                }
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(
        onSearchToggle: _toggleSearch,
        onQrScannerPressed: () => _showQrScanner(context),
        isSearchVisible: isSearchVisible,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            if (isSearchVisible)
              StoreSearchBar(
                onSearchSubmitted: _onSearchSubmitted,
                onClose: () => setState(() => isSearchVisible = false),
              ),

            // Sort filter chip (search chip removed - handled by suggestions)
            Consumer<StoreController>(
              builder: (context, controller, child) {
                if (controller.selectedSortOption == "None") {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Chip(
                    avatar: const Icon(
                      Iconsax.filter,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      controller.getSortOptionLabel(controller.selectedSortOption),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                    onDeleted: () => controller.updateSortOption("None"),
                    backgroundColor: AlkColors.AppSecColor,
                    deleteIconColor: Colors.white,
                  ),
                );
              },
            ),

            // Product grid with brand suggestions
            Expanded(
              child: Consumer<StoreController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(AlkSize.defaultSpace),
                      child: AlkShimmerProductGrid(itemCount: 6),
                    );
                  }

                  if (controller.products.isEmpty && controller.matchedBrands.isEmpty && controller.matchedAuthors.isEmpty) {
                    return Center(
                      child: Text(
                        controller.isSearching
                            ? "Aucun résultat trouvé pour votre recherche."
                            : "Aucun produit disponible.",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Collapsible brand & author suggestions
                      if (controller.isSearching && (controller.matchedBrands.isNotEmpty || controller.matchedAuthors.isNotEmpty))
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          constraints: BoxConstraints(
                            maxHeight: _suggestionsCollapsed ? 40 : MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: _suggestionsCollapsed
                              ? _buildCollapsedSuggestions(controller)
                              : _buildExpandedSuggestions(context, controller),
                        ),

                      // Product grid
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            // Collapse suggestions when scrolling down
                            if (scrollInfo is ScrollUpdateNotification) {
                              if (scrollInfo.scrollDelta != null && scrollInfo.scrollDelta! > 5 && !_suggestionsCollapsed) {
                                setState(() => _suggestionsCollapsed = true);
                              }
                            }
                            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                                !controller.isFetchingMore) {
                              if (controller.isSearching) {
                                controller.loadMoreSearchResults();
                              } else {
                                controller.loadMoreProducts();
                              }
                            }
                            return false;
                          },
                          child: Stack(
                            children: [
                              AlkStoreGridDrawer(
                                key: productListKey,
                                itemCount: controller.products.length,
                                categoryId: controller.isSearching ? -1 : controller.selectedCategoryId,
                                preloadedProducts: controller.products,
                                onLoadMoreProducts: () async {
                                  if (controller.isSearching) {
                                    await controller.loadMoreSearchResults();
                                  } else {
                                    await controller.loadMoreProducts();
                                  }
                                },
                              ),
                              if (controller.isFetchingMore)
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSuggestions(StoreController controller) {
    final totalCount = controller.matchedBrands.length + controller.matchedAuthors.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Search query chip with X
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _suggestionsCollapsed = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AlkColors.AppSecColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.search_normal, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '"${controller.currentSearchQuery}"',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalCount',
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white.withOpacity(0.8)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear search button
          GestureDetector(
            onTap: () {
              controller.clearSearch();
              setState(() {
                productListKey = UniqueKey();
                _suggestionsCollapsed = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSuggestions(BuildContext context, StoreController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search query header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AlkColors.AppSecColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.search_normal, size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recherche: "${controller.currentSearchQuery}"',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    controller.clearSearch();
                    setState(() => productListKey = UniqueKey());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          if (controller.matchedBrands.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AlkColors.AppSecColor.withOpacity(0.3)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Iconsax.shop, size: 18, color: AlkColors.AppSecColor),
                    title: Text(
                      'Marques (${controller.matchedBrands.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    children: controller.matchedBrands.map((brand) => _buildBrandDropdownItem(brand)).toList(),
                  ),
                ),
              ),
            ),
          if (controller.matchedAuthors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AlkColors.AppSecColor.withOpacity(0.3)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Iconsax.pen_tool, size: 18, color: AlkColors.AppSecColor),
                    title: Text(
                      'Auteurs (${controller.matchedAuthors.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    children: controller.matchedAuthors.map((author) => _buildAuthorDropdownItem(author)).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandDropdownItem(Map<String, dynamic> brand) {
    final brandId = int.tryParse(brand['id_manufacturer'].toString()) ?? 0;
    final brandName = brand['manufacturer_name']?.toString() ?? '';
    final productCount = int.tryParse(brand['product_count'].toString()) ?? 0;

    return InkWell(
      onTap: () => Get.to(() => BrandProductsScreen(
        brandId: brandId,
        brandName: brandName,
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            AlkCircularImage(
              image: 'https://www.alkirtas.com/img/m/$brandId.jpg',
              backgroundColor: Colors.transparent,
              isNetworkImage: true,
              fit: BoxFit.contain,
              width: 30, height: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(brandName, style: const TextStyle(fontSize: 13)),
            ),
            Text('$productCount', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorDropdownItem(Map<String, dynamic> author) {
    final authorName = author['name']?.toString() ?? '';
    final imageUrl = author['image_url']?.toString() ?? '';

    return InkWell(
      onTap: () => Get.to(() => AuthorProductsScreen(authorName: authorName)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 30, height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: AlkColors.AppSecColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.person, size: 18, color: AlkColors.AppSecColor),
                      ),
                    )
                  : Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AlkColors.AppSecColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.person, size: 18, color: AlkColors.AppSecColor),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(authorName, style: const TextStyle(fontSize: 13)),
            ),
            Icon(Iconsax.arrow_right_3, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /*Widget _buildBrandSuggestionCard(Map<String, dynamic> brand) {
    final brandId = int.tryParse(brand['id_manufacturer'].toString()) ?? 0;
    final brandName = brand['manufacturer_name']?.toString() ?? '';
    final productCount = int.tryParse(brand['product_count'].toString()) ?? 0;

    return GestureDetector(
      onTap: () => Get.to(() => BrandProductsScreen(
        brandId: brandId,
        brandName: brandName,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlkColors.AppSecColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            AlkCircularImage(
              image: 'https://www.alkirtas.com/img/m/$brandId.jpg',
              backgroundColor: Colors.transparent,
              isNetworkImage: true,
              fit: BoxFit.contain,
              width: 40, height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brandName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$productCount produits', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: AlkColors.AppSecColor),
          ],
        ),
      ),
    );
  }*/

  /*Widget _buildAuthorSuggestionCard(Map<String, dynamic> author) {
    final authorName = author['name']?.toString() ?? '';
    final imageUrl = author['image_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Get.to(() => AuthorProductsScreen(authorName: authorName)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlkColors.AppSecColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AlkColors.AppSecColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.person, size: 24, color: AlkColors.AppSecColor),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AlkColors.AppSecColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.person, size: 24, color: AlkColors.AppSecColor),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Text('Auteur', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: AlkColors.AppSecColor),
          ],
        ),
      ),
    );
  }*/
}
