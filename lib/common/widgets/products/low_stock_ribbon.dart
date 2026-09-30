import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:alkirtas/data/controllers/low_stock_service.dart';

/// Where the ribbon is being drawn. Mirrors the two variants the website
/// renders (`--cover` on the product page, `--list` on grid thumbnails), which
/// differ only in scale.
enum LowStockRibbonVariant { cover, list }

/// The "Reste {quantity} piece(s) en stock" ribbon.
///
/// Everything visible here — whether it shows at all, the wording, the colour,
/// the threshold — comes from the Product Low Stock Rules module in the
/// PrestaShop back office. Change a rule there and this follows, with no app
/// release. Nothing about "low stock" is decided in Dart.
///
/// Drop it into the existing [Stack] that holds a product image; it positions
/// itself in the top-right corner and renders nothing until (and unless) the
/// server says the product earns a badge.
class LowStockRibbon extends StatefulWidget {
  static const bool enabled = LowStockService.enabled;

  final String productId;

  /// Current stock, when the caller already knows it. Lets an in-stock product
  /// above every configured threshold skip the network entirely.
  final String? stock;

  final LowStockRibbonVariant variant;

  const LowStockRibbon({
    super.key,
    required this.productId,
    this.stock,
    this.variant = LowStockRibbonVariant.list,
  });

  @override
  State<LowStockRibbon> createState() => _LowStockRibbonState();
}

class _LowStockRibbonState extends State<LowStockRibbon>
    with SingleTickerProviderStateMixin {
  late Future<LowStockBadge?> _badge;

  // Left idle until a badge actually resolves: most products never get one,
  // and a grid full of always-running tickers is pure waste.
  late final AnimationController _swing;

  @override
  void initState() {
    super.initState();
    // Initialize while the element is active, even when no badge is displayed.
    // A lazy initializer would otherwise run for the first time in dispose().
    _swing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _badge = _load();
  }

  void _ensureSwinging(bool reduceMotion) {
    if (reduceMotion) {
      if (_swing.isAnimating) _swing.stop();
      return;
    }
    if (!_swing.isAnimating) _swing.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LowStockRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cards get recycled onto different products as the grid scrolls.
    if (oldWidget.productId != widget.productId ||
        oldWidget.stock != widget.stock) {
      _badge = _load();
    }
  }

  Future<LowStockBadge?> _load() {
    final id = int.tryParse(widget.productId) ?? 0;
    if (id <= 0) return Future.value(null);
    return LowStockService.badgeFor(id,
        stock: int.tryParse(widget.stock ?? ''));
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCover = widget.variant == LowStockRibbonVariant.cover;
    // Stay positioned while loading, absent, or failed. An unpositioned empty
    // child can shrink a Stack containing Positioned.fill images to zero width.
    return Positioned(
      top: isCover ? 14 : 9,
      right: isCover ? -30 : -24,
      child: FutureBuilder<LowStockBadge?>(
        future: _badge,
        builder: (context, snapshot) {
          final badge = snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;
          if (badge == null) {
            _swing.stop();
            return const SizedBox.shrink();
          }
          return _buildRibbon(context, badge);
        },
      ),
    );
  }

  Widget _buildRibbon(BuildContext context, LowStockBadge badge) {
    final isCover = widget.variant == LowStockRibbonVariant.cover;
    final fontSize = isCover ? 13.0 : 10.0;

    // The site tilts the ribbon 35deg and gently swings it. Honour the OS
    // reduced-motion setting the same way its CSS media query does.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _ensureSwinging(reduceMotion);

    final ribbon = Container(
      constraints: BoxConstraints(minWidth: isCover ? 150 : 108),
      padding: EdgeInsets.symmetric(
        horizontal: isCover ? 22 : 16,
        vertical: isCover ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: badge.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isCover ? 0.18 : 0.16),
            blurRadius: isCover ? 10 : 6,
            offset: Offset(0, isCover ? 5 : 3),
          ),
        ],
      ),
      child: Text(
        badge.message,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: badge.foreground,
          fontSize: fontSize,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return IgnorePointer(
      child: reduceMotion
          ? Transform.rotate(angle: _angle, child: ribbon)
          : AnimatedBuilder(
              animation: _swing,
              child: ribbon,
              builder: (context, child) {
                // Same motion as the CSS keyframes: a small vertical drift,
                // scaled to the font size so it tracks the ribbon.
                return Transform.translate(
                  offset: Offset(0, _swing.value * fontSize * 0.3),
                  child: Transform.rotate(angle: _angle, child: child),
                );
              },
            ),
    );
  }

  static const double _angle = 35 * math.pi / 180;
}
