import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../providers/wishlist_provider.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Ma liste de souhaits'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, provider, _) {
              if (provider.isChecking) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Iconsax.refresh),
                tooltip: 'Vérifier maintenant',
                onPressed: () =>
                    Provider.of<WishlistProvider>(context, listen: false)
                        .checkUpdates(),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          if (provider.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AlkSize.defaultSpace),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.notification_bing,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Liste vide',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activez la cloche sur un produit pour être notifié si le prix baisse ou si le produit revient en stock.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AlkSize.defaultSpace),
            itemCount: provider.items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AlkSize.spaceBtwItems),
            itemBuilder: (context, i) {
              final item = provider.items[i];
              return _WishlistTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  const _WishlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inStock = item.lastKnownStock > 0;
    final stockUnknown = item.lastKnownStock < 0;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AlkColors.darkerGrey : AlkColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Iconsax.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Iconsax.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Iconsax.notification_bing,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Alerte à ${item.watchedPrice.toStringAsFixed(2)} TND',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!stockUnknown)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (inStock ? Colors.green : Colors.red)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inStock ? 'En stock' : 'Hors stock',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: inStock
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  if (!stockUnknown) const SizedBox(height: 2),
                  Text(
                    'Ajoutée le ${_formatDate(item.addedAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.trash,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Retirer',
              onPressed: () =>
                  Provider.of<WishlistProvider>(context, listen: false)
                      .removeItem(item.productId),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}
