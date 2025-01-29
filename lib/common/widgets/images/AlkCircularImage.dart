
import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';
import '../../../utils/helpers/helper_functions.dart';

class AlkCircularImage extends StatelessWidget {
  const AlkCircularImage({
    super.key, 
    this.fit = BoxFit.cover, 
    
    required this.isNetworkImage, 
    this.overlayColor, 
    this.backgroundColor, 
     this.width =56, 
     this.height = 56, 
     this.padding= AlkSize.sm,
      required this.image,
  });
  final BoxFit? fit;
  final String image;
  final bool isNetworkImage;
  final Color? overlayColor;
  final Color?backgroundColor;
  final double width , height, padding;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AlkHelperFunctions.isDarkMode(context) ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(180),
      ),
      child: Image(
        fit: fit ,
        image: isNetworkImage ? NetworkImage(image) : AssetImage(image) as ImageProvider,
        color: overlayColor, ),
      );
  }
}