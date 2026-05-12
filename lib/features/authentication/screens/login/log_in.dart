import 'dart:convert';
import 'dart:ui';
import 'package:alkirtas/features/authentication/screens/login/log_in_divider.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_footer.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_form.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in_header.dart';
import 'package:alkirtas/features/authentication/screens/home/home.dart';
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
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

import '../../../../utils/backendData/userData.dart';
import '../../../../providers/odoo_account_provider.dart';
import '../../services/google_sign_in_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void signInUser() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
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
           'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}',
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

      if (!mounted) return;
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
              UserData.password = password;
              OdooAccountProvider.savePassword(password);

              // Restore phone from SharedPreferences (saved at signup, keyed by email)
              final phonePrefs = await SharedPreferences.getInstance();
              UserData.phone =
                  phonePrefs.getString('customer_phone_${email.toLowerCase()}') ?? '';

              // Pass the ID as integer to Firebase
     //         await registerAppUser(customer['id'] as int);

              // Add a small delay to let the loading animation complete smoothly
              await Future.delayed(const Duration(milliseconds: 500));

              final prefs = await SharedPreferences.getInstance();
              final pending = prefs.getString('pendingNavigation');

              if (pending != null) {
                prefs.remove('pendingNavigation');

                if (pending == 'Promos') {
                  Get.offAll(
                    () => const NavigationMenu(selectedMenu: 2), // Boutique page
                    transition: Transition.fadeIn,
                    duration: const Duration(milliseconds: 400),
                  );
                } else {
                  // Navigate to NavigationMenu with Home screen (page 0)
                  Get.offAll(
                    () => const NavigationMenu(selectedMenu: 0),
                    transition: Transition.fadeIn,
                    duration: const Duration(milliseconds: 400),
                  );
                }
              } else {
                // Navigate to NavigationMenu with Home screen (page 0)
                Get.offAll(
                  () => const NavigationMenu(selectedMenu: 0),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 400),
                );
              }

              return;
            } else {
              if (!mounted) return;
              showErrorDialog(context, 'Mot de passe invalide');
              return;
            }
          }
        }

        if (!mounted) return;
        showErrorDialog(context, 'Aucun utilisateur trouvé avec cet e-mail.');
      } else {
        if (!mounted) return;
        showErrorDialog(context, 'Erreur de connexion.');
      }
    } catch (e) {
       if (!mounted) return;
       setState(() {
         isLoading = false;
       });
       AlkLoggerHelper.error("Login failed", e);

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

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final error = await GoogleSignInService.signIn();

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      // Only show error if it wasn't a user cancellation
      if (!error.contains('cancelled')) {
        showErrorDialog(context, error);
      }
      return;
    }

    // Success — navigate like classic login
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString('pendingNavigation');
    if (pending != null) {
      prefs.remove('pendingNavigation');
      Get.offAll(
        () => NavigationMenu(selectedMenu: pending == 'Promos' ? 2 : 0),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 400),
      );
    } else {
      Get.offAll(
        () => const NavigationMenu(selectedMenu: 0),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 400),
      );
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AlkColors.AppSecColor.withOpacity(0.3),
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

                    /// Form with email/password input and login logic.
                    /// The Google button is rendered inside the form, right above the Connexion button.
                    AlkLoginForm(
                      emailController: emailController,
                      passwordController: passwordController,
                      onSignIn: (_) => signInUser(),
                      googleButton: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLoading ? null : _signInWithGoogle,
                              borderRadius: BorderRadius.circular(12),
                              splashColor:
                                  AlkColors.AppSecColor.withOpacity(0.08),
                              highlightColor:
                                  AlkColors.AppSecColor.withOpacity(0.04),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 22,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'lib/assets/icons/icons8-google-48.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Iconsax.global, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continuer avec Google',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F1F1F),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Divider
                    //AlkLoginDivider(dark: dark), *will be used once FireBase is implemented*
                    const SizedBox(height: AlkSize.spaceBtwSections),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Get.offAll(
                          () => const NavigationMenu(selectedMenu: 0),
                          transition: Transition.fadeIn,
                          duration: const Duration(milliseconds: 400),
                        ),
                        child: Text(
                          'Continuer sans compte',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                            color: AlkColors.AppSecColor,
                          ),
                        ),
                      ),
                    ),
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
                                AlkColors.AppFirstColor
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Connexion en cours...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AlkColors.AppSecColor
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
