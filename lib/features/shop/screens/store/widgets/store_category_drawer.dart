import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../../../common/widgets/shimmer/shimmer_list_tile.dart';
import '../controllers/store_controller.dart';

/// Category navigation drawer with 3-level hierarchy
/// Displays main categories, subcategories, and sub-subcategories
class StoreCategoryDrawer extends StatelessWidget {
  const StoreCategoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return ListView.builder(
            itemCount: 8,
            itemBuilder: (_, __) => const AlkShimmerListTile(),
          );
        }

        return Column(
          children: [
            _buildDrawerHeader(),
            _buildBreadcrumb(context, controller),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _buildCategoryList(context, controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AlkColors.AppFirstColor,
            AlkColors.AppSecColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.category,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Parcourir nos produits',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, StoreController controller) {
    if (controller.navigationStack.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.purple.shade50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.navigateBack();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: AlkColors.AppSecColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Retour vers ${controller.navigationStack.last}',
                    style: TextStyle(
                      color: AlkColors.AppSecColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AlkColors.AppSecColor.withOpacity(0.50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, StoreController controller) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (var category in controller.categoriesController.mainCategories.entries)
          _buildMainCategoryTile(context, controller, category),
      ],
    );
  }

  Widget _buildMainCategoryTile(
    BuildContext context,
    StoreController controller,
    MapEntry<String, int> category,
  ) {
    final isSelected =
        controller.selectedCategoryId == category.value && controller.navigationStack.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.purple.shade50 : Colors.transparent,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.purple.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.folder_2,
              color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade700,
              size: 20,
            ),
          ),
          title: GestureDetector(
            onTap: () {
              controller.selectCategory(category.key, category.value);
              Navigator.pop(context);
            },
            child: Text(
              category.key,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
                color: isSelected ? AlkColors.AppSecColor: Colors.grey.shade800,
              ),
            ),
          ),
          iconColor: AlkColors.AppSecColor,
          collapsedIconColor: Colors.grey.shade600,
          children: [
            if (controller.categoriesController.categoryTree.containsKey(category.value))
              for (var subcategory
                  in controller.categoriesController.categoryTree[category.value]!)
                _buildSubcategoryTile(context, controller, category, subcategory),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(
    BuildContext context,
    StoreController controller,
    MapEntry<String, int> parentCategory,
    Map<String, dynamic> subcategory,
  ) {
    final isSelected = controller.selectedCategoryId == subcategory['id'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected ? Colors.purple.shade50 : Colors.transparent,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.only(left: 8),
          leading: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Iconsax.category_2,
              color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade500,
              size: 16,
            ),
          ),
          title: GestureDetector(
            onTap: () {
              controller.navigateToSubcategory(
                parentCategory.key,
                parentCategory.value,
                subcategory['name'],
                subcategory['id'],
              );
              Navigator.pop(context);
            },
            child: Text(
              subcategory['name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade700,
              ),
            ),
          ),
          iconColor: AlkColors.AppSecColor,
          collapsedIconColor: Colors.grey.shade500,
          children: [
            if (controller.categoriesController.categoryTree.containsKey(subcategory['id']))
              for (var subSubcategory
                  in controller.categoriesController.categoryTree[subcategory['id']]!)
                _buildSubSubcategoryTile(
                  context,
                  controller,
                  parentCategory,
                  subcategory,
                  subSubcategory,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSubcategoryTile(
    BuildContext context,
    StoreController controller,
    MapEntry<String, int> parentCategory,
    Map<String, dynamic> subcategory,
    Map<String, dynamic> subSubcategory,
  ) {
    final isSelected = controller.selectedCategoryId == subSubcategory['id'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          controller.navigateToSubSubcategory(
            parentCategory.key,
            parentCategory.value,
            subcategory['name'],
            subcategory['id'],
            subSubcategory['name'],
            subSubcategory['id'],
          );
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? Colors.purple.shade50 : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subSubcategory['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade600,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AlkColors.AppSecColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
