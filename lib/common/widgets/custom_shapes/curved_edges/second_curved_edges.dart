import 'package:flutter/material.dart';

class AlkSecondCustomCurverEdges extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double radius = 20.0;

    final path = Path();

    // Top-left corner
    path.moveTo(0, radius);
    path.arcToPoint(
      Offset(radius, 0),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Top-right corner
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom-right curve start
    path.lineTo(size.width, size.height - radius);

    // Bottom-right curve with border radius
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom center curve
    path.quadraticBezierTo(
      size.width / 2, size.height + 20, // control point below the bottom for the curve
      radius, size.height,              // end before bottom-left
    );

    // Bottom-left corner with border radius
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
