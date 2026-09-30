import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HomeSellingFeed extends StatefulWidget {
  const HomeSellingFeed({super.key});

  @override
  State<HomeSellingFeed> createState() => _HomeSellingFeedState();
}

class _HomeSellingFeedState extends State<HomeSellingFeed> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductEnrichedService.fetchHomeSellingProducts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SellingFeedLoading();
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        final spotlight = _DealProduct.fromEnriched(products.first);
        final secondary =
            products.skip(1).take(4).map(_DealProduct.fromEnriched).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
          child: Column(
            children: [
              _SpotlightDeal(product: spotlight),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: secondary.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) =>
                        _SmallDealTile(product: secondary[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SpotlightDeal extends StatelessWidget {
  const _SpotlightDeal({required this.product});

  final _DealProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: AlkColors.AppFirstColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AlkColors.AppFirstColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: -18,
            bottom: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AlkColors.AppSecColor.withOpacity(0.45),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.flash_1,
                              color: Colors.white, size: 17),
                          const SizedBox(width: 5),
                          Text(
                            'Offre a saisir',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        product.stock <= 5
                            ? 'Dernieres pieces disponibles'
                            : product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (product.oldPrice.isNotEmpty)
                        Text(
                          '${product.oldPrice} TND',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white.withOpacity(0.72),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '${product.newPrice} TND',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AddButton(product: product, compact: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: product.openDetails,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 20, 14, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  )
                                : const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      if (product.discountText.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AlkColors.AppSecColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${product.discountText}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallDealTile extends StatelessWidget {
  const _SmallDealTile({required this.product});

  final _DealProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: product.openDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AlkColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlkColors.grey.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AlkColors.lightGrey,
                borderRadius: BorderRadius.circular(9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.discountText.isNotEmpty)
                    Text(
                      '-${product.discountText}',
                      style: TextStyle(
                        color: AlkColors.AppSecColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.08,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${product.newPrice} TND',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AlkColors.AppFirstColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _AddButton(product: product, compact: true),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product, required this.compact});

  final _DealProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: AlkColors.AppSecColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => product.addToCart(context),
          icon: const Icon(Iconsax.add, size: 18),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => product.addToCart(context),
      icon: const Icon(Iconsax.shopping_cart, size: 16),
      label: const Text('Ajouter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AlkColors.AppFirstColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DealProduct {
  _DealProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.reference,
    required this.description,
    required this.stock,
    required this.imageUrl,
    required this.imageUrls,
    required this.discountText,
    required this.oldPrice,
    required this.newPrice,
  });

  final String id;
  final String name;
  final String brand;
  final String brandId;
  final String reference;
  final String description;
  final int stock;
  final String imageUrl;
  final List<String> imageUrls;
  final String discountText;
  final String oldPrice;
  final String newPrice;

  factory _DealProduct.fromEnriched(Map<String, dynamic> enriched) {
    final product = ProductEnrichedService.buildProductFromEnriched(enriched);
    final imageUrls = (product['image_urls'] as List<String>?) ?? [];
    final taxGroup = product['id_tax_rules_group'] as int? ?? 0;
    final basePrice = taxGroup == 0
        ? (product['price'] as double? ?? 0.0)
        : (product['ttc_price'] as double? ?? 0.0);
    final discount = product['discount'] as double? ?? 0.0;
    final finalPrice =
        discount > 0 ? basePrice * (1 - discount / 100) : basePrice;

    return _DealProduct(
      id: product['id'].toString(),
      name: product['name'].toString(),
      brand: product['manufacturer_name'].toString(),
      brandId: product['id_manufacturer'].toString(),
      reference: product['reference'].toString(),
      description: product['description_short'].toString(),
      stock: int.tryParse(product['quantity'].toString()) ?? 0,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls,
      discountText: discount > 0 ? '${discount.toStringAsFixed(0)}%' : '',
      oldPrice: discount > 0 ? basePrice.toStringAsFixed(2) : '',
      newPrice: finalPrice.toStringAsFixed(2),
    );
  }

  void openDetails() {
    Get.to(() => ProductDetails(
          productId: id,
          productName: name,
          productReference: reference,
          productDiscount: discountText,
          productBrand: brand,
          productBrandId: brandId,
          productOldPrice: oldPrice,
          productNewPrice: newPrice,
          productDescription: description,
          productImage: imageUrl,
          productImageList: imageUrls,
          productStock: stock.toString(),
        ));
  }

  void addToCart(BuildContext context) {
    if (UserData.id.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
              'Vous devez etre connecte pour ajouter des articles au panier.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AlkColors.AppFirstColor),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.to(() => LoginScreen());
              },
              child: const Text('Se connecter',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    context.read<CartProvider>().addToCart(
          productId: id,
          productName: name,
          productBrand: brand,
          productImage: imageUrl,
          productPrice: newPrice,
          productDiscount: discountText,
          productBrandId: brandId,
          productOldPrice: oldPrice,
          productNewPrice: newPrice,
          productStock: stock.toString(),
          productDescription: description,
          productReference: reference,
          productImageList: imageUrls,
          productFeatures: const [],
          quantity: 1,
        );

    Get.snackbar(
      'Produit ajoute',
      '$name a ete ajoute au panier',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: AlkColors.success,
      colorText: Colors.white,
    );
  }
}

class _SellingFeedLoading extends StatelessWidget {
  const _SellingFeedLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AlkSize.sm),
      child: Container(
        height: 236,
        decoration: BoxDecoration(
          color: AlkColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlkColors.grey),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
