import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/layout/store_grid_drawer.dart';
import '../../../../common/widgets/qr_scanner/qr_scanner_widget.dart';
import '../../../../common/widgets/shimmer/shimmer_product_grid.dart';
import '../../../../controllers/qr_navigation_controller.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/size.dart';
import 'controllers/store_controller.dart';
import 'widgets/store_app_bar.dart';
import 'widgets/store_category_drawer.dart';
import 'widgets/store_search_bar.dart';

class StoreDrawer extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const StoreDrawer({super.key, this.initialCategoryId, this.initialCategoryName});

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
      drawer: const Drawer(
        child: StoreCategoryDrawer(),
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

            // Product grid
            Expanded(
              child: Consumer<StoreController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(AlkSize.defaultSpace),
                      child: AlkShimmerProductGrid(itemCount: 6),
                    );
                  }

                  if (controller.products.isEmpty) {
                    return Center(
                      child: Text(
                        controller.isSearching
                            ? "Aucun résultat trouvé pour votre recherche."
                            : "Aucun produit disponible.",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
