import 'package:alkirtas/features/authentication/screens/login/forgot_password_webview.dart';
import 'package:alkirtas/features/authentication/screens/signUp/sign_up.dart';
import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlkLoginForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final void Function(BuildContext) onSignIn;
  final Widget? googleButton;

  const AlkLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
    this.googleButton,
  });

  @override
  _AlkLoginFormState createState() => _AlkLoginFormState();
}

class _AlkLoginFormState extends State<AlkLoginForm> with TickerProviderStateMixin {
  final RxBool isObscured = true.obs;
  final RxBool isRememberMeChecked = false.obs;
  late AnimationController _formController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _loadSavedCredentials();
    _formController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final rememberMe = prefs.getBool('remember_me') ?? false;

    setState(() {
      widget.emailController.text = savedEmail;
      widget.passwordController.text = savedPassword;
      isRememberMeChecked.value = rememberMe;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (isRememberMeChecked.value) {
      await prefs.setString('saved_email', widget.emailController.text);
      await prefs.setString('saved_password', widget.passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AlkSize.spaceBtwSections),
            child: Column(
              children: [
                // Email Input with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AlkColors.AppSecColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Iconsax.direct, color: AlkColors.AppSecColor),
                      label: const Text('E-mail'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AlkColors.AppSecColor, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),
                // Password Input with Visibility Toggle and enhanced styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AlkColors.AppSecColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() => TextFormField(
                        controller: widget.passwordController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.password_check, color: AlkColors.AppSecColor),
                          labelText: 'Mot de passe',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AlkColors.AppSecColor, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscured.value ? Iconsax.eye_slash : Iconsax.eye,
                              color: AlkColors.AppSecColor,
                            ),
                            onPressed: () {
                              isObscured.value = !isObscured.value;
                            },
                          ),
                        ),
                        obscureText: isObscured.value,
                      )),
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields / 2),
                // Remember Me and Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Row(
                          children: [
                            Checkbox(
                              value: isRememberMeChecked.value,
                              onChanged: (value) {
                                isRememberMeChecked.value = value ?? false;
                              },
                              activeColor: AlkColors.AppSecColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Text(
                              'Mémoriser info',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        )),
                    Flexible(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ForgotPasswordWebView()),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AlkColors.AppSecColor,
                        ),
                        child: const Text(
                          'Mot de passe oublié?',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwSections),
                // Google Sign-In button (compact, sits right above the Connexion button)
                if (widget.googleButton != null) ...[
                  widget.googleButton!,
                  const SizedBox(height: AlkSize.spaceBtwItems),
                ],
                // Sign In Button with enhanced styling
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AlkColors.AppSecColor,
                        AlkColors.AppFirstColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AlkColors.AppSecColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await _saveCredentials();
                      if (context.mounted) {
                        widget.onSignIn(context);
                      }
                    },
                    child: const Text(
                      'Connexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AlkSize.spaceBtwItems),
                // Create Account Button with enhanced styling
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Get.to(() => const SignUpScreen()),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AlkColors.AppSecColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: AlkColors.AppFirstColor,
                    ),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}