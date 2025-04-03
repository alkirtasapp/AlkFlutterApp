import 'dart:convert';
import 'package:alkirtas/features/authentication/screens/login/log_in_divider.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_footer.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_form.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_header.dart';
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
      showErrorDialog(context, 'Veuillez remplir les deux champs.');
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
              //AlkLoginDivider(dark: dark), *will be used once FireBase is implemented*
              const SizedBox(height: AlkSize.spaceBtwSections),

              /// Footer with social login buttons
              //AlkLoginFooter()   *will be used once FireBase is implemented*
            ],
          ),
        ),
      ),
    );
  }
}






