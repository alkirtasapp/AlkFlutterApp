import 'package:alkirtas/common/widgets/layout/category_carousel_layout.dart';
import 'package:alkirtas/common/widgets/texts/section_heading.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BestSellersSection extends StatelessWidget {
  const BestSellersSection({
    super.key,
    required this.categoryId,
    required this.context,
    required this.title,
    required this.icon,
    required this.productsPerPage
  });

  final int categoryId;
  final BuildContext context;
  final String title;
  final Icon icon;
  final int productsPerPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Further reduced bottom padding below the special section
      padding: const EdgeInsets.only(
        bottom: AlkSize.spaceBtwItems / 2, // Was AlkSize.spaceBtwItems
        left: AlkSize.sm,
        right: AlkSize.sm,
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: AlkSize.md,
          left: AlkSize.md,
          right: AlkSize.md,
          bottom: AlkSize.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 202, 117, 218), Colors.deepPurple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.2, 0.8],
          ),
          borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
          boxShadow: [
            BoxShadow(
              color: AlkColors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading for Top Selling Books
            AlkSectionHeading(
              icon:  icon,
              title: title,
              textColor: AlkColors.white,
              showActionButton: false,
            ),
            Divider(
              color: AlkColors.white.withOpacity(0.4),
              height: AlkSize.spaceBtwSections * 0.8,
              thickness: 0.5,
            ),
            // --- Grid Implementation ---
            AlkCategoryCarouselLayout(
              key: ValueKey('grid_$categoryId'),
              categoryId: categoryId,
              itemCount: 6,
             
              productsPerPage: productsPerPage, 
              horizontalPadding: AlkSize.sm,
              verticalPadding: AlkSize.sm,
              autoSwipeDuration: const Duration(seconds: 10),
            ),
          ],
        ),
      ),
    );
  }
}
