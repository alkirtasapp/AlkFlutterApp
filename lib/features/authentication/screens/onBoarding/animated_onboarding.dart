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
                children: [
                  OnboardingNavigationDemo1(key: ValueKey('page_0')),
                  OnboardingNavigationDemo2(key: ValueKey('page_1')),
                  OnboardingNavigationDemo3(key: ValueKey('page_2')),
                  OnboardingNavigationDemo4(key: ValueKey('page_3')),
                  OnboardingNavigationDemo5(key: ValueKey('page_4')),
                  OnboardingNavigationDemo6(key: ValueKey('page_5')),
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
                    children: List.generate(6, (index) {
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
                      if (currentPage == 5) {
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
                      currentPage == 5 ? Iconsax.tick_circle : Iconsax.arrow_right_3,
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

// Demo 1: Welcome & Navigate to Store
class OnboardingNavigationDemo1 extends StatefulWidget {
  const OnboardingNavigationDemo1({super.key});

  @override
  State<OnboardingNavigationDemo1> createState() => _OnboardingNavigationDemo1State();
}

class _OnboardingNavigationDemo1State extends State<OnboardingNavigationDemo1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(AlkSize.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon or illustration
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AlkColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.shop,
                  size: 80,
                  color: AlkColors.primaryColor,
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'Bienvenue sur Alkirtas!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Découvrez comment naviguer facilement dans votre boutique en ligne',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Animated navigation hint
              _AnimatedNavigationHint(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavigationHint extends StatefulWidget {
  @override
  State<_AnimatedNavigationHint> createState() => _AnimatedNavigationHintState();
}

class _AnimatedNavigationHintState extends State<_AnimatedNavigationHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * _controller.value),
          child: Icon(
            Iconsax.arrow_down_1,
            size: 32,
            color: AlkColors.primaryColor.withOpacity(0.5 + 0.5 * _controller.value),
          ),
        );
      },
    );
  }
}

// Demo 2: Bottom Navigation Animation
class OnboardingNavigationDemo2 extends StatefulWidget {
  const OnboardingNavigationDemo2({super.key});

  @override
  State<OnboardingNavigationDemo2> createState() => _OnboardingNavigationDemo2State();
}

