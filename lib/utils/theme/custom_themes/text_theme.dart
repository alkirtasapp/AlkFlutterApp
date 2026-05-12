// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AlkTextTheme {
  AlkTextTheme._();
  // Sizes are tuned for TitilliumWeb. Each size is +1pt vs the original Poppins
  // values to compensate for Titillium's smaller x-height. `height: 1.15` keeps
  // the line-box compact so we don't overflow widgets with fixed heights.
  //costumizable light text  theme
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(
        fontSize: 33, height: 1.15, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: const TextStyle().copyWith(
        fontSize: 25, height: 1.15, fontWeight: FontWeight.w600, color: Colors.black),
    headlineSmall: const TextStyle().copyWith(
        fontSize: 19, height: 1.15, fontWeight: FontWeight.w600, color: Colors.black),
    titleLarge: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w600, color: Colors.black),
    titleMedium: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w500, color: Colors.black),
    titleSmall: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w400, color: Colors.black),
    bodyLarge: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.w500, color: Colors.black),
    bodyMedium: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.normal, color: Colors.black),
    bodySmall: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.w500, color: Colors.black),
    labelLarge: const TextStyle().copyWith(
        fontSize: 13, height: 1.15, fontWeight: FontWeight.normal, color: Colors.black),
    labelMedium: const TextStyle().copyWith(
        fontSize: 13,
        height: 1.15,
        fontWeight: FontWeight.normal,
        color: Colors.black.withOpacity(0.5)),
  );

  // costumizable dark text theme
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(
        fontSize: 33, height: 1.15, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: const TextStyle().copyWith(
        fontSize: 25, height: 1.15, fontWeight: FontWeight.w600, color: Colors.white),
    headlineSmall: const TextStyle().copyWith(
        fontSize: 19, height: 1.15, fontWeight: FontWeight.w600, color: Colors.white),
    titleLarge: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w600, color: Colors.white),
    titleMedium: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w500, color: Colors.white),
    titleSmall: const TextStyle().copyWith(
        fontSize: 17, height: 1.15, fontWeight: FontWeight.w400, color: Colors.white),
    bodyLarge: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.w500, color: Colors.white),
    bodyMedium: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.normal, color: Colors.white),
    bodySmall: const TextStyle().copyWith(
        fontSize: 15, height: 1.15, fontWeight: FontWeight.w500, color: Colors.white),
    labelLarge: const TextStyle().copyWith(
        fontSize: 13, height: 1.15, fontWeight: FontWeight.normal, color: Colors.white),
    labelMedium: const TextStyle().copyWith(
        fontSize: 13,
        height: 1.15,
        fontWeight: FontWeight.normal,
        color: Colors.white.withOpacity(0.5)),
  );
}
