import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';

class AlkQrScannerWidget extends StatefulWidget {
  final Function(String) onQrCodeScanned;
  final VoidCallback? onClose;

  const AlkQrScannerWidget({
    super.key,
    required this.onQrCodeScanned,
    this.onClose,
  });

  @override
  State<AlkQrScannerWidget> createState() => _AlkQrScannerWidgetState();
}

class _AlkQrScannerWidgetState extends State<AlkQrScannerWidget>
    with TickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _hasPermission = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
    } else if (status.isDenied || status.isRestricted) {
      // Request permission
      status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
          _errorMessage = 'Permission caméra refusée';
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
        _errorMessage = 'Permission caméra définitivement refusée.\nAllez dans les paramètres pour l\'activer.';
      });
    }
  }

  void _openSettings() async {
    await openAppSettings();
    // Recheck permission after returning from settings
    await Future.delayed(const Duration(seconds: 1));
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = AlkHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Scanner View
          if (_hasPermission && !_isLoading) ...[
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    widget.onQrCodeScanned(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            // Scanning Overlay
            _buildScanningOverlay(),
          ] else if (_isLoading) ...[
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AlkColors.primaryColor),
              ),
            ),
          ] else ...[
            // Permission Error
            Center(
              child: Container(
                margin: const EdgeInsets.all(AlkSize.defaultSpace),
                padding: const EdgeInsets.all(AlkSize.defaultSpace),
                decoration: BoxDecoration(
                  color: darkMode ? AlkColors.dark : AlkColors.light,
                  borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: AlkColors.error,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwItems),
                    Text(
                      'Accès à la caméra requis',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwItems / 2),
                    Text(
                      _errorMessage ?? 'Permission caméra nécessaire pour scanner les QR codes',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwSections),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _openSettings,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AlkColors.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AlkSize.cardRadiusMd),
                              ),
                            ),
                            child: const Text('Paramètres'),
                          ),
                        ),
                        const SizedBox(width: AlkSize.spaceBtwItems),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AlkColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AlkSize.cardRadiusMd),
                              ),
                            ),
                            child: const Text('Fermer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AlkSize.sm,
            left: AlkSize.defaultSpace,
            right: AlkSize.defaultSpace,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlkSize.md,
                    vertical: AlkSize.sm / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AlkSize.cardRadiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AlkColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AlkSize.sm / 2),
                      Text(
                        'Scanner Code QR / Code-barres',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _scannerController.toggleTorch();
                  },
                  icon: Icon(
                    Icons.flashlight_on,
                    color: _scannerController.torchState.value == TorchState.on
                        ? AlkColors.primaryColor
                        : Colors.white,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Scanning Instructions
          if (_hasPermission && !_isLoading)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + AlkSize.xl,
              left: AlkSize.defaultSpace,
              right: AlkSize.defaultSpace,
              child: Container(
                padding: const EdgeInsets.all(AlkSize.defaultSpace),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AlkSize.cardRadiusLg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code,
                      color: AlkColors.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwItems / 2),
                    Text(
                      'Placez le code dans le cadre',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AlkSize.sm),
                    Text(
                      'QR code ou code-barres produit\nDétection automatique',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _QrScannerOverlayShape(
          borderColor: AlkColors.primaryColor,
          borderWidth: 3.0,
          overlayColor: Colors.black.withOpacity(0.6),
          cutOutSize: MediaQuery.of(context).size.width * 0.7,
          animation: _animation,
        ),
      ),
    );
  }
}

class _QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double cutOutSize;
  final Animation<double> animation;

  const _QrScannerOverlayShape({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.cutOutSize,
    required this.animation,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..fillType = PathFillType.evenOdd;

    // Calculate center and cutout area
    final center = rect.center;
    final cutOutLeft = center.dx - cutOutSize / 2;
    final cutOutTop = center.dy - cutOutSize / 2;
    final cutOutRect = Rect.fromLTWH(cutOutLeft, cutOutTop, cutOutSize, cutOutSize);

    // Add overlay rectangles (areas outside the cutout)
    path.addRect(Rect.fromLTWH(0, 0, rect.width, rect.height));
    path.addRect(cutOutRect);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final center = rect.center;
    final cutOutLeft = center.dx - cutOutSize / 2;
    final cutOutTop = center.dy - cutOutSize / 2;
    final cutOutRect = Rect.fromLTWH(cutOutLeft, cutOutTop, cutOutSize, cutOutSize);

    // Draw overlay
    canvas.drawPath(getInnerPath(rect), paint);

    // Draw animated border
    final animatedBorderPaint = Paint()
      ..color = borderColor.withOpacity(animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRect(cutOutRect, animatedBorderPaint);

    // Draw corner indicators
    _drawCornerIndicators(canvas, cutOutRect, borderColor);
  }

  void _drawCornerIndicators(Canvas canvas, Rect cutOutRect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top),
      Offset(cutOutRect.left + cornerLength, cutOutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top),
      Offset(cutOutRect.left, cutOutRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top),
      Offset(cutOutRect.right - cornerLength, cutOutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top),
      Offset(cutOutRect.right, cutOutRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom),
      Offset(cutOutRect.left + cornerLength, cutOutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom),
      Offset(cutOutRect.left, cutOutRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom),
      Offset(cutOutRect.right - cornerLength, cutOutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom),
      Offset(cutOutRect.right, cutOutRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}