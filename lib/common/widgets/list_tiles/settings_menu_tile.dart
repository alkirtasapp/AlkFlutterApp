import 'package:flutter/material.dart';
import 'package:test/utils/constants/colors.dart';

class AlkSettingMenuTile extends StatelessWidget {
  const AlkSettingMenuTile({super.key, required this.icon, required this.title, required this.subtitle, this.trailing,
    });
      final IconData icon;
    final String title;
    final String subtitle;
    final Widget? trailing;


  @override
  Widget build(BuildContext context) {
  
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: AlkColors.primaryColor,
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .apply(color: AlkColors.darkGrey),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .labelMedium!
            .apply(color: AlkColors.darkGrey),
      ),
      trailing: trailing,
    );
  }
}
