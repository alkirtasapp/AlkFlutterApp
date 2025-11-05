import 'dart:math';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  double _opacity = 0.0;
  late final String _quote;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _rotationController;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

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

    // Initialize main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Initialize pulse animation for loading indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize rotation animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFF3E5F5),
                    const Color(0xFFE1BEE7),
                    const Color(0xFFCE93D8),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles/particles
            _buildFloatingParticles(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with enhanced animations
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.deepPurple.withOpacity(0.25),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            AlkImages.splashLogo,
                            height: 120,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Custom loading indicator with pulse animation
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeIn,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer rotating circle
                          RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          // Inner progress indicator
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.purpleAccent : Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Loading text with shimmer effect
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeIn,
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [
                                0.0,
                                _shimmerAnimation.value - 0.3,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.3,
                                1.0,
                              ],
                              colors: [
                                isDark ? Colors.white70 : Colors.black87,
                                isDark ? Colors.white : Colors.black,
                                isDark ? Colors.purpleAccent : Colors.purple,
                                isDark ? Colors.white : Colors.black,
                                isDark ? Colors.white70 : Colors.black87,
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            _quote,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Animated dots
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeIn,
                    child: _buildLoadingDots(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(6, (index) {
        final random = Random(index);
        final size = 50.0 + random.nextDouble() * 100;
        final left = random.nextDouble() * 400;
        final top = random.nextDouble() * 800;

        return Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: (0.05 + (random.nextDouble() * 0.1)) * _pulseAnimation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final offset = (index * 0.33);
            final animationValue = (_pulseController.value + offset) % 1.0;
            final scale = 0.5 + (sin(animationValue * 2 * pi) * 0.5);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
