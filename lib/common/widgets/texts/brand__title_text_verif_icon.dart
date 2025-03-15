import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/enums.dart';

import 'brand_title_text.dart';

class AlkBrandTitleTextVerifIcon extends StatelessWidget {
  const AlkBrandTitleTextVerifIcon({super.key,
   required this.title, 
    this.maxline = 1 ,
    this.textColor ,
     this.iconColor =AlkColors.primaryColor, 
     this.textAlign = TextAlign.center,
       this.brandTextSize = TextSizes.small, Color? color});

  final String title;
  final int maxline ;
  final Color? textColor,iconColor;
  final TextAlign? textAlign;
  final TextSizes brandTextSize;


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AlkBrandTitleText(
            title:title,
            color:textColor,
            maxline: maxline,
            textAlign: textAlign,
            brandTextSize: brandTextSize,
            
            
            
          
            ),
            ),
            /*
            const SizedBox(width: AlkSize.sm,),
            Icon(Iconsax.verify5, color: iconColor, size: AlkSize.iconXs,)*/
      ],

    );
  }
}