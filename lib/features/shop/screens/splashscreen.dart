import 'dart:math';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  late final String _quote;

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

    // Start logo fade animation
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _opacity = 1.0);
    });
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
              duration: const Duration(milliseconds: 1000),
              child: Image.asset(
                AlkImages.darkAppLogo,
                height: 150,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              _quote,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
