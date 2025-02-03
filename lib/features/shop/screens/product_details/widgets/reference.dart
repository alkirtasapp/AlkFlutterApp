import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/size.dart';

class AlkRef extends StatelessWidget {
  const AlkRef({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Iconsax.document5, color: AlkColors.secondary, size: 25),
        SizedBox(width: AlkSize.spaceBtwItems/2,),
        Text.rich(
          TextSpan(
            text: 'Référence : ',
            style: Theme.of(context).textTheme.labelMedium!.apply(color: AlkColors.darkGrey),
            children: [
              TextSpan(
                text: '123456',
                style: Theme.of(context).textTheme.labelMedium!.apply(color: AlkColors.darkGrey),
              )
            ]
          )
        )
      ],
    );
  }
}
