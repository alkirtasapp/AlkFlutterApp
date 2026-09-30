import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/providers/coupon_provider.dart';
import 'package:alkirtas/utils/constants/colors.dart';

/// Opens the "Mes coupons" bottom sheet (add / list / copy / remove codes).
///
/// When [selectOnAdd] is true (checkout), a freshly added coupon is also
/// selected so it applies to the current order right away.
Future<void> showCouponsSheet(BuildContext context, {bool selectOnAdd = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CouponsSheet(selectOnAdd: selectOnAdd),
  );
}

/// Coupons sorted with the ones expiring soonest first.
List<Coupon> sortedCoupons(List<Coupon> coupons) =>
    [...coupons]..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

class CouponsSheet extends StatefulWidget {
  final bool selectOnAdd;
  const CouponsSheet({super.key, this.selectOnAdd = false});

  @override
  State<CouponsSheet> createState() => _CouponsSheetState();
}

enum _MsgKind { success, info, error }

class _CouponsSheetState extends State<CouponsSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;
  _MsgKind _kind = _MsgKind.info;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show(String msg, _MsgKind kind) => setState(() {
        _message = msg;
        _kind = kind;
      });

  Future<void> _submit() async {
    if (_loading) return;
    final code = _controller.text.trim();
    if (code.isEmpty) {
      _show('Saisissez un code promo.', _MsgKind.error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
    });
    final provider = context.read<CouponProvider>();
    final result = await provider.redeemCoupon(code);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case CouponAddResult.added:
        HapticFeedback.lightImpact();
        _controller.clear();
        if (widget.selectOnAdd && provider.coupons.isNotEmpty) {
          provider.selectCoupon(provider.coupons.last);
          _show('Coupon ajouté et appliqué à votre commande.', _MsgKind.success);
        } else {
          _show('Coupon ajouté ! Il sera disponible lors du paiement.', _MsgKind.success);
        }
        break;
      case CouponAddResult.alreadyAdded:
        _show('Ce coupon est déjà dans votre liste.', _MsgKind.info);
        break;
      case CouponAddResult.expired:
        _show('Ce coupon a expiré.', _MsgKind.error);
        break;
      case CouponAddResult.invalid:
        _show('Code introuvable. Vérifiez l\'orthographe.', _MsgKind.error);
        break;
      case CouponAddResult.networkError:
        _show('Connexion impossible. Vérifiez votre réseau et réessayez.', _MsgKind.error);
        break;
    }
  }

  Future<void> _confirmRemove(Coupon coupon) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce coupon ?'),
        content: Text('Le code ${coupon.code} sera retiré de votre liste.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<CouponProvider>().removeCoupon(coupon);
      setState(() => _message = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coupons = sortedCoupons(context.watch<CouponProvider>().coupons);
    final accent = AlkColors.AppFirstColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Mes coupons',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (coupons.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${coupons.length}',
                              style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enregistrez vos codes promo et utilisez-les lors du paiement.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_loading,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) {
                            if (_message != null) setState(() => _message = null);
                          },
                          decoration: InputDecoration(
                            hintText: 'Code promo',
                            prefixIcon: const Icon(Iconsax.ticket),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Ajouter'),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _message == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _MessageBanner(text: _message!, kind: _kind),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Flexible(
              child: coupons.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: coupons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = coupons[i];
                        return CouponTicket(
                          coupon: c,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CopyCodeButton(code: c.code),
                              IconButton(
                                tooltip: 'Supprimer',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Iconsax.trash, size: 20, color: Colors.redAccent),
                                onPressed: () => _confirmRemove(c),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticket-style card for a coupon: discount stub on the left, details on the
/// right, optional [trailing] actions.
class CouponTicket extends StatelessWidget {
  final Coupon coupon;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? footnote;

  const CouponTicket({
    super.key,
    required this.coupon,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AlkColors.AppFirstColor;
    final label = coupon.discountLabel;
    final days = coupon.daysLeft;
    final urgent = days <= 7;
    final d = coupon.expiryDate;
    final expiryText = days <= 0
        ? 'Expire aujourd\'hui'
        : urgent
            ? 'Expire dans $days jour${days > 1 ? 's' : ''}'
            : 'Valable jusqu\'au ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? accent : theme.colorScheme.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Discount stub
              Container(
                width: 88,
                color: accent.withValues(alpha: selected ? 0.18 : 0.10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (label.isEmpty)
                      Icon(Iconsax.ticket_discount, color: accent, size: 28)
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label,
                            style: TextStyle(
                                color: accent, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                    const SizedBox(height: 2),
                    Text(label.isEmpty ? 'Offre' : 'de remise',
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: _DashedLinePainter(theme.colorScheme.outlineVariant),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (coupon.name.isNotEmpty)
                        Text(coupon.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(coupon.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accent)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Iconsax.clock,
                              size: 14,
                              color: urgent ? Colors.redAccent : theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(expiryText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: urgent ? Colors.redAccent : null,
                                  fontWeight: urgent ? FontWeight.w600 : null,
                                )),
                          ),
                        ],
                      ),
                      if (footnote != null) ...[
                        const SizedBox(height: 4),
                        Text(footnote!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AlkColors.AppSecColor, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  final String code;
  const _CopyCodeButton({required this.code});

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _copied ? 'Copié !' : 'Copier le code',
      visualDensity: VisualDensity.compact,
      onPressed: _copy,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _copied
            ? Icon(Iconsax.tick_circle, key: const ValueKey('ok'), size: 20, color: AlkColors.AppSecColor)
            : const Icon(Iconsax.copy, key: ValueKey('copy'), size: 20),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String text;
  final _MsgKind kind;
  const _MessageBanner({required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (kind) {
      _MsgKind.success => (AlkColors.AppSecColor, Iconsax.tick_circle),
      _MsgKind.info => (Colors.blueGrey, Iconsax.info_circle),
      _MsgKind.error => (Colors.redAccent, Iconsax.warning_2),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AlkColors.AppFirstColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(Iconsax.ticket_discount, size: 36, color: accent),
          ),
          const SizedBox(height: 14),
          Text('Aucun coupon pour le moment',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Saisissez un code promo ci-dessus pour l\'enregistrer.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0, gap = 3.0;
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(0, y), Offset(0, (y + dash).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

/// Coupon picker used on the checkout screen.
class CheckoutCouponBlock extends StatelessWidget {
  /// Order subtotal, used to show how much each coupon saves.
  final double subtotal;
  const CheckoutCouponBlock({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CouponProvider>();
    final coupons = sortedCoupons(provider.coupons);
    final selected = provider.selectedCoupon;
    final accent = AlkColors.AppFirstColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Code de réduction',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (coupons.isNotEmpty)
                TextButton.icon(
                  onPressed: () => showCouponsSheet(context, selectOnAdd: true),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (coupons.isEmpty)
            Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => showCouponsSheet(context, selectOnAdd: true),
                leading: Icon(Iconsax.ticket_discount, color: accent),
                title: const Text('Vous avez un code promo ?'),
                subtitle: const Text('Ajoutez-le pour l\'appliquer à cette commande.'),
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
              ),
            )
          else ...[
            for (final c in coupons) ...[
              CouponTicket(
                coupon: c,
                selected: selected?.code == c.code,
                onTap: () => provider.selectCoupon(selected?.code == c.code ? null : c),
                footnote: subtotal > 0 && c.discountOn(subtotal) > 0
                    ? 'Vous économisez ${c.discountOn(subtotal).toStringAsFixed(2)} TND'
                    : null,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Icon(
                      selected?.code == c.code ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected?.code == c.code ? accent : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (selected != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => provider.selectCoupon(null),
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: const Text('Retirer le coupon'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              )
            else
              Text('Touchez un coupon pour l\'appliquer.', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
