import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/features/authentication/screens/signUp/sign_up.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';
import 'package:http/http.dart' as http;

import '../../../../utils/backendData/userData.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  // handle user inputs 
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
   
  void signInUser(BuildContext context) async {
    final email = emailController.text;
    final password = passwordController.text;

    // Check if the email and password fields are empty
    if (email.isEmpty || password.isEmpty) {
      showErrorDialog(context, 'Please fill in both fields.');
      return;
    }

    // Make the API call
    final response = await http.get(
      Uri.parse(
        'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU',
      ),
    );

    // Check if the response status code is 200
    if (response.statusCode == 200) {
      try {
        var data = json.decode(response.body);

        // Ensure 'customers' exists and is a list
        if (data['customers'] != null && data['customers'] is List && data['customers'].isNotEmpty) {
          var customer = data['customers'][0];

          // Check if the email matches
          if (customer['email'] == email) {
            bool passwordMatch = BCrypt.checkpw(password, customer['passwd']);
            if (passwordMatch) {
              UserData.email = customer['email'];
              UserData.firstname = customer['firstname'];
              UserData.lastname = customer['lastname'];
              UserData.id = customer['id'].toString();

              // Navigate to NavigationMenu and clear the navigation stack
              Get.offAll(() => NavigationMenu());
              return;
            } else {
              showErrorDialog(context, 'Mot de passe invalide');
              return;
            }
          }
        }

        // If no customers found or invalid structure
        showErrorDialog(context, 'Aucun utilisateur trouvé avec cet e-mail.');
      } catch (e) {
        // Handle JSON decoding or other unexpected errors
        showErrorDialog(context, 'Aucun utilisateur trouvé avec cet e-mail.');
        print('Error decoding response: $e');
      }
    } else {
      // Handle non-200 response
      showErrorDialog(context, 'Erreur de connexion.');
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
        const SizedBox(height: AlkSize.lg),
        Text(
          'Connectez-vous à Votre Compte',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
 /// 1.  Import the required packages
 /// 2.  Create a function to sign in the user
 /// 3.  Check if the email and password fields are empty 
 /// 4.  Check if the email is valid
 /// 5.  Check if the response status code is 200
 /// 6.  Decode the response body
 /// 7.  Ensure 'customers' exists and is a list
 /// 8.  Check if the data is not empty
 /// 9.  Check if the password is valid
 /// 10.  Set the user data
 /// 11.  Handle JSON decoding or other unexpected errors
 /// 12.  Show an error dialog
 /// 13.  Build the login screen
 /// 14.  Stores the Customers data in UserData class
 /// 15.  Redirects to SignUpScreen upon Pressing the Create Account Button
 /// 16.  Redirects to NavigationMenu upon successful login

