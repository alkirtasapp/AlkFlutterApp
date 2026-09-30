import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/common/widgets/products/product_cards/category_product_card.dart';

class HomeNewArrivals extends StatefulWidget {
  const HomeNewArrivals({super.key});
  @override
  State<HomeNewArrivals> createState() => _HomeNewArrivalsState();
}

class _HomeNewArrivalsState extends State<HomeNewArrivals> {
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await http
        .get(Uri.parse(AppConfig.prestashopUrl('products', params: {
          'display': '[id]',
          'filter[active]': '[1]',
          'sort': '[date_add_DESC,id_DESC]',
          'limit': '24',
        })))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('New arrivals unavailable');
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final rows = decoded['products'] as List<dynamic>? ?? [];
    final ids = rows.map((row) => int.parse(row['id'].toString())).toList();
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

  void _showAll(List<Map<String, dynamic>> products) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Nouveautés')),
              body: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 650 ? 4 : 2,
                          mainAxisExtent: 310,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, index) =>
                            CategoryProductCard(productData: products[index]),
                      )),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton.icon(
            onPressed: () => setState(() => _products = _load()),
            icon: const Icon(Icons.refresh),
            label: const Text('Recharger les nouveautés'),
          );
        }
        final products = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.done &&
            products.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Nouveautés',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700))),
            TextButton(
                onPressed: products.isEmpty ? null : () => _showAll(products),
                child: const Text('Voir tout')),
          ]),
          Text('Les dernières pièces à découvrir',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
              height: 310,
              child: snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.take(8).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => SizedBox(
                          width: 180,
                          child: CategoryProductCard(
                              productData: products[index])),
                    )),
        ]);
      },
    );
  }
}
