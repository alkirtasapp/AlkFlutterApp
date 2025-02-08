import 'package:flutter/widgets.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/images_strings.dart';
import '../../../../utils/constants/size.dart';
import '../../images/AlkRoundedImages.dart';
import '../../texts/brand__title_text_verif_icon.dart';
import '../../texts/product_title_text.dart';

class AlkCartItem extends StatelessWidget {
  const AlkCartItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
    // image 
    AlkRoundedImage(imageUrl: AlkImages.darkAppLogo,
    width: 65,
    height: 65,
    padding: EdgeInsets.all(AlkSize.sm),
    backgroundColor: AlkColors.light,),
    const SizedBox(width: AlkSize.spaceBtwItems),
    // title , price 
    Expanded(
      
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start ,
        children: [
          const AlkBrandTitleTextVerifIcon(title: 'ALKIRTAS'),
          const Flexible(child: AlkProductTitleText(title: 'Product PlaceHolder', maxLines: 1,)),
          
        ],
      ),
    )
    
                  ]);
  }
}