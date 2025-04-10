// d:\flutter\test\lib\common\widgets\texts\section_heading.dart (Updated)
import 'package:flutter/material.dart';

class AlkSectionHeading extends StatelessWidget {
  const AlkSectionHeading({
    super.key,
    this.textColor,
    this.showActionButton = true,
    required this.title,
    this.buttonTitle = 'Voir tout',
    this.onPressed,
  });

  final Color? textColor;
  final bool showActionButton;
  final String title, buttonTitle;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      // *** Add this line to push children to opposite ends ***
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title (remains on the left)
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .apply(color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),

        // Action Button (will be pushed to the right)
        if (showActionButton)
          TextButton(onPressed: onPressed, child: Text(buttonTitle))
      ],
    );
  }
}
