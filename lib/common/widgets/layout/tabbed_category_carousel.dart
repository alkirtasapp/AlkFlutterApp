// lib/common/widgets/layout/tabbed_category_carousel.dart
import 'package:flutter/material.dart';
import '../../../models/home_section.dart';
import '../../../features/shop/controllers/category_product_controller.dart';
import 'category_carousel_layout.dart';
import '../../../utils/constants/colors.dart';

class TabbedCategoryCarousel extends StatefulWidget {
  final HomeSection section;
  final int itemsPerCategory;

  const TabbedCategoryCarousel({
    Key? key,
    required this.section,
    this.itemsPerCategory = 8,
  }) : super(key: key);

  @override
  State<TabbedCategoryCarousel> createState() => _TabbedCategoryCarouselState();
}

class _TabbedCategoryCarouselState extends State<TabbedCategoryCarousel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, List<Map<String, dynamic>>> _categoryProducts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.section.tabs.length, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    for (var tab in widget.section.tabs) {
      final products =
          await CategoryProductController.fetchProductsFromCategories(
              [tab.categoryId], widget.itemsPerCategory);
      if (mounted) {
        setState(() {
          _categoryProducts[tab.categoryId] = products;
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Center(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 1],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.section.icon,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.section.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tab Bar (only if there are multiple tabs)
        if (widget.section.tabs.length > 1)
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    surfaceVariant: Colors.transparent,
                  ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AlkColors.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AlkColors.primaryColor,
              tabs: widget.section.tabs
                  .map((tab) => Tab(text: tab.name))
                  .toList(),
            ),
          ),

        // Product Carousel
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: widget.section.tabs.map((tab) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = _categoryProducts[tab.categoryId] ?? [];

              return AlkCategoryCarouselLayout(
                itemCount: products.length,
                productsPerPage: 2,
                categoryId: tab.categoryId,
                horizontalPadding: 8,
                autoSwipeDuration:
                    Duration(milliseconds: 5000 + (tab.categoryId % 5 * 900)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
