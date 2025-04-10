// d:\flutter\test\lib\common\widgets\shimmers\product_card_vertical_shimmer.dart (Corrected)
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Corrected Class Name: Renamed from AlkCategoryProductCardVerticalShimmer
class AlkProductCardVerticalShimmer extends StatelessWidget {
  // Corrected Constructor Name
  const AlkProductCardVerticalShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
        color: dark ? AlkColors.darkerGrey : AlkColors.white,
      ),
      child: Shimmer.fromColors(
        baseColor: dark ? Colors.grey[850]! : Colors.grey[300]!,
        highlightColor: dark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AlkSize.productImageRadius),
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwItems / 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity, height: 15, color: Colors.white),
                  const SizedBox(height: AlkSize.spaceBtwItems / 4),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 12,
                      color: Colors.white),
                  const SizedBox(height: AlkSize.spaceBtwItems / 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: 18,
                          color: Colors.white),
                      Container(
                          width: AlkSize.iconLg * 1.2,
                          height: AlkSize.iconLg * 1.2,
                          color: Colors.white),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: AlkSize.sm),
          ],
        ),
      ),
    );
  }
}
