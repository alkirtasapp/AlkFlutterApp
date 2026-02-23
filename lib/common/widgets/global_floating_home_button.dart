import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/navigation_menu.dart';

/// Global floating home button that can be shown on any screen
class GlobalFloatingHomeButton extends StatefulWidget {
  final Widget child;
  
  const GlobalFloatingHomeButton({
    super.key,
    required this.child,
  });

  @override
  State<GlobalFloatingHomeButton> createState() => _GlobalFloatingHomeButtonState();
}

class _GlobalFloatingHomeButtonState extends State<GlobalFloatingHomeButton> {
  // Draggable FAB position
  Offset? _fabPosition;
  final double _fabSize = 56.0;
  final bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize FAB position if not set (bottom-right)
        _fabPosition ??= Offset(
          constraints.maxWidth - _fabSize - 16,
          constraints.maxHeight - _fabSize - 100, // Account for bottom nav
        );

        return Stack(
          children: [
            widget.child,
            // Draggable Home FAB
            if (_isVisible)
              Positioned(
                left: _fabPosition!.dx,
                top: _fabPosition!.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      double newX = _fabPosition!.dx + details.delta.dx;
                      double newY = _fabPosition!.dy + details.delta.dy;
                      // Keep FAB within bounds
                      newX = newX.clamp(0, constraints.maxWidth - _fabSize);
                      newY = newY.clamp(0, constraints.maxHeight - _fabSize);
                      _fabPosition = Offset(newX, newY);
                    });
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      // Navigate to home screen
                      Get.offAll(() => const NavigationMenu(selectedMenu: 0));
                    },
                    backgroundColor: AlkColors.AppFirstColor,
                    elevation: 4,
                    mini: false,
                    child: const Icon(Iconsax.home, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Service to manage global FAB visibility
class GlobalFabService extends GetxService {
  static GlobalFabService get instance => Get.find();
  
  final Rx<bool> _isVisible = true.obs;
  
  bool get isVisible => _isVisible.value;
  
  void show() => _isVisible.value = true;
  void hide() => _isVisible.value = false;
  void toggle() => _isVisible.value = !_isVisible.value;
}

/// Wrapper widget that responds to GlobalFabService
class ResponsiveGlobalFab extends StatelessWidget {
  final Widget child;
  final bool? forceShow;
  final bool? forceHide;
  
  const ResponsiveGlobalFab({
    super.key,
    required this.child,
    this.forceShow,
    this.forceHide,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Always read the observable so GetX registers a listener
      final serviceVisible = GlobalFabService.instance.isVisible;
      final shouldShow = forceShow ?? (forceHide == true ? false : serviceVisible);

      return shouldShow
        ? GlobalFloatingHomeButton(child: child)
        : child;
    });
  }
}
