import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/icons/circularIcons.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';

class AlkBottomAddToCart extends StatelessWidget {
  const AlkBottomAddToCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace, vertical: AlkSize.defaultSpace /2),
      decoration: BoxDecoration(
        color: AlkColors.light,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(AlkSize.cardRadiusLg), 
          topRight: Radius.circular(AlkSize.cardRadiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        
        children: [
          Row(
              
            children: [
              AlkCircularIcon(
                icon: Iconsax.minus, 
                size: 25,
                backgroundColor: Colors.purple,
                height: 40,
                width: 40,
                color: Colors.white,
              ),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text('1',style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AlkSize.spaceBtwItems),
                AlkCircularIcon(
                icon: Iconsax.add, 
                size: 25,
                backgroundColor: Colors.purple,
                height: 40,
                width: 40,
                color: Colors.white,
              ),
              ],
          ),
              ElevatedButton(onPressed: (){}, 
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(AlkSize.md),
                backgroundColor: AlkColors.primaryColor,
                side: const BorderSide(color: Colors.black)
              ),
              child: const Text('Ajouter au Panier'),
              )
            ]
          ),
       
      );
  
  }
}