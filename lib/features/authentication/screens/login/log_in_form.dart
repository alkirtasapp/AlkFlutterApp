import 'package:alkirtas/features/authentication/screens/login/forgot_password_webview.dart';
import 'package:alkirtas/features/authentication/screens/signUp/sign_up.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:iconsax/iconsax.dart';

class AlkLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final void Function(BuildContext) onSignIn;
    final RxBool isObscured = true.obs;

   AlkLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AlkSize.spaceBtwSections),
        child: Column(
          children: [
            // Email Input
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                label: Text('Email'),
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwInputFields),
            // Password Input with Visibility Toggle
            Obx(() => TextFormField(
                  controller: passwordController,
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ForgotPasswordWebView()),
                  ),
                  child: const Text('Mot de passe oublié?'),
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
                onPressed: () => onSignIn(context),
                child: const Text('Connexion',style: TextStyle(color: Colors.white),),
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