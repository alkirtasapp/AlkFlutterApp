import 'package:flutter/material.dart';
import 'package:alkirtas/common/widgets/global_floating_home_button.dart';

/// A helper widget that wraps any screen with the global floating home button
/// Use this instead of Scaffold when you want the global FAB to appear
class ScreenWithGlobalFab extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Drawer? drawer;
  final Drawer? endDrawer;
  final Widget? bottomSheet;
  final bool primary;

  const ScreenWithGlobalFab({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBar,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveGlobalFab(
      child: Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        drawer: drawer,
        endDrawer: endDrawer,
        bottomSheet: bottomSheet,
        primary: primary,
      ),
    );
  }
}

/// Extension method to make it easier to wrap existing Scaffold widgets
extension ScaffoldWithGlobalFab on Scaffold {
  /// Wrap this Scaffold with the global floating home button
  Widget withGlobalFab() {
    return ResponsiveGlobalFab(child: this);
  }
}
