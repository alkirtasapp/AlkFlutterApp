import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alkirtas/common/widgets/products/ets_reward_badge.dart';
import 'package:alkirtas/data/controllers/ets_service.dart';

/// "Utiliser mes récompenses" at checkout: same behaviour and texts as the
/// website block (module alk_ets_odoo_bridge).
///
/// "Appliquer" turns the amount into an ETS voucher right away (Odoo safety
/// check, ETS spend lines, ETS email: all done by alkirtas.com). The voucher
/// waits in "Mes bons" and the checkout puts it in the order's cart
/// ([EtsService.attach]). "Retirer" only takes it off this order: it stays in
/// "Mes bons" and shows here as "Bon de X disponible".
///
/// Renders nothing for customers outside "Clients concernés", without a
/// ticket, or with no balance and no voucher.
class EtsBlock extends StatefulWidget {
  /// Products total left to pay (after the promo code, without delivery).
  final double productsTotal;
  final bool hasCoupon;
  final EtsVoucher? applied;
  final ValueChanged<EtsVoucher?> onChanged;

  const EtsBlock({
    super.key,
    required this.productsTotal,
    required this.hasCoupon,
    required this.applied,
    required this.onChanged,
  });

  @override
  State<EtsBlock> createState() => _EtsBlockState();
}

class _EtsBlockState extends State<EtsBlock> {
  static const Color _plum = Color(0xFF7A1A5A);

  EtsRewards? _rewards;
  final _amountController = TextEditingController();
  String _error = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rewards = await EtsService.getRewards();
    if (mounted) setState(() => _rewards = rewards);
  }

  double get _max {
    final r = _rewards;
    if (r == null) return 0;
    var max = r.balance < widget.productsTotal ? r.balance : widget.productsTotal;
    if (r.max > 0 && r.max < max) max = r.max;
    return max < 0 ? 0 : double.parse(max.toStringAsFixed(3));
  }

  double get _amount => double.tryParse(_amountController.text.replaceAll(',', '.').trim()) ?? 0;

  bool get _amountValid => _amount > 0 && _amount <= _max;

  void _onAmountChanged() {
    setState(() => _error = _amount > _max ? 'Maximum ${EtsService.format(_max)} DT.' : '');
  }

  Future<void> _convert() async {
    if (!_amountValid || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await EtsService.convert(
      amount: _amount,
      productsTotal: widget.productsTotal,
      hasCoupon: widget.hasCoupon,
    );
    if (!mounted) return;
    if (result.success && result.voucher != null) {
      _amountController.clear();
      setState(() => _busy = false);
      widget.onChanged(result.voucher);
      _load(); // new balance
    } else {
      setState(() {
        _busy = false;
        _error = result.error;
      });
    }
  }

  void _useVoucher(EtsVoucher voucher) {
    if (widget.hasCoupon && !(_rewards?.combine ?? true)) {
      setState(() => _error = 'Ce bon ne se cumule pas avec votre code promo.');
      return;
    }
    setState(() => _error = '');
    widget.onChanged(voucher);
  }

  void _remove() {
    setState(() => _error = '');
    widget.onChanged(null);
    _load(); // the voucher shows again as "disponible"
  }

  @override
  Widget build(BuildContext context) {
    final r = _rewards;
    final applied = widget.applied;
    if (r == null) return const SizedBox.shrink();
    final vouchers = r.vouchers.where((v) => v.idCartRule != applied?.idCartRule).toList();
    if (applied == null && r.balance <= 0 && vouchers.isEmpty) return const SizedBox.shrink();
    final max = _max;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              EtsCoin(size: 22),
              SizedBox(width: 8),
              Text('Utiliser mes récompenses',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
            ],
          ),
          if (applied != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 18, color: Color(0xFF1E6B2E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E6B2E)),
                        children: [
                          TextSpan(
                              text: '${EtsService.format(applied.amount)} TND',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' de récompenses utilisés sur cette commande.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _remove,
                style: TextButton.styleFrom(foregroundColor: _plum),
                child: const Text('Retirer',
                    style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'Solde : '),
                  TextSpan(
                    text: '${EtsService.format(r.balance)} TND',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ],
              ),
            ),
            for (final voucher in vouchers)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Material(
                  color: const Color(0xFFF7EEF4),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _busy ? null : () => _useVoucher(voucher),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(text: 'Bon de '),
                                  TextSpan(
                                      text: '${EtsService.format(voucher.amount)} TND',
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const TextSpan(text: ' disponible'),
                                ],
                              ),
                            ),
                          ),
                          const Text("L'utiliser",
                              style: TextStyle(color: _plum, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (max > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,3}'))],
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Montant (max ${EtsService.format(max)})',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _plum),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _amountValid && !_busy ? _convert : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _plum,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _plum.withOpacity(0.5),
                      disabledForegroundColor: Colors.white,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Appliquer', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ],
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
