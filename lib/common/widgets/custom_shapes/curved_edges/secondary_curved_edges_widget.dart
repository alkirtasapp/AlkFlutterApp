import 'package:alkirtas/common/widgets/custom_shapes/curved_edges/second_curved_edges.dart';
import 'package:flutter/material.dart';

import 'curved_edges.dart';


class AlkSecondaryCurvedEdgeswidget extends StatelessWidget {
  const AlkSecondaryCurvedEdgeswidget({
    super.key,this.child,
  });
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AlkSecondCustomCurverEdges(), //important barsha  
      child: child,
    );
  }
}

