// ignore: file_names

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:alkirtas/features/shop/controllers/home_controller.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/api/banner_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../common/widgets/custom_shapes/containers/circular_container.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/images_strings.dart';  
import '../../../../../utils/constants/size.dart';
import 'package:alkirtas/features/authentication/screens/splash_wrapper.dart';

class AlkBannerSlider extends StatelessWidget {
  const AlkBannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final banners = SplashWrapper.preloadedBannerUrls;
    if (banners.isEmpty) {
      return const Center(child: Text('No banners available'));
    }

    // Get screen width for responsive sizing with padding
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AlkSize.defaultSpace * 2; // Padding on both sides
    final availableWidth = screenWidth - horizontalPadding;
    // Maintain 1200x500 aspect ratio (2.4:1)
    final bannerHeight = availableWidth / 2.4;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
      ),
      child: Column(
        children: [
          CarouselSlider(
            items: banners
                .map((url) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AlkRoundedImage(
                        imageUrl: url,
                        width: availableWidth,
                        height: bannerHeight,
                        fit: BoxFit.cover,
                      ),
                    ))
                .toList(),
            options: CarouselOptions(
              viewportFraction: 0.92,
              height: bannerHeight,
              enlargeCenterPage: true,
              autoPlay: true, // Enable autoPlay
              autoPlayInterval: const Duration(seconds: 5), // Set interval
              onPageChanged: (index, _) =>
                  controller.updatePageIndicator(index),
            ),
          ),
          const SizedBox(height: AlkSize.spaceBtwItems),
          Center(
            child: Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < banners.length; i++)
                    AlkCircularContainer(
                      width: 20,
                      height: 6,
                      margin: const EdgeInsets.only(right: 10),
                      backgroundColor:
                          controller.carousalCurrentIndex.value == i
                              ? AlkColors.primaryColor
                              : AlkColors.grey,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
