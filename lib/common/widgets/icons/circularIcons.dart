import 'package:flutter/material.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/utils/helpers/helper_functions.dart';


class AlkCircularIcon extends StatelessWidget {
  const AlkCircularIcon({
    super.key,
     this.width,
      this.height,
       this.size = AlkSize.xs,
        required this.icon,
         this.color,
          this.backgroundColor, 
          this.onPressed, 

  });
  final double? width,height, size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;


  @override
  Widget build(BuildContext context) {
    return Container(

        width: width,
        height: height, 
       decoration: BoxDecoration(
        color :backgroundColor != null ?backgroundColor! : AlkHelperFunctions.isDarkMode(context)? Colors.transparent:Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        

       ),
       child: IconButton(onPressed: onPressed, icon:  Icon(icon , color: color , size: size),
       ),
    );
  }
}
