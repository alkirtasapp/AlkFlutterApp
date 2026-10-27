import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alkirtas/services/notification_inbox_service.dart';
import 'package:alkirtas/services/push_notification_service.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';

/// Notifications sent from the back office during the last 30 days, so a
/// missed one can still be opened. Opened from Settings and the home bell.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await NotificationInboxService.refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(InboxNotification n) async {
    await NotificationInboxService.markRead(n);
    if (!mounted) return;
    setState(() {});
    if (!n.hasTarget) return;
    // Categories and tabs (cart, profile, menu) open under this screen, so
    // close it first; products and full screens open on top of it.
    if (!_opensOnTop(n.data)) Navigator.of(context).maybePop();
    PushNotificationService.onTap?.call(n.data);
  }

  static bool _opensOnTop(Map<String, dynamic> data) =>
      data.containsKey('product_id') ||
      const {'audiobooks', 'wishlist', 'coupons', 'orders'}
          .contains(data['screen']);

  @override
  Widget build(BuildContext context) {
    final items = NotificationInboxService.items;
    final hasUnread = items.any((n) => !NotificationInboxService.isRead(n));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tout marquer comme lu',
              onPressed: () async {
                await NotificationInboxService.markAllRead();
                if (mounted) setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            tooltip: 'État des notifications',
            onPressed: () => showNotificationStatusDialog(context),
          ),
        ],
      ),
      body: _loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Iconsax.notification, size: 56, color: AlkColors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Aucune notification pour le moment')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AlkSize.sm),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _NotificationTile(
                        notification: items[i],
                        read: NotificationInboxService.isRead(items[i]),
                        onTap: () => _open(items[i]),
                      ),
                    ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.read,
    required this.onTap,
  });

  final InboxNotification notification;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: read ? null : AlkColors.AppFirstColor.withOpacity(0.06),
        padding: const EdgeInsets.symmetric(
            horizontal: AlkSize.defaultSpace, vertical: AlkSize.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: CircleAvatar(
                radius: 4,
                backgroundColor:
                    read ? Colors.transparent : AlkColors.AppFirstColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: textTheme.titleSmall!.copyWith(
                        fontWeight: read ? FontWeight.w500 : FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(n.body, style: textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(_formatDate(n.date),
                      style: textTheme.labelSmall!.copyWith(color: AlkColors.grey)),
                ],
              ),
            ),
            if (n.imageUrl.isNotEmpty) ...[
              const SizedBox(width: AlkSize.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: n.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (n.hasTarget)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 18),
                child: Icon(Icons.chevron_right, color: AlkColors.grey),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

/// Whether this phone can receive pushes — for remote diagnosis.
Future<void> showNotificationStatusDialog(BuildContext context) async {
  final enabled = await PushNotificationService.areNotificationsEnabled();
  if (!context.mounted) return;

  Widget row(String label, bool ok, [String? detail]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.check_circle : Icons.cancel,
                color: ok ? Colors.green : Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(detail == null ? label : '$label\n$detail'),
            ),
          ],
        ),
      );

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Autorisées sur ce téléphone', enabled),
          row('Service de notifications connecté',
              PushNotificationService.isFirebaseReady),
          row('Inscrit aux annonces Alkirtas', PushNotificationService.subscribed),
          if (PushNotificationService.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                PushNotificationService.lastError!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
      actions: [
        if (!enabled)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Ouvrir les réglages'),
          ),
        if (PushNotificationService.isFirebaseReady &&
            !PushNotificationService.subscribed)
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await PushNotificationService.ensureSubscribed();
              if (context.mounted) showNotificationStatusDialog(context);
            },
            child: const Text('Réessayer'),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
