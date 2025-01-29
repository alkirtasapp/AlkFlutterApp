import 'package:flutter/material.dart';
import 'package:test/utils/constants/enums.dart';

class AlkBrandTitleText extends StatelessWidget {
  const AlkBrandTitleText({super.key,
   this.color, 
   required this.title,
     this.maxLine =1 ,
     this.textAlign = TextAlign.center,
       this.brandTextSize = TextSizes.small,  int maxline =1 });


  final Color? color ;
  final String title;
  final int maxLine;
  final TextAlign? textAlign;
  final TextSizes brandTextSize;


  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
      
      // check which brandSize is required and set the style 
      style: brandTextSize==TextSizes.small
      ? Theme.of(context).textTheme.labelMedium!.apply(color: color)
      : brandTextSize == TextSizes.medium 
      ? Theme.of(context).textTheme.bodyLarge!.apply(color: color) 
      :brandTextSize == TextSizes.large
      ? Theme.of(context).textTheme.titleLarge!.apply(color: color)
      : Theme.of(context).textTheme.bodyMedium!.apply(color: color),
    );
  }
}