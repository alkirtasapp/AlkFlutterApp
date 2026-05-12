import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time spotlight overlay shown the first time the user opens a product
/// detail screen for an out-of-stock product. Dark backdrop with a circular
/// cutout around the bell icon + hint text. Tap anywhere to dismiss.
class WishlistHint {
  static const _key = 'wishlist_oos_hint_shown';

  static Future<bool> alreadyShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// [targetKey] must be attached to the bell widget so we can read its
  /// on-screen position and cut a hole around it.
  static Future<void> show(BuildContext context, GlobalKey targetKey) async {
    final ctx = targetKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;
    final center =
        Offset(topLeft.dx + size.width / 2, topLeft.dy + size.height / 2);
    final radius = (size.shortestSide / 2) + 14;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Astuce liste de souhaits',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) =>
          _SpotlightHint(targetCenter: center, targetRadius: radius),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
    await _markShown();
  }
}

class _SpotlightHint extends StatefulWidget {
  final Offset targetCenter;
  final double targetRadius;

  const _SpotlightHint({
    required this.targetCenter,
    required this.targetRadius,
  });

  @override
  State<_SpotlightHint> createState() => _SpotlightHintState();
}

class _SpotlightHintState extends State<_SpotlightHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    // Place the bubble on whichever side has more room
    final bubbleAbove = widget.targetCenter.dy > screenH / 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          // Dark backdrop with circular cutout around the bell
          IgnorePointer(
            child: ClipPath(
              clipper: _SpotlightClipper(
                center: widget.targetCenter,
                radius: widget.targetRadius,
              ),
              child: Container(color: Colors.black.withOpacity(0.78)),
            ),
          ),

          // Pulsing ring around the hole
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final extra = _pulse.value * 8;
              final r = widget.targetRadius + extra;
              return Positioned(
                left: widget.targetCenter.dx - r,
                top: widget.targetCenter.dy - r,
                child: IgnorePointer(
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber
                            .withOpacity(0.85 - (_pulse.value * 0.5)),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Hint text bubble
          Positioned(
            left: 24,
            right: 24,
            top: bubbleAbove
                ? null
                : widget.targetCenter.dy + widget.targetRadius + 32,
            bottom: bubbleAbove
                ? screenH -
                    widget.targetCenter.dy +
                    widget.targetRadius +
                    32
                : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Text(
                'Activez la cloche pour être notifié si le prix baisse OU si ce produit revient en stock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Tap-to-dismiss hint at the bottom
          Positioned(
            bottom: 38,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Touchez l\'écran pour fermer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _SpotlightClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final full =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(_SpotlightClipper old) =>
      old.center != center || old.radius != radius;
}
