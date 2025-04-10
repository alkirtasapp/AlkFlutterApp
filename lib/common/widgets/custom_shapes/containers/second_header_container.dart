import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../curved_edges/second_curved_edges.dart';
import 'circular_container.dart';

class AlkSecondHeaderContainer extends StatelessWidget {
  const AlkSecondHeaderContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AlkSecondCustomCurverEdges(), //important barsha
      child: Container(
        color: AlkColors.primaryColor,
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -250,
              child: AlkCircularContainer(
                backgroundColor: AlkColors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              top: 100,
              right: -300,
              child: AlkCircularContainer(
                backgroundColor: AlkColors.white.withOpacity(0.4),
              ),
            ),
             Positioned(
              bottom: -280,
              right: 150,
             
              child: AlkCircularContainer(
                backgroundColor: AlkColors.white.withOpacity(0.3),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
