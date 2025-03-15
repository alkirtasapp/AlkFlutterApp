import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/colors.dart';
 
 class AlkShadowStyle {
  static final verticalProductShadow = BoxShadow(
  color: AlkColors.darkGrey.withOpacity(0.1),
  blurRadius: 50,
  spreadRadius: 7,
  offset: const Offset(0, 2),
  );


  static final horizontalProdutShadow =BoxShadow(
  color: AlkColors.darkGrey.withOpacity(0.1),
  blurRadius: 50,
  spreadRadius: 7,
  offset: const Offset(0, 2),
  );
 }