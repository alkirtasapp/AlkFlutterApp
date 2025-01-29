import 'package:flutter/material.dart';

import 'curved_edges.dart';


class AlkCurvedEdgeswidget extends StatelessWidget {
  const AlkCurvedEdgeswidget({
    super.key,this.child,
  });
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AlkCustomCurverEdges(), //important barsha  
      child: child,
    );
  }
}

