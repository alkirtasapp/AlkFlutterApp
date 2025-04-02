import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/products/cart/cart_menu_icon.dart';
import '../../../../../navigation_menu.dart'; // Import NavigationMenu
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/backendData/userData.dart';

class AlkHomeAppBar extends StatelessWidget {
  const AlkHomeAppBar({
    super.key,
    this.showCartIcon = true,
  });
   final bool showCartIcon;

  @override
  Widget build(BuildContext context) {
    return AlkAppBar(
      showBackArrow: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AlkTexts.homeAppBarSubitle,
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .apply(color: AlkColors.grey),
          ),
          Text(
            utf8.decode(UserData.firstname.runes.toList()),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: AlkColors.white,
                  fontFamily: 'Cairo', // Explicitly set the Cairo font
                ),
          ),
        ],
      ),
      actions: [
         if (showCartIcon)
        AlkCartCounterIcon(
          onPressed: () {
            // Navigate to NavigationMenu and show the cart screen
             Get.offAll(() => const NavigationMenu(selectedMenu: 2));
          },
        ),
      ],
    );
  }
}

/// 1. Import the required libraries
/// 2. Create a personalized app bar with a CartCounterIcon
/// 3. Show the user's first name from UserData class


/// 1. Import the required libraries
/// 2. Create a personalized app bar with a CartCounterIcon
/// 3. Show the user's first name from UserData class
