import 'package:flutter/material.dart%20';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/size.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../roundedContainer.dart';

class AlkBrandShowcase extends StatelessWidget {
  const AlkBrandShowcase({
    super.key, 
    required this.images,
  });

  final List<String > images ;

  @override
  Widget build(BuildContext context) {
    return AlkRoundedContainer(
      showBorder: true,
      borderColor: AlkColors.darkGrey,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.all(AlkSize.sm),
      margin:
          const EdgeInsets.only(bottom: AlkSize.spaceBtwItems),
      child: Column(
        children: [
          //brands wit product contianer
          // brand top 3 product images
          Row(
            children:
              images.map((image)=> brandTopProductImageWidget(image, context)).toList(),
           
          )
        ],
      ),
    );
  }
}
Widget brandTopProductImageWidget (String image , context){
  return Expanded(
                child: AlkRoundedContainer(
                  height: 100,
                  backgroundColor:
                      AlkHelperFunctions.isDarkMode(context)
                          ? Colors.black
                          : Colors.white,
                  margin:
                      const EdgeInsets.only(right: AlkSize.sm),
                  padding: const EdgeInsets.all(AlkSize.sm),
                  child: Image(
                    fit: BoxFit.contain,
                    image: AssetImage(image),
                  ),
                ),
              );
}