import 'package:flutter/material.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/size.dart';

class AlkProductImageSlider extends StatefulWidget {
  final List<String> productImages;

  const AlkProductImageSlider({
    super.key,
    required this.productImages,
  });

  @override
  _AlkProductImageSliderState createState() => _AlkProductImageSliderState();
}

class _AlkProductImageSliderState extends State<AlkProductImageSlider> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AlkCurvedEdgeswidget(
      child: Container(
        color: AlkColors.white,
        child: Stack(
          children: [
            // **Main Large Image**
            SizedBox(
              height: 450,
              child: Padding(
                padding: const EdgeInsets.all(AlkSize.productImageRadius * 2),
                child: Center(
                  child: Image.network(
                    widget.productImages.isNotEmpty
                        ? widget.productImages[selectedIndex] // Show selected image
                        : 'https://www.alkirtas.com/img/p/placeholder.jpg', // Default image
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.image_not_supported));
                    },
                  ),
                ),
              ),
            ),

            // **Image Slider Thumbnails**
            Positioned(
              right: 0,
              bottom: 30,
              left: AlkSize.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  separatorBuilder: (_, __) => const SizedBox(width: AlkSize.spaceBtwItems),
                  itemCount: widget.productImages.length, // Dynamic thumbnail count
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (_, index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: AlkRoundedImage(
                      imageUrl: widget.productImages[index],
                      width: 80,
                      backgroundColor: AlkColors.white,
                      border: Border.all(
                        color: selectedIndex == index ? AlkColors.primaryColor : Colors.grey,
                        width: selectedIndex == index ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // **App Bar Icon**
            const AlkAppBar(showBackArrow: true),
          ],
        ),
      ),
    );
  }
}
