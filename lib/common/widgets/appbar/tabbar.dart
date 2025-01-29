import 'package:flutter/material.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/device/device_utility.dart';
import 'package:test/utils/helpers/helper_functions.dart';

class AlkTabBar extends StatelessWidget implements PreferredSizeWidget  {
    final List<Widget> tabs; 


  const AlkTabBar({
  super.key,
  required this.tabs});

  @override
  Widget build(BuildContext context) {
    final dark =AlkHelperFunctions.isDarkMode(context);
    
    return Material(
      color: dark ? AlkColors.black : AlkColors.white,
      child:TabBar(
        tabs: tabs,
       isScrollable: true,
       indicatorColor: AlkColors.primaryColor,
       labelColor: dark ? AlkColors.white : AlkColors.primaryColor,
        unselectedLabelColor: AlkColors.darkGrey,


)


    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(AlkDeviceUtils.getAppBarHeight());
}