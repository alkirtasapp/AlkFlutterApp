import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/features/scratch_card/scratch_card_screen.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';

class ScratchCardBanner extends StatefulWidget {
  const ScratchCardBanner({super.key});

  @override
  State<ScratchCardBanner> createState() => _ScratchCardBannerState();
}

class _ScratchCardBannerState extends State<ScratchCardBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final Animation<double> _shimmerValue =
      Tween<double>(begin: -1.5, end: 2.5).animate(
    CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AlkColors.AppFirstColor;
    final light = Color.lerp(base, Colors.white, 0.35)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AlkSize.sm,
        vertical: AlkSize.xs,
      ),
      child: GestureDetector(
        onTap: () => Get.to(
          () => const ScratchCardScreen(),
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 400),
        ),
        child: AnimatedBuilder(
          animation: _shimmerValue,
          builder: (context, _) {
            final v = _shimmerValue.value;
            return Container(
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [base, light, Colors.white.withOpacity(0.85), light, base],
                  stops: [
                    0.0,
                    (v - 0.4).clamp(0.0, 1.0),
                    v.clamp(0.0, 1.0),
                    (v + 0.4).clamp(0.0, 1.0),
                    1.0,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: base.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grattez & Gagnez ! 🎁',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Votre récompense vous attend',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
