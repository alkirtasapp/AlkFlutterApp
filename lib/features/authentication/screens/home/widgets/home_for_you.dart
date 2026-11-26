import 'package:flutter/material.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/services/personalization_service.dart';
import 'package:alkirtas/common/widgets/products/product_cards/category_product_card.dart';
import 'package:alkirtas/utils/constants/size.dart';

/// "Pour vous": books picked from the authors and categories the logged-in
/// customer viewed, wished for or bought (online and in store).
/// Hidden for guests and for customers with no history yet.
class HomeForYou extends StatefulWidget {
  const HomeForYou({super.key});
  @override
  State<HomeForYou> createState() => _HomeForYouState();
}

class _HomeForYouState extends State<HomeForYou> {
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (!PersonalizationService.isLoggedIn) return [];
    final ids = await PersonalizationService.recommendations(limit: 16);
    if (ids.isEmpty) return [];
    final enriched = await ProductEnrichedService.fetchEnrichedByIds(ids);
    return ids.where(enriched.containsKey).map((id) {
      final product =
          ProductEnrichedService.buildProductFromEnriched(enriched[id]!);
      final images = product['image_urls'] as List<String>? ?? [];
      return {
        ...product,
        'default_image_url': images.isEmpty ? '' : images.first
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _products,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        // Only show once there is something to show: no spinner, no error
        // box, so guests and new customers see no empty section.
        if (snapshot.connectionState != ConnectionState.done ||
            products.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AlkSize.defaultSpace, 0, 0, AlkSize.spaceBtwSections),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pour vous',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('Selon vos lectures, achats et votre liste d\'envies',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 310,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: AlkSize.defaultSpace),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => SizedBox(
                      width: 180,
                      child: CategoryProductCard(productData: products[index])),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
