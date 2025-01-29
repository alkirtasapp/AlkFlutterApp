import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';

class AlkSearchContainer extends StatelessWidget {
  const AlkSearchContainer({
    super.key,
     required this.text,
      this.icon, 
       this.showBackground =true , 
        this.showBorder = true,
        this.onTap, 
        this.padding = const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
  });

  final String text;
  final IconData? icon;
  final bool showBackground,showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = AlkHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        
        padding: padding,
        child: Container(
          width: AlkDeviceUtils.getScreenWidth(context),
          padding: EdgeInsets.all(AlkSize.md),
          decoration: BoxDecoration(
            color: showBackground ? dark ? AlkColors.dark :AlkColors.light: Colors.transparent,
            borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
            border:showBorder ?  Border.all(color: AlkColors.grey ): null,
          ),
          child: Row(
            children: [
              Icon(icon, color:  AlkColors.darkerGrey),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text(text , style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
