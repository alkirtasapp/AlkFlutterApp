import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/size.dart';

class AlkRef extends StatelessWidget {
    final String productReference;
    final String title ;
    final IconData icon;
    final double size;
    

  const AlkRef({
    super.key, required this.productReference, required this.title, required this.icon, required this.size , 
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple.shade300, size: size ,),
        SizedBox(width: AlkSize.spaceBtwItems/2,),
        Text.rich(
          TextSpan(
            text: title,
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
