import 'dart:convert';
import 'package:alkirtas/features/authentication/screens/login/log_in_divider.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_footer.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_form.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_header.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void signInUser(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog(context, 'Veuillez remplir les deux champs.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU',
        ),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['customers'] != null && data['customers'] is List && data['customers'].isNotEmpty) {
          final customer = data['customers'][0];

          if (customer['email'] == email) {
            final bool passwordMatch = BCrypt.checkpw(password, customer['passwd']);
            if (passwordMatch) {
              // Convert the ID to string when storing
              UserData.email = customer['email'].toString();
              UserData.firstname = customer['firstname'].toString();
              UserData.lastname = customer['lastname'].toString();
              UserData.id = customer['id'].toString();

              // Pass the ID as integer to Firebase
              await registerAppUser(customer['id'] as int);

              Get.offAll(() => const NavigationMenu());
              return;
            } else {
              showErrorDialog(context, 'Mot de passe invalide');
              return;
            }
          }
        }

        showErrorDialog(context, 'Aucun utilisateur trouvé avec cet e-mail.');
      } else {
        showErrorDialog(context, 'Erreur de connexion.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Login error: $e');
      showErrorDialog(context, 'Une erreur est survenue. Veuillez réessayer.');
    }
  }

  Future<void> registerAppUser(int prestashopId) async {
    final usersRef = FirebaseFirestore.instance.collection('app_users');

    final existingUser = await usersRef.where('prestashop_id', isEqualTo: prestashopId).get();

    if (existingUser.docs.isEmpty) {
      await usersRef.add({
        'prestashop_id': prestashopId,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
          if (isLoading)
            Container(
              color: Colors.purple.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}






