import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/roundedContainer.dart';
import 'package:alkirtas/common/widgets/texts/section_heading.dart';
import 'package:alkirtas/utils/constants/size.dart';

class ProductAttributes extends StatelessWidget {
  const ProductAttributes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //selected Attribute pricing and Description 
        AlkRoundedContainer(
          backgroundColor: Colors.grey,
          child: Column(
            children: [
              /// Title , price and stock 
              Row(
                children: [
                AlkSectionHeading(title: 'Variation', showActionButton: false,),
                SizedBox(width: AlkSize.spaceBtwItems),


                Row(
                 /// Actuall price 
                 

                )
                ],
              ) 
              
              /// description 
              
            ],
          ),
        )
      ],
    );
  }
}