class _OnboardingNavigationDemo2State extends State<OnboardingNavigationDemo2>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Animate tab selection
    _animateTabs();
  }

  void _animateTabs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => selectedTab = 0);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (mounted) {
      setState(() => selectedTab = 1);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    // Repeat
    _animateTabs();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Navigation facile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Accédez rapidement à vos sections',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

          // Mock phone screen
          Container(
            width: 280,
            height: 450,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 8),
              borderRadius: BorderRadius.circular(32),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mock status bar
                Container(
                  height: 30,
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedTab == 0 ? Iconsax.home : Iconsax.shop,
                          size: 60,
                          color: AlkColors.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedTab == 0 ? 'Accueil' : 'Boutique',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation bar
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Iconsax.home, 'Accueil', 0),
                      _buildNavItem(Iconsax.shop, 'Boutique', 1),
                      _buildNavItem(Iconsax.shopping_cart, 'Panier', 2),
                      _buildNavItem(Iconsax.user, 'Profil', 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instruction with animation
          _AnimatedTapInstruction(
            text: 'Naviguez vers Boutique',
            icon: Iconsax.shop,
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedTab == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AlkColors.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AlkColors.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AlkColors.primaryColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTapInstruction extends StatefulWidget {
  final String text;
  final IconData icon;

  const _AnimatedTapInstruction({
    required this.text,
    required this.icon,
  });

  @override
  State<_AnimatedTapInstruction> createState() => _AnimatedTapInstructionState();
}

class _AnimatedTapInstructionState extends State<_AnimatedTapInstruction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AlkColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AlkColors.primaryColor.withOpacity(0.3 + 0.3 * _controller.value),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: AlkColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: AlkColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Demo 3: Drawer & Categories
class OnboardingNavigationDemo3 extends StatefulWidget {
  const OnboardingNavigationDemo3({super.key});

  @override
  State<OnboardingNavigationDemo3> createState() => _OnboardingNavigationDemo3State();
}

class _OnboardingNavigationDemo3State extends State<OnboardingNavigationDemo3>
    with TickerProviderStateMixin {
  bool showDrawer = false;
  bool expandLivres = false;
  bool showSubcategory = false;

  @override
  void initState() {
    super.initState();
    _animateDrawer();
  }

  void _animateDrawer() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showDrawer = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => expandLivres = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => showSubcategory = true);
    await Future.delayed(const Duration(milliseconds: 2000));

    // Reset and repeat
    if (mounted) {
      setState(() {
        showDrawer = false;
        expandLivres = false;
        showSubcategory = false;
      });
      _animateDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Explorez les catégories',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Ouvrez le menu pour naviguer dans les catégories',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

          // Mock phone screen with drawer
          Container(
            width: 280,
            height: 450,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 8),
              borderRadius: BorderRadius.circular(32),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      // App bar
                      Container(
                        height: 56,
                        color: Colors.white,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {},
                            ),
                            const Text(
                              'Boutique',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Text(
                              'Produits',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Drawer overlay
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: showDrawer ? 0 : -250,
                    top: 0,
                    bottom: 0,
                    width: 250,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 56),
                          _buildDrawerItem(
                            'Livres',
                            Icons.menu_book,
                            expanded: expandLivres,
                            onTap: () {},
                          ),
                          if (expandLivres && showSubcategory) ...[
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: showSubcategory ? 1.0 : 0.0,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('  • Romans', style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 2),
                                    Text('  • Jeunesse', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          _buildDrawerItem('Papeterie', Iconsax.note, expanded: false, onTap: () {}),
                          _buildDrawerItem('Bagagerie', Iconsax.bag, expanded: false, onTap: () {}),
                        ],
                      ),
                    ),
                  ),

                  // Scrim when drawer is open
                  if (showDrawer)
                    Positioned.fill(
                      left: 250,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _AnimatedTapInstruction(
            text: 'Ouvrez le menu',
            icon: Icons.menu,
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, {required bool expanded, required VoidCallback onTap}) {
    return Container(
      color: expanded ? AlkColors.primaryColor.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: expanded ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          expanded ? Icons.expand_more : Icons.chevron_right,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Demo 4: Search & QR Features
class OnboardingNavigationDemo4 extends StatefulWidget {
  const OnboardingNavigationDemo4({super.key});

  @override
  State<OnboardingNavigationDemo4> createState() => _OnboardingNavigationDemo4State();
}

class _OnboardingNavigationDemo4State extends State<OnboardingNavigationDemo4>
    with TickerProviderStateMixin {
  bool showSearch = false;
  bool showQR = false;

  @override
  void initState() {
    super.initState();
    _animateFeatures();
  }

  void _animateFeatures() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showSearch = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => showSearch = false);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showQR = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Reset and repeat
    if (mounted) {
      setState(() => showQR = false);
      _animateFeatures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Fonctionnalités avancées',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Recherchez ou scannez les codes QR',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

          // Features showcase
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureCard(
                icon: Iconsax.search_normal,
                title: 'Recherche',
                description: 'Trouvez rapidement vos produits',
                isActive: showSearch,
              ),
              _buildFeatureCard(
                icon: Iconsax.scan,
                title: 'Scanner QR',
                description: 'Scannez pour accéder',
                isActive: showQR,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Visual demo
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: showSearch || showQR
                  ? AlkColors.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: showSearch || showQR
                    ? AlkColors.primaryColor
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showSearch
                    ? Icon(
                        Iconsax.search_normal,
                        key: const ValueKey('search'),
                        size: 80,
                        color: AlkColors.primaryColor,
                      )
                    : showQR
                        ? Icon(
                            Iconsax.scan,
                            key: const ValueKey('qr'),
                            size: 80,
                            color: AlkColors.primaryColor,
                          )
                        : Icon(
                            Iconsax.shop,
                            key: const ValueKey('default'),
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Vous êtes prêt à commencer!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AlkColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AlkColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AlkColors.primaryColor : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AlkColors.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: isActive ? Colors.white : AlkColors.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Demo 5: Shopping Cart Flow
class OnboardingNavigationDemo5 extends StatefulWidget {
  const OnboardingNavigationDemo5({super.key});

  @override
  State<OnboardingNavigationDemo5> createState() => _OnboardingNavigationDemo5State();
}

class _OnboardingNavigationDemo5State extends State<OnboardingNavigationDemo5>
    with TickerProviderStateMixin {
  bool showProduct = false;
  bool showAddToCart = false;
  bool showCartBadge = false;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    _animateCartFlow();
  }

  void _animateCartFlow() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showProduct = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => showAddToCart = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        showCartBadge = true;
        cartCount = 1;
      });
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        cartCount = 2;
      });
    }
    await Future.delayed(const Duration(milliseconds: 2000));

    // Reset and repeat
    if (mounted) {
      setState(() {
        showProduct = false;
        showAddToCart = false;
        showCartBadge = false;
        cartCount = 0;
      });
      _animateCartFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Ajoutez au panier',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Sélectionnez vos produits facilement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Mock product card
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: showProduct ? 1.0 : 0.0,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Product image placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Livre Example',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '29.99 TND',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AlkColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Add to cart button with animation
                    AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: showAddToCart ? 1.0 : 0.0,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Iconsax.shopping_cart, size: 18),
                        label: Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlkColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Cart icon with badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AlkColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Iconsax.shopping_cart,
                    size: 50,
                    color: AlkColors.primaryColor,
                  ),
                  if (showCartBadge)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Vos articles sont ajoutés!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AlkColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Demo 6: Coupon/Discount Feature
class OnboardingNavigationDemo6 extends StatefulWidget {
  const OnboardingNavigationDemo6({super.key});

  @override
  State<OnboardingNavigationDemo6> createState() => _OnboardingNavigationDemo6State();
}

class _OnboardingNavigationDemo6State extends State<OnboardingNavigationDemo6>
    with TickerProviderStateMixin {
  bool showCoupon = false;
  bool showApply = false;
  bool showDiscount = false;
  String originalPrice = '100.00 TND';
  String discountedPrice = '80.00 TND';

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

    // Reset and repeat
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AlkSize.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Économisez avec les coupons',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Utilisez vos codes promo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Coupon card
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
                  children: [
                    Icon(
                      Iconsax.ticket_discount,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PROMO20',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Réduction de 20%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Apply button
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: showApply ? 1.0 : 0.0,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Iconsax.tick_circle, size: 18),
                label: Text('Appliquer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Price comparison
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: showDiscount ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          originalPrice,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Iconsax.arrow_right, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          discountedPrice,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Économie: 20 TND',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Profitez de vos réductions!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AlkColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
