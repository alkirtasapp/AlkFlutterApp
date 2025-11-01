import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_effect.dart';
import 'package:alkirtas/utils/constants/size.dart';

/// Shimmer effect for product card loading state
class AlkShimmerProductCard extends StatelessWidget {
  const AlkShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          const AlkShimmerEffect(width: 180, height: 180, radius: AlkSize.productImageRadius),
          const SizedBox(height: AlkSize.spaceBtwItems / 2),

          // Product Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AlkShimmerEffect(width: 160, height: 15),
                const SizedBox(height: AlkSize.spaceBtwItems / 4),
                const AlkShimmerEffect(width: 110, height: 15),
                const SizedBox(height: AlkSize.spaceBtwItems / 2),

                // Price
                Row(
                  children: [
                    const AlkShimmerEffect(width: 50, height: 20),
                    const SizedBox(width: AlkSize.spaceBtwItems),
                    const AlkShimmerEffect(width: 40, height: 15),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
