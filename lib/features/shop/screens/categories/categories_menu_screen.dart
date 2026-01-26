import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/features/shop/controllers/categories_store_controller.dart';
import 'package:alkirtas/common/widgets/shimmer/shimmer_list_tile.dart';
import 'package:alkirtas/navigation_menu.dart';

/// Full-screen Categories Menu that replaces Home tab
/// Selecting a category navigates to Store tab with that category
class CategoriesMenuScreen extends StatefulWidget {
  const CategoriesMenuScreen({super.key});

  @override
  State<CategoriesMenuScreen> createState() => _CategoriesMenuScreenState();
}

class _CategoriesMenuScreenState extends State<CategoriesMenuScreen> {
  final CategoriesStoreController _categoriesController = CategoriesStoreController();
  bool _isLoading = true;

  // Track expanded tiles
  final Set<int> _expandedMainCategories = {};
  final Set<int> _expandedSubcategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await _categoriesController.fetchAllCategories();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCategory(String categoryName, int categoryId, {List<String>? breadcrumb}) {
    final navController = Get.find<NavigationController>();
    navController.navigateToStoreDrawer(
      categoryId: categoryId,
      categoryName: categoryName,
      breadcrumb: breadcrumb,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingList()
                : _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.menu_1,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Parcourir les catégories',
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

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => const AlkShimmerListTile(),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: _categoriesController.mainCategories.length,
      itemBuilder: (context, index) {
        final entry = _categoriesController.mainCategories.entries.elementAt(index);
        return _buildMainCategoryTile(entry);
      },
    );
  }

  Widget _buildMainCategoryTile(MapEntry<String, int> category) {
    final isExpanded = _expandedMainCategories.contains(category.value);
    final hasChildren = _categoriesController.categoryTree.containsKey(category.value);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(category.value),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            // Delay setState to avoid calling during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  if (expanded) {
                    _expandedMainCategories.add(category.value);
                  } else {
                    _expandedMainCategories.remove(category.value);
                  }
                });
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AlkColors.AppFirstColor.withOpacity(0.1),
                  AlkColors.AppSecColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Iconsax.folder_2,
              color: AlkColors.AppSecColor,
              size: 22,
            ),
          ),
          title: GestureDetector(
            onTap: () => _navigateToCategory(category.key, category.value),
            child: Text(
              category.key,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          trailing: hasChildren
              ? Icon(
                  isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: AlkColors.AppSecColor,
                  size: 20,
                )
              : IconButton(
                  icon: Icon(
                    Iconsax.arrow_right_3,
                    color: AlkColors.AppSecColor,
                    size: 20,
                  ),
                  onPressed: () => _navigateToCategory(category.key, category.value),
                ),
          children: hasChildren
              ? [
                  for (var subcategory in _categoriesController.categoryTree[category.value]!)
                    _buildSubcategoryTile(category, subcategory),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(
    MapEntry<String, int> parentCategory,
    Map<String, dynamic> subcategory,
  ) {
    final subcategoryId = subcategory['id'] as int;
    final isExpanded = _expandedSubcategories.contains(subcategoryId);
    final hasChildren = _categoriesController.categoryTree.containsKey(subcategoryId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(subcategoryId),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            // Delay setState to avoid calling during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  if (expanded) {
                    _expandedSubcategories.add(subcategoryId);
                  } else {
                    _expandedSubcategories.remove(subcategoryId);
                  }
                });
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
          leading: Icon(
            Iconsax.folder_open,
            color: Colors.grey.shade600,
            size: 18,
          ),
          title: GestureDetector(
            onTap: () => _navigateToCategory(
              subcategory['name'],
              subcategoryId,
              breadcrumb: [parentCategory.key],
            ),
            child: Text(
              subcategory['name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          trailing: hasChildren
              ? Icon(
                  isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: Colors.grey.shade500,
                  size: 18,
                )
              : Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
          children: hasChildren
              ? [
                  for (var subSubcategory in _categoriesController.categoryTree[subcategoryId]!)
                    _buildSubSubcategoryTile(
                      subSubcategory,
                      parentName: parentCategory.key,
                      subcategoryName: subcategory['name'],
                    ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildSubSubcategoryTile(
    Map<String, dynamic> subSubcategory, {
    required String parentName,
    required String subcategoryName,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _navigateToCategory(
          subSubcategory['name'],
          subSubcategory['id'],
          breadcrumb: [parentName, subcategoryName],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                Iconsax.document,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subSubcategory['name'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
