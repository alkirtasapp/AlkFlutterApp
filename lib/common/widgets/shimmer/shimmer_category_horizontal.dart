import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_effect.dart';
import 'package:alkirtas/utils/constants/size.dart';

/// Shimmer effect for horizontal category list
class AlkShimmerCategoryHorizontal extends StatelessWidget {
  const AlkShimmerCategoryHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 6,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(right: AlkSize.spaceBtwItems),
            child: Column(
              children: [
                // Category Icon Circle
                const AlkShimmerEffect(width: 56, height: 56, radius: 56),
                const SizedBox(height: AlkSize.spaceBtwItems / 2),

                // Category Name
                const AlkShimmerEffect(width: 55, height: 8, radius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}
