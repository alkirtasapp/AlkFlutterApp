import 'package:alkirtas/utils/theme/custom_themes/appbar_theme.dart';
import 'package:alkirtas/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:alkirtas/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:alkirtas/utils/theme/custom_themes/elevatedButtonTheme.dart';
import 'package:alkirtas/utils/theme/custom_themes/outlined_button_theme.dart';
import 'package:alkirtas/utils/theme/custom_themes/text_theme.dart';
import 'package:flutter/material.dart';

import 'custom_themes/chip_theme.dart';
import 'custom_themes/text_field_theme.dart';

class TAppTheme {
  TAppTheme._();

//light theme

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.deepPurpleAccent,
    scaffoldBackgroundColor: Colors.white,
    textTheme: AlkTextTheme.lightTextTheme,
    chipTheme: AlkChipTheme.lightChipTheme,
    checkboxTheme: AlkCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: AlkBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: AlkElevatedbuttontheme.lightElevatedButtonTheme,
    outlinedButtonTheme: AlkOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: AlkTextFormFieldTheme.lightInputDecorationTheme,
    appBarTheme: AlkAppbarTheme.lightAppBarTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.deepPurpleAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: AlkTextTheme.darkTextTheme,
    chipTheme: AlkChipTheme.darkChipTheme,
    checkboxTheme: AlkCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: AlkBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: AlkElevatedbuttontheme.darkElevatedButtonTheme,
    outlinedButtonTheme: AlkOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: AlkTextFormFieldTheme.darkInputDecorationTheme,
    appBarTheme: AlkAppbarTheme.darkAppBarTheme,
  );
}
