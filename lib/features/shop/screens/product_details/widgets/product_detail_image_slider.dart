import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widgets.dart';
import '../../../../../common/widgets/images/AlkRoundedImages.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/size.dart';

class AlkProductImageSlider extends StatefulWidget {
  final List<String> productImages;
  final String productName;

  const AlkProductImageSlider({
    super.key,
    required this.productImages,
    required this.productName,
  });

  @override
  _AlkProductImageSliderState createState() => _AlkProductImageSliderState();
}

class _AlkProductImageSliderState extends State<AlkProductImageSlider> {
  int selectedIndex = 0;
  final TransformationController _transformationController = TransformationController();

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Fullscreen InteractiveViewer
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to make the container height responsive
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AlkCurvedEdgeswidget(
      child: Container(
        color: AlkColors.white,
        child: Column(
          children: [
            // App Bar
            AlkAppBar(showBackArrow: true, title: Text(widget.productName)),
            
            // Main Content
            SizedBox(
              height: screenHeight * 0.45, 
              child: Stack(
                children: [
                  // Main Large Image
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(AlkSize.productImageRadius),
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(
                          context,
                          widget.productImages.isNotEmpty
                              ? widget.productImages[selectedIndex]
                              : 'https://www.alkirtas.com/img/p/placeholder.jpg',
                        ),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: widget.productImages.isNotEmpty
                                  ? widget.productImages[selectedIndex]
                                  : 'https://www.alkirtas.com/img/p/placeholder.jpg',
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),


                  // Thumbnail Slider
                  if (widget.productImages.length > 1) // Only show if there are multiple images
                    Positioned(
                      right: 0,
                      bottom: 20,
                      left: AlkSize.defaultSpace,
                      child: SizedBox(
                        height: 60,
                        child: ListView.separated(
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AlkSize.spaceBtwItems),
                          itemCount: widget.productImages.length,
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
                              width: 60,
                              backgroundColor: AlkColors.white,
                              border: Border.all(
                                color: selectedIndex == index
                                    ? AlkColors.primaryColor
                                    : Colors.grey,
                                width: selectedIndex == index ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
