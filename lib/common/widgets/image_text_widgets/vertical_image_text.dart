import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/size.dart';

class AlkVerticalImageText extends StatelessWidget {
  const AlkVerticalImageText({
    super.key, required this.title, required this.textColor, this.backgroundColor, this.onTap,
  });

  final String   title ;
  final Color textColor ;
  final Color? backgroundColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ,
      child: Padding(
        padding: const EdgeInsets.only(right: AlkSize.spaceBtwItems),
        child: Column(
        children: [  
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(AlkSize.sm),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: 
            Center(
              child: Image (image: AssetImage(AlkImages.darkAppLogo),fit: BoxFit.cover, color :AlkColors.white),
            ),
          ),
          ///TEXT 
           const SizedBox(height: AlkSize.spaceBtwItems/2),
           SizedBox(
           width :55 ,
             child: 
              Text(title ,style: Theme.of(context).textTheme.labelMedium!.apply(color: textColor),
           maxLines: 1,
           overflow: TextOverflow.ellipsis,),
           )
        ],
                                  ),
      ),
    );
  }
}

