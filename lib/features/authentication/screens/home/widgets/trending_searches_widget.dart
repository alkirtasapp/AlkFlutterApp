import 'package:alkirtas/common/widgets/shimmer/shimmer_effect.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TrendingSearchesWidget extends StatefulWidget {
  const TrendingSearchesWidget({super.key});

  @override
  State<TrendingSearchesWidget> createState() => _TrendingSearchesWidgetState();
}

class _TrendingSearchesWidgetState extends State<TrendingSearchesWidget> {
  List<Map<String, dynamic>> trendingSearches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingSearches();
  }

  Future<void> _loadTrendingSearches() async {
    final trending = await ProductEnrichedService.getTrendingSearches(limit: 3);
    setState(() {
      trendingSearches = trending.take(3).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
        child: AlkShimmerEffect(width: double.infinity, height: 80),
      );
    }

    if (trendingSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Iconsax.trend_up, size: 18, color: AlkColors.AppFirstColor),
              const SizedBox(width: 6),
              Text(
                'Trending',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AlkSize.sm + 2),

          // Horizontal scrollable chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingSearches.length,
              separatorBuilder: (_, __) => const SizedBox(width: AlkSize.sm),
              itemBuilder: (context, index) {
                return _buildChip(trendingSearches[index], index);
              },
            ),
          ),
          const SizedBox(height: AlkSize.spaceBtwItems),
        ],
      ),
    );
  }

  Widget _buildChip(Map<String, dynamic> trend, int index) {
    String displayQuery = trend['display_query']?.toString() ?? '';

    // Decode Unicode escape sequences for Arabic text
    if (displayQuery.contains('\\u')) {
      displayQuery = displayQuery.replaceAllMapped(
        RegExp(r'\\u([0-9a-fA-F]{4})'),
        (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
      );
    }

    final searches = int.tryParse(trend['total_searches'].toString()) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSearchResults(displayQuery),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AlkColors.AppFirstColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AlkColors.AppFirstColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.search_normal_1,
                size: 14,
                color: AlkColors.AppFirstColor,
              ),
              const SizedBox(width: 6),
              Text(
                displayQuery,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AlkColors.AppFirstColor,
                ),
              ),
              if (searches > 1) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AlkColors.AppFirstColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$searches',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AlkColors.AppFirstColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSearchResults(String query) {
    final navController = Get.find<NavigationController>();
    navController.navigateToStoreDrawer(searchQuery: query);
  }
}
