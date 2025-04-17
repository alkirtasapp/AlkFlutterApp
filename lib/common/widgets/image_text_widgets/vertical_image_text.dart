import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/size.dart';

class AlkVerticalImageText extends StatelessWidget {
  const AlkVerticalImageText({
    super.key,
    required this.title,
    required this.textColor,
    this.backgroundColor,
    this.onTap,
    this.icon = Icons.category,
  });

  final String title;
  final Color textColor;
  final Color? backgroundColor;
  final void Function()? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AlkSize.spaceBtwItems),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(AlkSize.sm),
              decoration: BoxDecoration(
                color: backgroundColor?.withOpacity(0.1) ?? Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                icon,
                color: textColor,
                size: 28,
              ),
            ),
            ///TEXT 
            const SizedBox(height: AlkSize.spaceBtwItems/2),
            SizedBox(
              width: 55,
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.apply(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}

