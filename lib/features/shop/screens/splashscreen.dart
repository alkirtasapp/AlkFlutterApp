import 'dart:math';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late final String _quote;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  final List<String> _quotes = [
    "Chargement...",
    "Préparation de votre expérience...",
    "Chargement des nouveautés...",
    "Optimisation de l'expérience...",
    "Patientez un instant, presque prêt !",
  ];

  @override
  void initState() {
    super.initState();

    // Random quote
    _quote = _quotes[Random().nextInt(_quotes.length)];

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _opacity = 1.0);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    AlkImages.darkAppLogo,
                    height: 150,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              child: const CircularProgressIndicator(color: Colors.purple),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              child: Text(
                _quote,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center
              ),
            ),
          ],
        ),
      ),
    );
  }
}
