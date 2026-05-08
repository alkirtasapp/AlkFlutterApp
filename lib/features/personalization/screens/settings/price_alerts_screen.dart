import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../providers/price_alert_provider.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Get.back(),
        ),
        title: const Text('Mes alertes prix'),
        actions: [
          Consumer<PriceAlertProvider>(
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
                tooltip: 'Vérifier les prix maintenant',
                onPressed: () =>
                    Provider.of<PriceAlertProvider>(context, listen: false)
                        .checkPriceDrops(),
              );
            },
          ),
        ],
      ),
      body: Consumer<PriceAlertProvider>(
        builder: (context, provider, _) {
          if (provider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification_bing,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte configurée',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activez la cloche sur un produit\npour être notifié d\'une baisse de prix.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AlkSize.defaultSpace),
            itemCount: provider.alerts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AlkSize.spaceBtwItems),
            itemBuilder: (context, i) {
              final alert = provider.alerts[i];
              return _AlertTile(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final WatchedProduct alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

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
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: alert.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: alert.imageUrl,
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

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.productName,
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
                        'Alerte à ${alert.watchedPrice.toStringAsFixed(2)} TND',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ajoutée le ${_formatDate(alert.addedAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Iconsax.trash,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Supprimer l\'alerte',
              onPressed: () =>
                  Provider.of<PriceAlertProvider>(context, listen: false)
                      .removeAlert(alert.productId),
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
