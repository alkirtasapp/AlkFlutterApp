import 'package:flutter/material.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/products/cart/cart_menu_icon.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/backendData/userData.dart';

class AlkHomeAppBar extends StatelessWidget {
  const AlkHomeAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlkAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AlkTexts.homeAppBarSubitle,
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .apply(color: AlkColors.grey),
          ),
          Text(
            "${UserData.firstname} ",
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .apply(color: AlkColors.white),
          ),
        ],
      ),
      actions: [
        AlkCartCounterIcon(onPressed: (){},)
      ],
    );
  }
}
