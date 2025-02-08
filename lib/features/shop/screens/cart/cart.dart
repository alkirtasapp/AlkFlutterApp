import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/icons/circularIcons.dart';
import 'package:test/common/widgets/images/AlkRoundedImages.dart';
import 'package:test/common/widgets/texts/brand__title_text_verif_icon.dart';
import 'package:test/common/widgets/texts/product_title_text.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/images_strings.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/products/cart/add_remove_button.dart';
import '../../../../common/widgets/products/cart/cartItem.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlkAppBar(
          showBackArrow: true,
          title:
              Text('Panier', style: Theme.of(context).textTheme.headlineSmall)),
      body: Padding(
        padding: EdgeInsets.all(AlkSize.defaultSpace),
        child: ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(
            height: AlkSize.spaceBtwSections,
          ),
          itemCount: 5,
          itemBuilder: (_, index) => Column(
            children: [
              AlkCartItem(),
              SizedBox(
                height: AlkSize.spaceBtwItems,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      //extraSpace
                      const SizedBox(width: 70),
                      // add and remove button
                  AlkProductQuantityAddRemove(),
                    ],
                  ),
                  
                  Text('10 TND '),
                 
                ],
                
              ),
              
              
            ],
            
          ),
          
        ),
      
        
      ),
      
    
    );
  }
}

