import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/device/device_utility.dart';

class AlkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AlkAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = true,
    

  });
  final Widget? title;
  final List<Widget>? actions;
  final IconData? leadingIcon;
  final bool showBackArrow;
  final VoidCallback? leadingOnPressed;
  

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AlkSize.md),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(
                onPressed: ()=>  Get.back(),
                icon: Icon(
                  Iconsax.arrow_left,
                  color: Colors.black,
                ))
            : leadingIcon != null
                ? IconButton(
                    onPressed: leadingOnPressed, icon: Icon(leadingIcon))
                : null,
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AlkDeviceUtils.getAppBarHeight());
}




/// AlkAppBar is a custom AppBar widget 
/// It provides a flexible and consistent AppBar experience with options for a
/// title, actions, and a leading icon or back arrow.
///
///  Features :
///
/// -   **Customizable Title:**  Display a `Widget` as the title.
/// -   **Customizable Actions:** Add a list of `Widget`s to the actions section.
/// -   **Leading Icon:**  Display a custom `IconData` as the leading element.
/// -   **Back Arrow:** Optionally show a back arrow as the leading element, which
///     navigates back using `Get.back()`.
/// -   **Leading Icon Action:** Optionally provide a callback function for
///     leading icon, if back arrow is false.
/// -   **Automatic Height:** Uses `AlkDeviceUtils.getAppBarHeight()` to
///     dynamically set the AppBar height based on the device.
/// -  **Padding:** Applies horizontal padding using `AlkSize.md`.
///
/// ### Parameters
///
/// -   `title`: (Optional) A `Widget` to display as the title of the AppBar.
/// -   `actions`: (Optional) A `List<Widget>` to display as actions in the
///     AppBar.
/// -   `leadingIcon`: (Optional) An `IconData` to use as the leading icon.
/// -   `showBackArrow`: (Optional) A `bool` indicating whether to show a back
///     arrow. Defaults to `true`.
/// - `leadingOnPressed` : (Optional) A function called when leading icon is pressed.
///
/// ### Usage
///
/// ```dart
/// AlkAppBar(
///   title: Text('My Page'),
///   actions: [
///     IconButton(
///       icon: Icon(Icons.search),
///       onPressed: () {
///         // Handle search action
///       },
///     ),
///   ],
///   leadingIcon: Icons.menu,
///   leadingOnPressed: (){
///      // Handle leading action
///   },
///   showBackArrow: false
/// )
/// ```
///
/// ### Notes
///
/// -   When `showBackArrow` is `true`, the `leadingIcon` and `leadingOnPressed` parameters are ignored.
/// -   If `showBackArrow` is `false` and `leadingIcon` is `null`, no leading widget will be displayed.
/// -   Uses the `Get` package for back navigation (`Get.back()`).
/// -   Uses the `Iconsax` package for the default back arrow icon.
/// - Relies on `AlkSize` and `AlkDeviceUtils` for consistency.