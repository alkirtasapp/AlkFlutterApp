import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/personalization/screens/settings/notifications_screen.dart';
import '../../../services/notification_inbox_service.dart';
import '../../../utils/constants/colors.dart';

/// Bell opening the notification history, with the unread count.
class AlkNotificationBellIcon extends StatelessWidget {
  const AlkNotificationBellIcon({super.key, this.iconColor = Colors.white});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Get.to(() => const NotificationsScreen()),
          tooltip: 'Notifications',
          icon: Icon(Iconsax.notification, color: iconColor),
        ),
        Positioned(
          right: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationInboxService.unreadCount,
            builder: (context, count, _) {
              if (count == 0) return const SizedBox.shrink();
              return Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AlkColors.AppSecColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .apply(color: AlkColors.white, fontSizeFactor: 0.8),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
