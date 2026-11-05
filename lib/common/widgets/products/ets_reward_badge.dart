import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:alkirtas/data/controllers/ets_service.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/features/authentication/screens/signUp/sign_up.dart';
import 'package:alkirtas/utils/backendData/userData.dart';

/// "Gagnez X TND" gold tag next to "En Stock": the ETS reward for buying this
/// product, same amount and same rules as the website's product page
/// (module alk_loyaltyhint). Tapping it shows the website's message.
/// Shows nothing when the product earns no reward.
class EtsRewardTag extends StatefulWidget {
  final String productId;

  const EtsRewardTag({super.key, required this.productId});

  @override
  State<EtsRewardTag> createState() => _EtsRewardTagState();
}

class _EtsRewardTagState extends State<EtsRewardTag> {
  static const Color _plum = Color(0xFF7A1A5A);
  double _reward = 0;
  double _cartMin = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EtsRewardTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) _load();
  }

  Future<void> _load() async {
    final reward = await EtsService.productReward(widget.productId);
    final cartMin = EtsService.productCartMin(widget.productId);
    if (mounted && (reward != _reward || cartMin != _cartMin)) {
      setState(() {
        _reward = reward;
        _cartMin = cartMin;
      });
    }
  }

  void _showMessage() {
    final logged = UserData.id.isNotEmpty;
    final amount = '${EtsService.format(_reward)} TND';
    const textStyle = TextStyle(fontSize: 15, height: 1.4, color: Colors.black87);
    const bold = TextStyle(fontWeight: FontWeight.w700);
    // Product alone under the ETS minimum, same words as the website.
    final cartMin = _cartMin > 0
        ? [
            const TextSpan(text: ', dès que votre panier atteint '),
            TextSpan(text: '${EtsService.format(_cartMin)} TND', style: bold),
            const TextSpan(text: ' (hors livraison)'),
          ]
        : const <TextSpan>[];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  EtsPopper(size: 36),
                  SizedBox(width: 10),
                  Text('Récompenses',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                logged
                    ? TextSpan(style: textStyle, children: [
                        const TextSpan(text: 'Achetez ce produit et gagnez '),
                        TextSpan(text: amount, style: bold),
                        const TextSpan(text: ' de récompenses'),
                        ...cartMin,
                        const TextSpan(text: '.'),
                      ])
                    : TextSpan(style: textStyle, children: [
                        const TextSpan(text: 'Connectez-vous ou créez un compte pour gagner '),
                        TextSpan(text: amount, style: bold),
                        const TextSpan(text: ' de récompenses avec ce produit'),
                        ...cartMin,
                        const TextSpan(text: '.'),
                      ]),
              ),
              if (!logged) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Get.to(() => const LoginScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _plum,
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Get.to(() => const SignUpScreen());
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _plum,
                          side: const BorderSide(color: _plum),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Créer un compte', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reward <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showMessage,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF5C842)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EtsPopper(size: 22),
            const SizedBox(width: 5),
            Text(
              'Gagnez ${_reward.toStringAsFixed(3)} TND',
              style: const TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Party popper of the website's reward message (lib/assets/icons/cotillon.svg).
/// Every 2.4 s it tilts to -12° and grows to 115%, then 8°, then back,
/// pivoting near its bottom-left, like the website's alk-lh-pop animation.
class EtsPopper extends StatefulWidget {
  final double size;

  const EtsPopper({super.key, this.size = 36});

  @override
  State<EtsPopper> createState() => _EtsPopperState();
}

class _EtsPopperState extends State<EtsPopper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  // Website keyframes: 0-60% still, 70% -12° x1.15, 80% 8° x1.05, 100% still (ease-in-out).
  static final _angle = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: -12.0, end: 8.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
  ]);
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
  ]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Transform(
          // transform-origin: 30% 80%
          alignment: const Alignment(-0.4, 0.6),
          transform: Matrix4.identity()
            ..rotateZ(_angle.transform(t) * math.pi / 180)
            ..scale(_scale.transform(t)),
          child: child,
        );
      },
      child: SvgPicture.asset('lib/assets/icons/cotillon.svg', width: s, height: s),
    );
  }
}

/// Gold "DT" coin that flips every 3 seconds, like on the website.
class EtsCoin extends StatefulWidget {
  final double size;

  const EtsCoin({super.key, this.size = 18});

  @override
  State<EtsCoin> createState() => _EtsCoinState();
}

class _EtsCoinState extends State<EtsCoin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Still for 70% of the time, then one full turn (website: 0-70% still, 85% half, 100% full).
  double _angle(double t) => t < 0.7 ? 0 : (t - 0.7) / 0.3 * 2 * math.pi;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(_angle(Curves.linear.transform(_controller.value))),
        child: child,
      ),
      child: Container(
        width: s,
        height: s,
        decoration: const BoxDecoration(color: Color(0xFFF5B301), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          width: s * 0.76,
          height: s * 0.76,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD34D),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE09A00), width: s * 0.05),
          ),
          alignment: Alignment.center,
          child: Text(
            'DT',
            style: TextStyle(
              fontSize: s * 0.36,
              height: 1,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB87400),
            ),
          ),
        ),
      ),
    );
  }
}
