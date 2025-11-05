import 'dart:convert';
import 'dart:ui';
import 'package:alkirtas/features/authentication/screens/login/log_in_divider.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_footer.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_form.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_header.dart';
import 'package:bcrypt/bcrypt.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
       // Create the request with CORS-friendly headers for web platform
       final request = http.Request(
         'GET',
         Uri.parse(
           'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU',
         ),
       );

       // Add headers to handle CORS issues on web platform
       request.headers.addAll({
         'Content-Type': 'application/json',
         'Accept': 'application/json',
         'User-Agent': 'Flutter-Web-App/1.0',
         // Add Origin header for web platform
         if (kIsWeb)
           'Origin': 'https://www.alkirtas.com', // Match the API domain
       });

       final streamedResponse = await request.send();
       final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['customers'] != null &&
            data['customers'] is List &&
            data['customers'].isNotEmpty) {
          final customer = data['customers'][0];

          if (customer['email'] == email) {
            final bool passwordMatch =
                BCrypt.checkpw(password, customer['passwd']);
            if (passwordMatch) {
              // Convert the ID to string when storing
              UserData.email = customer['email'].toString();
              UserData.firstname = customer['firstname'].toString();
              UserData.lastname = customer['lastname'].toString();
              UserData.id = customer['id'].toString();

              // Pass the ID as integer to Firebase
     //         await registerAppUser(customer['id'] as int);

              Get.offAll(() => const NavigationMenu());
              final prefs = await SharedPreferences.getInstance();
              final pending = prefs.getString('pendingNavigation');
              if (pending != null) {
                prefs.remove('pendingNavigation');
                print('Redirecting after login to: $pending');

                // Small delay to make sure NavigationMenu is fully built
                Future.delayed(Duration(milliseconds: 100), () {
                  if (pending == 'Promos') {
                    Get.offAll(() => const NavigationMenu(selectedMenu: 1));
                  }

                  // Add more cases if needed
                });
              }

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

       // Provide more specific error messages based on the error type
       String errorMessage = 'Une erreur est survenue. Veuillez réessayer.';

       if (e.toString().contains('XMLHttpRequest')) {
         errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet ou essayez sur l\'application mobile.';
       } else if (e.toString().contains('CORS')) {
         errorMessage = 'Erreur CORS. Cette fonctionnalité nécessite l\'application mobile ou un serveur configuré.';
       } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed to connect')) {
         errorMessage = 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
       }

       showErrorDialog(context, errorMessage);
     }
  }

//  Future<void> registerAppUser(int prestashopId) async {
//    final usersRef = FirebaseFirestore.instance.collection('app_users');
//
//    final existingUser =
//        await usersRef.where('prestashop_id', isEqualTo: prestashopId).get();
//
//    if (existingUser.docs.isEmpty) {
//      await usersRef.add({
//        'prestashop_id': prestashopId,
//        'timestamp': FieldValue.serverTimestamp(),
//      });
//    }
 // }

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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade50.withOpacity(0.3),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
            child: SingleChildScrollView(
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
          ),
          if (isLoading)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isLoading ? 1.0 : 0.0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Connexion en cours...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Veuillez patienter',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
