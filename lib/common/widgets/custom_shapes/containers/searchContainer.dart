import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/size.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../common/widgets/qr_scanner/qr_scanner_widget.dart';
import '../../../../controllers/qr_navigation_controller.dart';
import '../../../../navigation_menu.dart';

// Add debug import
import 'package:flutter/foundation.dart' show debugPrint;

class AlkSearchContainer extends StatelessWidget {
  const AlkSearchContainer({
    super.key,
     required this.text,
      this.icon,
       this.showBackground =true ,
        this.showBorder = true,
        this.onPressed,
        this.padding = const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
        this.showQrButton = false,
        this.onQrScanned,
  });

  final String text;
  final IconData? icon;
  final bool showBackground,showBorder;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool showQrButton;
  final Function(String)? onQrScanned;

  @override
  Widget build(BuildContext context) {
    final dark = AlkHelperFunctions.isDarkMode(context);

    // Get NavigationController instance if available
     NavigationController? navigationController;
     try {
       navigationController = Get.find<NavigationController>();
     } catch (e) {
       // NavigationController not found, will handle gracefully
       navigationController = null;
     }

    return GestureDetector(
      onTap: onPressed,
      child: Padding(

        padding: padding,
        child: Container(
          width: AlkDeviceUtils.getScreenWidth(context),
          padding: const EdgeInsets.all(AlkSize.md),
          decoration: BoxDecoration(
            color: showBackground ? dark ? AlkColors.dark :AlkColors.light: Colors.transparent,
            borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
            border:showBorder ?  Border.all(color: AlkColors.grey ): null,
          ),
          child: Row(
            children: [
              Icon(icon, color:  AlkColors.darkerGrey),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Expanded(
                child: Text(text , style: Theme.of(context).textTheme.bodySmall),
              ),
              if (showQrButton) ...[
                const SizedBox(width: AlkSize.spaceBtwItems),
                Container(
                  decoration: BoxDecoration(
                    color: AlkColors.grey.withOpacity(0.2),
                    border: Border.all(color: AlkColors.grey.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(AlkSize.cardRadiusMd),
                  ),
                  child: InkWell(
                    onTap: () => _showQrScanner(context, navigationController),
                    borderRadius: BorderRadius.circular(AlkSize.cardRadiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AlkSize.sm),
                      child: Icon(
                        Iconsax.scan,
                        color: AlkColors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show QR scanner dialog
  void _showQrScanner(BuildContext context, NavigationController? navigationController) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: AlkQrScannerWidget(
              onQrCodeScanned: (String qrCode) async {
                // Close the scanner
                Navigator.of(context).pop();

                debugPrint('📱 QR Code scanned: $qrCode');

                // Process the QR code
                if (navigationController != null) {
                  final qrController = QrNavigationController(navigationController);
                  final success = await qrController.processScannedCode(qrCode);
                  debugPrint('📱 QR Processing result: ${success ? "Success" : "Failed"}');
                } else {
                  debugPrint('❌ NavigationController not available');
                  // Show error message if NavigationController is not available
                  Get.snackbar(
                    'Erreur',
                    'Navigation non disponible',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                }
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }
}
