import 'package:alkirtas/features/shop/screens/brand/brand_products_screen.dart';
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

  const StoreDrawer({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialBreadcrumb,
  });

  @override
  State<StoreDrawer> createState() => _StorePageState();
}

class _StorePageState extends State<StoreDrawer> {
  bool isSearchVisible = false;
  Key productListKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Initialize the controller with initial category if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().initializeCategories(
            initialCategoryId: widget.initialCategoryId,
            initialCategoryName: widget.initialCategoryName,
            initialBreadcrumb: widget.initialBreadcrumb,
          );
    });
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

            // Active filters and search chips
            Consumer<StoreController>(
              builder: (context, controller, child) {
                if (!controller.isSearching && controller.selectedSortOption == "None") {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (controller.isSearching)
                        Chip(
                          avatar: const Icon(
                            Iconsax.search_normal,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Recherche: "${controller.currentSearchQuery}"',
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
                          onDeleted: () {
                            controller.clearSearch();
                            setState(() => productListKey = UniqueKey());
                          },
                          backgroundColor: AlkColors.AppSecColor,
                          deleteIconColor: Colors.white,
                        ),
                      if (controller.selectedSortOption != "None")
                        Chip(
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
                    ],
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

                  if (controller.products.isEmpty && controller.matchedBrands.isEmpty) {
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
                      // Brand suggestion cards (shown above product results when searching)
                      if (controller.isSearching && controller.matchedBrands.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Marques', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8),
                              ...controller.matchedBrands.map((brand) => _buildBrandSuggestionCard(brand)),
                            ],
                          ),
                        ),
                      
                      // Product grid
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
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

  Widget _buildBrandSuggestionCard(Map<String, dynamic> brand) {
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
  }
}
