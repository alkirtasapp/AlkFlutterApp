import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/device/device_utility.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';

class AlkTabBar extends StatelessWidget implements PreferredSizeWidget  {
    final List<Widget> tabs; 


  const AlkTabBar({
  super.key,
  required this.tabs});

  @override
  Widget build(BuildContext context) {
    final dark =AlkHelperFunctions.isDarkMode(context);
    
    return Material(
      color: dark ? AlkColors.black : AlkColors.white,
      child:TabBar(
        tabs: tabs,
       isScrollable: true,
       indicatorColor: AlkColors.primaryColor,
       labelColor: dark ? AlkColors.white : AlkColors.primaryColor,
        unselectedLabelColor: AlkColors.darkGrey,


)


    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(AlkDeviceUtils.getAppBarHeight());
}

///  AlkTabBar Documentation
///
/// `AlkTabBar` is a custom TabBar widget designed for the Alkirtas application.
/// It provides a styled and consistent TabBar experience with support for
/// dynamic theming (light/dark mode).
///
///  Features
///
/// -   Customizable Tabs: Accepts a list of `Widget`s to be used as the tabs.
/// -   Scrollable: Tabs can scroll horizontally if there are too many to fit
///     on the screen, thanks to `isScrollable: true`.
/// -   Dynamic Theming: Adapts to the current theme (light/dark mode)
///     using `AlkHelperFunctions.isDarkMode(context)`.
/// -   Consistent Styling: Uses predefined colors from `AlkColors` for
///     background, indicator, label, and unselected label colors.
/// -   Automatic Height: Uses `AlkDeviceUtils.getAppBarHeight()` to
///     dynamically determine the TabBar's height, ensuring consistency with the
///     AppBar.
///
///  Parameters
///
/// -   `tabs`: (Required) A `List<Widget>` containing the tabs to display in the
///     TabBar. Typically, these would be `Tab` widgets.
///
///  Usage
///
/// ```dart
/// AlkTabBar(
///   tabs: [
///     Tab(text: 'Tab 1'),
///     Tab(text: 'Tab 2'),
///     Tab(text: 'Tab 3'),
///   ],
/// )
/// ```
///
///  Styling Details
///
/// -   Background Color:
///     -   Dark Mode: `AlkColors.black`
///     -   Light Mode: `AlkColors.white`
/// -   Indicator Color: `AlkColors.primaryColor` (app's primary color)
/// -   Label Color (Selected Tab):
///     -   Dark Mode: `AlkColors.white`
///     -   Light Mode: `AlkColors.primaryColor`
/// -   Unselected Label Color: `AlkColors.darkGrey`
///
///  Notes
///
/// -   Relies on `AlkHelperFunctions` to check the current theme.
/// -   Uses `AlkDeviceUtils` to determine the appropriate height.
/// -   Utilizes `AlkColors` for consistent color theming.
/// -   It is usually used inside a `DefaultTabController` widget to work properly.