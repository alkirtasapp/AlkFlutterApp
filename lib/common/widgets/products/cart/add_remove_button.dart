import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/size.dart';
import '../../icons/circularIcons.dart';

class AlkProductQuantityAddRemove extends StatelessWidget {
  const AlkProductQuantityAddRemove({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AlkCircularIcon(
          icon: Iconsax.minus,
          width: 32,
          height: 32,
          size: AlkSize.md,
          color: Colors.white,
          backgroundColor: Colors.grey.shade400,
        ),
        const SizedBox(width: AlkSize.spaceBtwItems),
        Text(
          '1',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(width: AlkSize.spaceBtwItems),
        AlkCircularIcon(
          icon: Iconsax.add,
          width: 32,
          height: 32,
          size: AlkSize.md,
          color: Colors.white,
          backgroundColor: AlkColors.AppSecColor.withOpacity(0.5),
        ),
      ],
    );
  }
}
