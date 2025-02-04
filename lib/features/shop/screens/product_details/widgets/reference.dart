import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/size.dart';

class AlkRef extends StatelessWidget {
    final String productReference;
    

  const AlkRef({
    super.key, required this.productReference, 
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Iconsax.document5, color: AlkColors.secondary, size: 25 ,),
        SizedBox(width: AlkSize.spaceBtwItems/2,),
        Text.rich(
          TextSpan(
            text: 'Référence : ',
            style: Theme.of(context).textTheme.labelMedium!.apply(color: AlkColors.darkGrey),
            children: [
              TextSpan(
                text: '${productReference} ' ,
                style: Theme.of(context).textTheme.labelMedium!.apply(color: AlkColors.darkGrey),
              )
            ]
          )
        )
      ],
    );
  }
}
