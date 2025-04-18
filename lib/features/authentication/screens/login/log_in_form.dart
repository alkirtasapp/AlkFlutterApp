import 'package:alkirtas/features/authentication/screens/login/forgot_password_webview.dart';
import 'package:alkirtas/features/authentication/screens/signUp/sign_up.dart';
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

  const AlkLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
  });

  @override
  _AlkLoginFormState createState() => _AlkLoginFormState();
}

class _AlkLoginFormState extends State<AlkLoginForm> {
  final RxBool isObscured = true.obs;
  final RxBool isRememberMeChecked = false.obs;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
    return Form(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AlkSize.spaceBtwSections),
        child: Column(
          children: [
            // Email Input
            TextFormField(
              controller: widget.emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                label: Text('Email'),
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwInputFields),
            // Password Input with Visibility Toggle
            Obx(() => TextFormField(
                  controller: widget.passwordController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Iconsax.password_check),
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(isObscured.value ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () {
                        isObscured.value = !isObscured.value;
                      },
                    ),
                  ),
                  obscureText: isObscured.value,
                )),
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
                        ),
                        const Text('Mémoriser info'),
                      ],
                    )),
                Flexible(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ForgotPasswordWebView()),
                    ),
                    child: const Text(
                      'Mot de passe oublié?',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AlkSize.spaceBtwSections),
            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent[700],
                ),
                onPressed: () async {
                  await _saveCredentials();
                  widget.onSignIn(context);
                },
                child: const Text(
                  'Connexion',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwItems),
            // Create Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(() => const SignUpScreen()),
                child: const Text('Créer un compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}