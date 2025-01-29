import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../curved_edges/curved_edges_widgets.dart';
import 'circular_container.dart';


class AlkPrimaryHeaderContainer extends StatelessWidget {
  const AlkPrimaryHeaderContainer({
    super.key,required this.child
  });

  final  Widget child;

  @override
  Widget build(BuildContext context) {
    return AlkCurvedEdgeswidget(
      child: Container(
        color : AlkColors.primaryColor,
        padding : const EdgeInsets.all(0),
        child: SizedBox(
          height: 380,
          child: Stack(
            children: [
              Positioned( top :-150 , right: -250, child: AlkCircularContainer(backgroundColor: AlkColors.white.withOpacity(0.1)),),
              Positioned( top :100 , right: -300, child: AlkCircularContainer(backgroundColor: AlkColors.white.withOpacity(0.1)),),
              child,
    
    
            ],
          ),
        ),
      ),
    );
  }
}
