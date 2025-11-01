import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_product_card.dart';
import 'package:alkirtas/utils/constants/size.dart';

/// Grid of shimmer product cards for loading state
class AlkShimmerProductGrid extends StatelessWidget {
  const AlkShimmerProductGrid({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AlkSize.gridViewSpacing,
        crossAxisSpacing: AlkSize.gridViewSpacing,
        mainAxisExtent: 288,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const AlkShimmerProductCard(),
    );
  }
}
