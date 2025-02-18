import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/features/authentication/screens/signUp/sign_up.dart';
import 'package:test/navigation_menu.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/images_strings.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/utils/helpers/helper_functions.dart';
import 'package:http/http.dart' as http;

import '../../../../utils/backendData/userData.dart';



class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

void signInUser(BuildContext context) async {
  final email = emailController.text;
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    showErrorDialog(context, 'Please fill in both fields.');
    return;
  }

  final response = await http.get(
    Uri.parse(
      'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU',
    ),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    if (data['customers'] != null && data['customers'].isNotEmpty) {
      var customer = data['customers'][0];

      if (customer['email'] == email) {
        bool passwordMatch = BCrypt.checkpw(password, customer['passwd']);
        if (passwordMatch) {
         
          UserData.email = customer['email'];
          UserData.firstname = customer['firstname'];
          UserData.lastname = customer['lastname'];
          UserData.id = customer['id'].toString();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigationMenu()),
          );
          return;
        } else {
          showErrorDialog(context, 'Invalid password.');
          return;
        }
      }
    } else {
      showErrorDialog(context, 'No user found with this email.');
    }
  } else {
    showErrorDialog(context, 'Connection error.');
  }
}

  // Show error dialog
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AlkHelperFunctions.isDarkMode(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: AlkSize.appBarHeight,
            left: AlkSize.defaultSpace,
            bottom: AlkSize.defaultSpace,
            right: AlkSize.defaultSpace,
          ),
          child: Column(
            children: [
              /// Logo title and subtitle
              AlkLoginHeader(dark: dark),

              /// Form with email/password input and login logic
              AlkLoginForm(
                emailController: emailController,
                passwordController: passwordController,
                onSignIn: (context) => signInUser(context),
              ),

              /// Divider
              AlkLoginDivider(dark: dark),
              const SizedBox(height: AlkSize.spaceBtwSections),

              /// Footer with social login buttons
              AlkLoginFooter()
            ],
          ),
        ),
      ),
    );
  }
}

class AlkLoginFooter extends StatelessWidget {
  const AlkLoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AlkColors.grey),
            borderRadius: BorderRadius.circular(100),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: AlkSize.iconMd,
              height: AlkSize.iconMd,
              image: AssetImage(AlkImages.google),
            ),
          ),
        ),
        const SizedBox(width: AlkSize.spaceBtwItems),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AlkColors.grey),
            borderRadius: BorderRadius.circular(100),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: AlkSize.iconMd,
              height: AlkSize.iconMd,
              image: AssetImage(AlkImages.facebook),
            ),
          ),
        ),
      ],
    );
  }
}

class AlkLoginDivider extends StatelessWidget {
  const AlkLoginDivider({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Divider(
            color: dark ? AlkColors.darkGrey : AlkColors.grey,
            thickness: 0.5,
            indent: 60,
            endIndent: 5,
          ),
        ),
        Text(
          'ou continuez avec',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Flexible(
          child: Divider(
            color: dark ? AlkColors.darkGrey : AlkColors.grey,
            thickness: 0.5,
            indent: 5,
            endIndent: 60,
          ),
        ),
      ],
    );
  }
}

class AlkLoginForm extends StatelessWidget {
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
            // Password Input
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.password_check),
                labelText: 'Mot de passe',
                suffixIcon: Icon(Iconsax.eye_slash),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AlkSize.spaceBtwInputFields / 2),
            // Remember Me and Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                
               /* Row(
                  children: [
                    Checkbox(value: true, onChanged: (value) {}),
                    const Text('Remember me'),
                  ],
                ),*/
                TextButton(
                  onPressed: () {},
                  child: const Text('Mot de passe oublié?'),
                ),
              ],
            ),
            const SizedBox(height: AlkSize.spaceBtwSections),
            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onSignIn(context),
                child: const Text('Connexion'),
              ),
            ),
            const SizedBox(height: AlkSize.spaceBtwItems),
            // Create Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(()=> const SignUpScreen()),
                child: const Text('Créer un compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlkLoginHeader extends StatelessWidget {
  const AlkLoginHeader({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(
          height: 150,
          image: AssetImage(
              dark ? AlkImages.darkAppLogo : AlkImages.lighAppLogo),
        ),
        /*Text(
          'Bienvenue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),*/
        const SizedBox(height: AlkSize.lg),
        Text(
          'Connectez-vous à Votre Compte',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
