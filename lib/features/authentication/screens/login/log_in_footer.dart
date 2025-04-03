import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';

class AlkLoginFooter extends StatelessWidget {
  const AlkLoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AlkColors.grey),
            borderRadius: BorderRadius.circular(100),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: AlkSize.iconMd,
              height: AlkSize.iconMd,
              image: AssetImage(AlkImages.google),
            ),
          ),
        ),
        const SizedBox(width: AlkSize.spaceBtwItems),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AlkColors.grey),
            borderRadius: BorderRadius.circular(100),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: AlkSize.iconMd,
              height: AlkSize.iconMd,
              image: AssetImage(AlkImages.facebook),
            ),
          ),
        ),
      ],
    );
  }
}
