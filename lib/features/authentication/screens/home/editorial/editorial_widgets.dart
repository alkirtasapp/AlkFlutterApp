import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'editorial_product.dart';

Color editorialInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF192023);
Color editorialPaper(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252525)
        : const Color(0xFFF5F2EE);
TextStyle editorialTitle(BuildContext context) => TextStyle(
    fontFamily: 'Cairo',
    fontSize: 23,
    height: 1.35,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
    color: editorialInk(context));

class EditorialImage extends StatelessWidget {
  const EditorialImage(
      {super.key,
      required this.url,
      this.fallbackUrl = '',
      this.fit = BoxFit.cover,
      this.icon = Icons.shopping_bag_outlined});
  final String url, fallbackUrl;
  final BoxFit fit;
  final IconData icon;
  Widget _placeholder(BuildContext context) => ColoredBox(
      color: editorialPaper(context),
      child: Center(child: Icon(icon, size: 44, color: Colors.grey.shade400)));
  Widget _fallback(BuildContext context) =>
      fallbackUrl.isNotEmpty && fallbackUrl != url
          ? EditorialImage(url: fallbackUrl, fit: BoxFit.contain, icon: icon)
          : _placeholder(context);
  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _fallback(context);
    if (url.startsWith('lib/assets/')) {
      return Image.asset(url,
          fit: fit, errorBuilder: (_, __, ___) => _fallback(context));
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !['https', 'http'].contains(uri.scheme)) {
      return _fallback(context);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => _placeholder(context),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }
}

class EditorialProductCard extends StatelessWidget {
  const EditorialProductCard(
      {super.key, required this.product, this.onOpen, this.onAdd});
  final EditorialProduct product;
  final VoidCallback? onOpen, onAdd;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Material(
          color: editorialPaper(context),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onOpen ?? product.openDetails,
              child: Stack(fit: StackFit.expand, children: [
                EditorialImage(url: product.imageUrl, fit: BoxFit.cover),
                if (product.discountText.isNotEmpty)
                  Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: AlkColors.AppFirstColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('-${product.discountText}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      )),
              ])),
        )),
        const SizedBox(height: 9),
        InkWell(
            onTap: onOpen ?? product.openDetails,
            child: Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, height: 1.3, color: editorialInk(context)))),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (product.oldPrice.isNotEmpty)
                  Text('${product.oldPrice} TND',
                      style: const TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey)),
                Text('${product.newPrice} TND',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: editorialInk(context))),
              ])),
          IconButton.filled(
            style: IconButton.styleFrom(
                backgroundColor: AlkColors.AppFirstColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44)),
            tooltip: product.stock > 0
                ? 'Ajouter ${product.name} au panier'
                : 'Rupture de stock',
            onPressed: product.stock > 0
                ? (onAdd ?? () => product.addToCart(context))
                : null,
            icon: const Icon(Icons.add, size: 21),
          ),
        ]),
      ]);
}

class EditorialProductShelf extends StatelessWidget {
  const EditorialProductShelf(
      {super.key, required this.products, this.narrow = false});
  final List<EditorialProduct> products;
  final bool narrow;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = narrow
            ? (constraints.maxWidth / 2.7).clamp(122.0, 170.0)
            : (constraints.maxWidth / 2.12).clamp(145.0, 205.0);
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        return SizedBox(
          height: (narrow ? 260 : 290) + (scale - 1).clamp(0, 2) * 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
                width: width,
                child: EditorialProductCard(product: products[i])),
          ),
        );
      });
}

class EditorialCampaign extends StatelessWidget {
  const EditorialCampaign(
      {super.key,
      required this.image,
      required this.headline,
      required this.onTap,
      this.fallbackImage = '',
      this.background = const Color(0xFFF0DED2),
      this.cta = 'Explorer',
      this.icon = Icons.auto_awesome});
  final String image, headline, fallbackImage, cta;
  final Color background;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              return SizedBox(
                  height: 230 + (scale - 1).clamp(0, 2) * 85,
                  child: Stack(fit: StackFit.expand, children: [
                    if (image.isNotEmpty)
                      EditorialImage(
                          url: image, fallbackUrl: fallbackImage, icon: icon)
                    else
                      Positioned(
                          left: 0,
                          top: 18,
                          bottom: 18,
                          width: constraints.maxWidth * 0.48,
                          child: EditorialImage(
                              url: fallbackImage,
                              fit: BoxFit.contain,
                              icon: icon)),
                    Positioned.fill(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                      colors: [
                        background.withOpacity(0.02),
                        background.withOpacity(image.isNotEmpty ? 0.10 : 0.72),
                        background.withOpacity(image.isNotEmpty ? 0.30 : 0.97)
                      ],
                      stops: const [0, 0.5, 1],
                    )))),
                    Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: constraints.maxWidth *
                              (scale > 1.2 ? 0.68 : 0.54),
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 18, 18, 18),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(headline,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: editorialTitle(context).copyWith(
                                            fontSize: 22,
                                            color: const Color(0xFF332B27))),
                                    const SizedBox(height: 18),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: AlkColors.AppFirstColor,
                                            borderRadius:
                                                BorderRadius.circular(28)),
                                        child: Text('$cta  →',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13))),
                                  ])),
                        )),
                  ]));
            })),
      );
}
