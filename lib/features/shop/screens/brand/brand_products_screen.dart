import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/common/widgets/images/AlkCircularImage.dart';
import 'package:alkirtas/common/widgets/layout/store_grid_drawer.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_product_grid.dart';
import 'package:alkirtas/features/shop/controllers/brand_product_controller.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';

class BrandProductsScreen extends StatelessWidget {
  final int brandId;
  final String brandName;

  const BrandProductsScreen({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrandProductController(
        brandId: brandId,
        brandName: brandName,
      )..fetchBrandProducts(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          titleSpacing: 0,
          title: Row(
            children: [
              brandId > 0
                  ? AlkCircularImage(
                      image: 'https://www.alkirtas.com/img/m/$brandId.jpg',
                      backgroundColor: Colors.transparent,
                      isNetworkImage: true,
                      fit: BoxFit.contain,
                      width: 40,
                      height: 40,
                    )
                  : AlkCircularImage(
                      isNetworkImage: false,
                      image: AlkImages.darkAppLogo,
                      width: 40,
                      height: 40,
                      overlayColor: AlkColors.AppSecColor,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brandName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
        body: Consumer<BrandProductController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AlkSize.defaultSpace),
                child: AlkShimmerProductGrid(itemCount: 6),
              );
            }

            if (controller.products.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun produit disponible pour cette marque.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                    !controller.isFetchingMore) {
                  controller.loadMoreProducts();
                }
                return false;
              },
              child: Stack(
                children: [
                  AlkStoreGridDrawer(
                    itemCount: controller.products.length,
                    categoryId: -1,
                    preloadedProducts: controller.products,
                    onLoadMoreProducts: () => controller.loadMoreProducts(),
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
    );
  }
}
