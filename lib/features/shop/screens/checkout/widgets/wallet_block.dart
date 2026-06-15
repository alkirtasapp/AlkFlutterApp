import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/data/controllers/wallet_service.dart';
import 'package:alkirtas/utils/constants/colors.dart';

/// Wallet block shown on the checkout screen. Lets the customer apply part of
/// their Odoo wallet balance against the current order.
///
/// Behavior:
///   - On mount: fetches the wallet balance.
///   - If not eligible (not whitelisted) → renders nothing.
///   - If balance is 0 → renders nothing.
///   - Otherwise: shows an input + Apply button. Capped at min(balance, cartTotal).
///   - When the customer applies an amount, this widget calls back via [onAmountChanged]
///     so the parent can subtract it from the displayed total.
///
/// Important: the actual voucher creation on the PrestaShop side happens later
/// (after the parent calls [createCartWithAddress]). This widget just tracks
/// the amount the customer wants to use. The parent triggers the real apply
/// via [WalletService.applyToCart] once the PS cart exists.
class WalletBlock extends StatefulWidget {
  final double cartTotal;
  final double currentAppliedAmount;
  final ValueChanged<double> onAmountChanged;

  const WalletBlock({
    super.key,
    required this.cartTotal,
    required this.currentAppliedAmount,
    required this.onAmountChanged,
  });

  @override
  State<WalletBlock> createState() => _WalletBlockState();
}

class _WalletBlockState extends State<WalletBlock> {
  bool _loading = true;
  WalletBalance? _balance;
  final _amountController = TextEditingController();
  String? _errorText;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _applied = widget.currentAppliedAmount > 0;
    if (_applied) {
      _amountController.text = widget.currentAppliedAmount.toStringAsFixed(2);
    }
  }

  @override
  void didUpdateWidget(covariant WalletBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent cleared the applied amount (e.g. coupon changed),
    // reflect that in our UI.
    if (oldWidget.currentAppliedAmount != widget.currentAppliedAmount) {
      _applied = widget.currentAppliedAmount > 0;
      if (!_applied) {
        _amountController.text = '';
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final result = await WalletService.getBalance();
    if (!mounted) return;
    setState(() {
      _balance = result;
      _loading = false;
    });
  }

  double _maxApplicable() {
    if (_balance == null) return 0;
    final cap = widget.cartTotal;
    return _balance!.balance < cap ? _balance!.balance : cap;
  }

  void _apply() {
    final txt = _amountController.text.replaceAll(',', '.').trim();
    final v = double.tryParse(txt);
    final max = _maxApplicable();
    if (v == null || v <= 0) {
      setState(() => _errorText = 'Entrez un montant supérieur à 0');
      return;
    }
    if (v > max + 0.001) {
      setState(() => _errorText =
          'Maximum ${max.toStringAsFixed(2)} ${_balance?.currency ?? 'TND'}');
      return;
    }
    setState(() {
      _errorText = null;
      _applied = true;
    });
    widget.onAmountChanged(v);
  }

  void _remove() {
    setState(() {
      _applied = false;
      _amountController.text = '';
      _errorText = null;
    });
    widget.onAmountChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    // Render NOTHING while loading or when there's no balance to use:
    // this guarantees a 0-balance / non-whitelisted customer never sees
    // anything related to the wallet — not even a brief loading flash.
    if (_loading ||
        _balance == null ||
        !_balance!.eligible ||
        _balance!.balance <= 0) {
      return const SizedBox.shrink();
    }

    final currency = _balance!.currency;
    final max = _maxApplicable();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Iconsax.wallet_3, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Utiliser mon portefeuille',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const Spacer(),
              if (_balance!.testMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('TEST',
                      style: TextStyle(fontSize: 10, color: Colors.brown)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Solde : ',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  TextSpan(
                    text: '${_balance!.balance.toStringAsFixed(2)} $currency',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Applied state
          if (_applied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(color: Colors.green.shade400, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.tick_circle,
                      color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Appliqué : ${widget.currentAppliedAmount.toStringAsFixed(2)} $currency',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _remove,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('Retirer',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[\.,]?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          hintText: '0.00 — ${max.toStringAsFixed(2)}',
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(currency,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AlkColors.AppFirstColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _errorText!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
