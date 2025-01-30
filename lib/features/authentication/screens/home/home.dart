import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';

import '../../../../common/widgets/custom_shapes/containers/searchContainer.dart';
import '../../../../common/widgets/layout/grid_layout.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import 'widgets/bannerSlider.dart';
import 'widgets/homeAppBar.dart';
import 'widgets/homeCategories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header --
            AlkPrimaryHeaderContainer(
              child: Column(
                children: [
                  //APP BAR
                  const AlkHomeAppBar(),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  // SEARCH BAR
                  const AlkSearchContainer(text: 'Recherche',  icon: Iconsax.search_normal, ),
                  const SizedBox(height: AlkSize.spaceBtwSections),

                  //CATEGORIES
                  Padding(padding: 
                  EdgeInsets.only(left: AlkSize.defaultSpace),
                  child: Column(
                    children: [

                      ///Heading
                      AlkSectionHeading(title: 'Nos Catégories : ',
                      textColor: Colors.white,
                       showActionButton: false,),
                      const SizedBox(height: AlkSize.spaceBtwItems), 

                      ///Catégories
                      AlkHomeCategories(),
                      ],
                  ),
                  ),
                ],
              ),
            ),




            /// Body 
            Padding(
              padding: const EdgeInsets.all(AlkSize.sm),
              child:Column(
                children: [

              // Banner Slider
                const AlkBannerSlider(),
                const SizedBox(height: AlkSize.spaceBtwSections/1.5),

              // heading 
              const AlkSectionHeading(title: 'Produits populaires :',showActionButton: false, ),
              const SizedBox(height: AlkSize.spaceBtwSections/1.5),

                

              //Products Home Page

              AlkGridLayout(itemCount: 10),
             
              

                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}



