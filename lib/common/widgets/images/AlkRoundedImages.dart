import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/size.dart';

class AlkRoundedImage extends StatelessWidget {
  const AlkRoundedImage({
    super.key,
    this.width,
    this.height,
    required this.imageUrl,
    this.applyImageRadius = true,
    this.border,
    this.backgroundColor = AlkColors.light,
    this.fit,
    this.padding,
    this.onPressed,
    this.borderRadius = AlkSize.md,
  });

  final double? width, height;
  final String imageUrl;
  final bool applyImageRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    bool isNetwork = imageUrl.startsWith("http"); // Detect network image

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          border: border,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AlkSize.md),
        ),
        child: ClipRRect(
          borderRadius:
              applyImageRadius ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
          child: isNetwork
              ? Image.network(
                  imageUrl,
                  fit: fit ?? BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                )
              : Image.asset(
                  imageUrl,
                  fit: fit ?? BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
