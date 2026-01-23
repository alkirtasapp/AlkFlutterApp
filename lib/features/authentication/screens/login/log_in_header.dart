import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';

class AlkLoginHeader extends StatefulWidget {
  const AlkLoginHeader({super.key, required this.dark});

  final bool dark;

  @override
  State<AlkLoginHeader> createState() => _AlkLoginHeaderState();
}

class _AlkLoginHeaderState extends State<AlkLoginHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                         AlkColors.AppSecColor.withOpacity(0.3),
                  AlkColors.AppSecColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Image(
                    height: 130,
                    image: AssetImage(
                        widget.dark ? AlkImages.splashLogo : AlkImages.splashLogo),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AlkSize.lg),
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Bienvenue',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AlkColors.AppFirstColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous à votre compte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}