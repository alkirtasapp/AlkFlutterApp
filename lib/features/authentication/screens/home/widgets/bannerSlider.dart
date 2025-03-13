// ignore: file_names

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:test/features/shop/controllers/home_controller.dart';
import 'package:test/utils/constants/colors.dart';

import '../../../../../common/widgets/custom_shapes/containers/circular_container.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/images_strings.dart';  
import '../../../../../utils/constants/size.dart';

class AlkBannerSlider extends StatelessWidget {
  const AlkBannerSlider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put (HomeController());
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100)
      ),
      child: Column(
        
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1000)
            ),
            child: CarouselSlider(
             items: [
               
               AlkRoundedImage(imageUrl: AlkImages.banner2),
               AlkRoundedImage(imageUrl: AlkImages.banner3),
               AlkRoundedImage(imageUrl: AlkImages.banner4),
               AlkRoundedImage(imageUrl: AlkImages.banner5),
             ],
              options: CarouselOptions(
               viewportFraction: 1.8,
               onPageChanged: (index,_)=>controller.updatePageIndicator(index)
              ),
              ),
          ),
            const SizedBox(height: AlkSize.spaceBtwItems),
      
            Center (
              child: Obx(
                ()=>  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   for(int i =0; i<4 ;i++)
                   AlkCircularContainer(
                     width: 20,
                     height: 4,
                     margin: const EdgeInsets.only(right: 10),
                     backgroundColor: controller.carousalCurrentIndex.value == i ? AlkColors.primaryColor : AlkColors.grey,
              
                     
                   
                    ),
                    
                    
                    
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
// this Class is used to display the banner slider in the home screen
// it enables u to swipe through the different banners which exist on the asset u 
// have provided in the images_strings.dart file
// have to provide the path of the images in pubspec.yaml file
