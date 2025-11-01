import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_effect.dart';
import 'package:alkirtas/utils/constants/size.dart';

/// Shimmer effect for list tile (categories, etc.)
class AlkShimmerListTile extends StatelessWidget {
  const AlkShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace, vertical: AlkSize.sm),
      child: Row(
        children: [
          // Leading icon/image
          const AlkShimmerEffect(width: 50, height: 50, radius: 50),
          const SizedBox(width: AlkSize.spaceBtwItems),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AlkShimmerEffect(width: double.infinity, height: 18),
                const SizedBox(height: AlkSize.spaceBtwItems / 2),
                const AlkShimmerEffect(width: 160, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
