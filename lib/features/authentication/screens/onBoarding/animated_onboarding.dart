import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';

class AnimatedOnboardingScreen extends StatefulWidget {
  const AnimatedOnboardingScreen({super.key});

  @override
  State<AnimatedOnboardingScreen> createState() => _AnimatedOnboardingScreenState();
}

class _AnimatedOnboardingScreenState extends State<AnimatedOnboardingScreen> with TickerProviderStateMixin {
  static const int _pageCount = 8;

  int currentPage = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    Get.offAll(() => LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: completeOnboarding,
                    child: const Text('Passer', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: const [
                  OnboardingWelcomePage(key: ValueKey('page_welcome')),
                  OnboardingAudiobookSamplePage(key: ValueKey('page_audiobook')),
                  OnboardingQrScannerPage(key: ValueKey('page_scanner')),
                  OnboardingCouponPage(key: ValueKey('page_coupon')),
                  OnboardingCartQrPosPage(key: ValueKey('page_cart_qr')),
                  OnboardingLoyaltyPage(key: ValueKey('page_loyalty')),
                  OnboardingScratchCardPage(key: ValueKey('page_scratch')),
                  OnboardingWishlistPage(key: ValueKey('page_wishlist')),
                ],
              ),
            ),

            // Bottom section with indicator and button
            Padding(
              padding: const EdgeInsets.all(AlkSize.defaultSpace),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(_pageCount, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? AlkColors.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next/Start button
                  ElevatedButton(
                    onPressed: () {
                      if (currentPage == _pageCount - 1) {
                        completeOnboarding();
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Icon(
                      currentPage == _pageCount - 1 ? Iconsax.tick_circle : Iconsax.arrow_right_3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget illustration;
  final String? footerText;

  const _PageScaffold({
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            illustration,
            if (footerText != null) ...[
              const SizedBox(height: 24),
              Text(
                footerText!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AlkColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        const double s = 80;
        return SizedBox(
          width: s * 2.4,
          height: s * 2.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: s * (1.6 + 0.5 * t),
                height: s * (1.6 + 0.5 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.08 * (1 - t)),
                ),
              ),
              // Mid ring
              Container(
                width: s * (1.3 + 0.3 * t),
                height: s * (1.3 + 0.3 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.12),
                ),
              ),
              // Solid bubble
              Container(
                width: s * 1.6,
                height: s * 1.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.15),
                ),
                child: Icon(widget.icon, size: s, color: widget.color),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Welcome
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingWelcomePage extends StatefulWidget {
  const OnboardingWelcomePage({super.key});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _PageScaffold(
          title: 'Bienvenue sur Alkirtas!',
          subtitle:
              'Découvrez les fonctionnalités qui rendent votre expérience unique',
          illustration: const _PulsingIcon(
            icon: Iconsax.shop,
            color: AlkColors.primaryColor,
          ),
          footerText: 'Glissez pour découvrir',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Audiobook samples
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingAudiobookSamplePage extends StatefulWidget {
  const OnboardingAudiobookSamplePage({super.key});

  @override
  State<OnboardingAudiobookSamplePage> createState() =>
      _OnboardingAudiobookSamplePageState();
}

class _OnboardingAudiobookSamplePageState
    extends State<OnboardingAudiobookSamplePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Écoutez avant d\'acheter',
      subtitle:
          'Un extrait audio généré pour chaque livre ',
      illustration: Column(
        children: [
          // Mock audio player card
          Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AlkColors.primaryColor,
                  AlkColors.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AlkColors.primaryColor.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.book_1,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Extrait audio',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                          SizedBox(height: 4),
                          Text('Généré automatiquement',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Animated waveform
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return SizedBox(
                      height: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(22, (i) {
                          final phase = (_controller.value * 2 * math.pi) +
                              (i * 0.5);
                          final h = 8 + 22 * (0.5 + 0.5 * math.sin(phase));
                          return Container(
                            width: 4,
                            height: h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.pause,
                          color: AlkColors.primaryColor, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      footerText: 'Cliquez sur l\'icône audio sur la fiche produit',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. QR product scanner
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingQrScannerPage extends StatefulWidget {
  const OnboardingQrScannerPage({super.key});

  @override
  State<OnboardingQrScannerPage> createState() =>
      _OnboardingQrScannerPageState();
}

class _OnboardingQrScannerPageState extends State<OnboardingQrScannerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Scannez les produits',
      subtitle:
          'Scannez le code-barres d\'un produit pour l\'ajouter instantanément à votre panier',
      illustration: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Frame
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Corners
            ..._buildCorners(),
            // Scanning line
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final dy = -90 + 180 * _controller.value;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: 180,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AlkColors.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AlkColors.primaryColor.withOpacity(0.7),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Barcode preview
            Container(
              width: 140,
              height: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(20, (i) {
                  final w = (i % 3 == 0) ? 3.0 : (i % 2 == 0 ? 2.0 : 1.5);
                  return Container(
                    width: w,
                    color: Colors.black,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      footerText: 'Bouton scanner dans la barre de recherche',
    );
  }

  List<Widget> _buildCorners() {
    const double size = 28;
    const double thickness = 4;
    final color = AlkColors.primaryColor;
    Widget corner({required Alignment alignment, required BorderSide top, required BorderSide left, required BorderSide right, required BorderSide bottom}) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(top: top, left: left, right: right, bottom: bottom),
            ),
          ),
        ),
      );
    }

    final side = BorderSide(color: color, width: thickness);
    final none = BorderSide.none;

    return [
      corner(alignment: Alignment.topLeft, top: side, left: side, right: none, bottom: none),
      corner(alignment: Alignment.topRight, top: side, left: none, right: side, bottom: none),
      corner(alignment: Alignment.bottomLeft, top: none, left: side, right: none, bottom: side),
      corner(alignment: Alignment.bottomRight, top: none, left: none, right: side, bottom: side),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Coupon
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingCouponPage extends StatefulWidget {
  const OnboardingCouponPage({super.key});

  @override
  State<OnboardingCouponPage> createState() => _OnboardingCouponPageState();
}

class _OnboardingCouponPageState extends State<OnboardingCouponPage>
    with TickerProviderStateMixin {
  bool showCoupon = false;
  bool showApply = false;
  bool showDiscount = false;

  @override
  void initState() {
    super.initState();
    _animateCouponFlow();
  }

  void _animateCouponFlow() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showCoupon = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => showApply = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => showDiscount = true);
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        showCoupon = false;
        showApply = false;
        showDiscount = false;
      });
      _animateCouponFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Économisez avec les coupons',
      subtitle: 'Saisissez un code promo au panier pour activer votre réduction',
      illustration: Column(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: showCoupon ? 1.0 : 0.0,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AlkColors.primaryColor,
                    AlkColors.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AlkColors.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Icon(Iconsax.ticket_discount, size: 40, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'PROMO20',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Réduction de 20%',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: showApply ? 1.0 : 0.0,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: const Text('Appliquer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: showDiscount ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '100.00 TND',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_right, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '80.00 TND',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      footerText: 'Profitez de vos réductions!',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. QR Cart → POS
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingCartQrPosPage extends StatefulWidget {
  const OnboardingCartQrPosPage({super.key});

  @override
  State<OnboardingCartQrPosPage> createState() =>
      _OnboardingCartQrPosPageState();
}

class _OnboardingCartQrPosPageState extends State<OnboardingCartQrPosPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Payez en magasin',
      subtitle:
          'Générez un QR code de votre panier et scannez-le à la caisse pour payer en magasin',
      illustration: SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Phone with QR code
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 130,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        height: 16,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AlkColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Mon panier',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AlkColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const _MockQrCode(size: 100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated beam
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.3 + 0.7 * _controller.value,
                  child: Icon(
                    Iconsax.arrow_right_3,
                    size: 36,
                    color: AlkColors.primaryColor,
                  ),
                );
              },
            ),

            // POS terminal
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(Iconsax.scan,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Iconsax.shop,
                                    color: Colors.white70, size: 18),
                                SizedBox(height: 4),
                                Text('POS',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      footerText: 'Scannez à la caisse — payez sans queue',
    );
  }
}

class _MockQrCode extends StatelessWidget {
  final double size;
  const _MockQrCode({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QrPainter(),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const cells = 11;
    final cell = size.width / cells;
    final rng = math.Random(42);
    for (int x = 0; x < cells; x++) {
      for (int y = 0; y < cells; y++) {
        if (rng.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }
    // Finder patterns (corners)
    void finder(double cx, double cy) {
      final outer = Paint()..color = Colors.black;
      final inner = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(cx, cy, cell * 3, cell * 3), outer);
      canvas.drawRect(
          Rect.fromLTWH(cx + cell * 0.5, cy + cell * 0.5, cell * 2, cell * 2),
          inner);
      canvas.drawRect(
          Rect.fromLTWH(cx + cell, cy + cell, cell, cell), outer);
    }

    finder(0, 0);
    finder((cells - 3) * cell, 0);
    finder(0, (cells - 3) * cell);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Loyalty points wallet
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingLoyaltyPage extends StatefulWidget {
  const OnboardingLoyaltyPage({super.key});

  @override
  State<OnboardingLoyaltyPage> createState() => _OnboardingLoyaltyPageState();
}

class _OnboardingLoyaltyPageState extends State<OnboardingLoyaltyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _points;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _points = IntTween(begin: 0, end: 1240).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _loop();
  }

  void _loop() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _controller.reset();
    _loop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Vos points fidélité',
      subtitle:
          'Cumulez des points à chaque achat, échangez-les contre des remises, des cadeaux ou la livraison gratuite',
      illustration: Container(
        width: 290,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1F1147),
              AlkColors.primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AlkColors.primaryColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Iconsax.medal_star, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  'Carte fidélité',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Solde actuel',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _points,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_points.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'points',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            // Mock barcode
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(36, (i) {
                        final w = (i % 4 == 0) ? 3.0 : (i % 2 == 0 ? 2.0 : 1.0);
                        return Container(width: w, color: Colors.black);
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ALK-1240-USR',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footerText: 'Scannez en magasin pour utiliser vos points',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Scratch card
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScratchCardPage extends StatefulWidget {
  const OnboardingScratchCardPage({super.key});

  @override
  State<OnboardingScratchCardPage> createState() =>
      _OnboardingScratchCardPageState();
}

class _OnboardingScratchCardPageState extends State<OnboardingScratchCardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Carte à gratter',
      subtitle:
          'À l\'inscription, grattez votre carte pour gagner des points, une remise ou la livraison gratuite',
      illustration: SizedBox(
        width: 260,
        height: 200,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // 0..1 progress: scratch reveals; then resets
            final t = _controller.value;
            // First half scratches, second half holds
            final reveal = (t * 2).clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Reward card (back)
                Container(
                  width: 240,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Iconsax.gift, size: 50, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        '+200 points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bienvenue chez Alkirtas!',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Scratch overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 240,
                    height: 180,
                    child: ClipPath(
                      clipper: _ScratchClipper(reveal),
                      child: Container(
                        color: Colors.grey.shade400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.magicpen,
                                  color: Colors.white, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'Grattez ici',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      footerText: 'Disponible une seule fois — à la première connexion',
    );
  }
}

class _ScratchClipper extends CustomClipper<Path> {
  final double reveal;
  _ScratchClipper(this.reveal);

  @override
  Path getClip(Size size) {
    // The clip keeps the overlay only outside the reveal area.
    final outer = Path()..addRect(Offset.zero & size);
    final cx = size.width * (0.2 + 0.6 * reveal);
    final cy = size.height / 2;
    final r = size.width * 0.6 * reveal;
    final hole = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(covariant _ScratchClipper oldClipper) =>
      oldClipper.reveal != reveal;
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Wishlist — price drop + stock comeback alerts
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingWishlistPage extends StatefulWidget {
  const OnboardingWishlistPage({super.key});

  @override
  State<OnboardingWishlistPage> createState() =>
      _OnboardingWishlistPageState();
}

class _OnboardingWishlistPageState extends State<OnboardingWishlistPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool showNotif = false;
  // 0 = price drop banner, 1 = stock comeback banner
  int notifVariant = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loop();
  }

  void _loop() async {
    while (mounted) {
      setState(() => showNotif = false);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => showNotif = true);
      _controller.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return;
      setState(() => notifVariant = 1 - notifVariant);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Ma liste de souhaits',
      subtitle:
          'Ajoutez vos produits favoris et soyez notifié dès qu\'ils baissent de prix ou reviennent en stock',
      illustration: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Price history sparkline
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AlkColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Iconsax.book_1,
                              color: AlkColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Livre suivi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Alerte activée',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.notification,
                            color: AlkColors.primaryColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: CustomPaint(
                        painter: _PriceLinePainter(),
                        size: Size.infinite,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('40 TND',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            )),
                        Row(
                          children: const [
                            Icon(Iconsax.trend_down,
                                color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '28 TND',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Floating notification banner (alternates between price drop and stock comeback)
            AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              offset: showNotif ? Offset.zero : const Offset(0, -1.5),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: showNotif ? 1.0 : 0.0,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (notifVariant == 0 ? Colors.green : Colors.blue)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          notifVariant == 0
                              ? Iconsax.discount_shape
                              : Iconsax.box_tick,
                          color:
                              notifVariant == 0 ? Colors.green : Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notifVariant == 0
                                  ? 'Le prix a baissé!'
                                  : 'De retour en stock!',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notifVariant == 0
                                  ? '-30% sur un produit suivi'
                                  : 'Votre produit est à nouveau disponible',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      footerText: 'Activez la cloche depuis la fiche produit',
    );
  }
}

class _PriceLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlkColors.primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AlkColors.primaryColor.withOpacity(0.25),
          AlkColors.primaryColor.withOpacity(0.0),
        ],
      ).createShader(Offset.zero & size);

    final pts = <Offset>[
      Offset(size.width * 0.0, size.height * 0.30),
      Offset(size.width * 0.18, size.height * 0.20),
      Offset(size.width * 0.35, size.height * 0.45),
      Offset(size.width * 0.52, size.height * 0.40),
      Offset(size.width * 0.70, size.height * 0.55),
      Offset(size.width * 0.85, size.height * 0.75),
      Offset(size.width * 1.0, size.height * 0.85),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);

    // End dot
    final dot = Paint()..color = Colors.green;
    canvas.drawCircle(pts.last, 5, dot);
    canvas.drawCircle(
        pts.last,
        8,
        Paint()
          ..color = Colors.green.withOpacity(0.25)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
