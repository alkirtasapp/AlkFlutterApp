/*import 'dart:convert';
import 'package:alkirtas/Components/login_form.dart';
import 'package:alkirtas/Components/sign_button.dart';
import 'package:alkirtas/Components/square_tile.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign in user
  void signInUser(BuildContext context) async {
    final email = emailController.text;
    final password = passwordController.text;

    // Validate the input fields
    if (email.isEmpty || password.isEmpty) {
      showErrorDialog(context, 'Please fill in both fields.');
     // print("Login failed: Email or password field is empty.");
      return;
    }

    //print("Attempting to sign in with email: $email");

    final response = await http.get(
      Uri.parse(
        'https://www.alkirtas.com/api/customers?filter[email]=$email&display=[id,firstname,lastname,email,passwd]&output_format=JSON&ws_key=PIVRXTPACCDPK4ST8MN59V7LLTYT357K',
      ),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      // Check if the 'customers' key exists and is not empty
      if (data['customers'] != null && data['customers'].isNotEmpty) {
        var customer = data['customers']
            [0]; // Since we are filtering by email, we expect only one customer

        //print("Customer found: ID = $customerId, Email = ${customer['email']}");

        // Check if the email matches
        if (customer['email'] == email) {
          // Check if the password matches
          bool passwordMatch = BCrypt.checkpw(password, customer['passwd']);

          if (passwordMatch) {
            // Successful login
            //print("Login successful for customer ID: $customerId");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            return; // Exit the method after successful login
          } else {
            showErrorDialog(context, 'Mot de passe invalide.');
            //print("Invalid password attempt for email: $email");
            return;
          }
        }
      } else {
        showErrorDialog(context, 'Auccun utilisateur trouvé avec cet email.');
       // print("No user found with email: $email");
      }
    } else {
      // API request failed
      showErrorDialog(context, 'Erreur lors de la connexion.');
      //print("API request failed with status code: ${response.statusCode}");
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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(Icons.account_circle, size: 150, color: Colors.grey),
              SizedBox(height: 10),

              // message
              Text(
                'Connectez-vous à votre compte',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              SizedBox(height: 25),

              // email input
              LoginForm(
                  controller: emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                  obscureText: false),

              SizedBox(height: 15),

              // password input
              LoginForm(
                  controller: passwordController,
                  hintText: 'Mot de Passe',
                  icon: Icons.lock,
                  obscureText: true),
              SizedBox(height: 10),

              // forgot password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Mot de passe oublié ?',
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // login button
              SignButton(
                onTap: () => signInUser(context), // Pass context here
              ),
              const SizedBox(height: 20),

              // or continue with
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '  ou continuez avec  ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // login with google button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //google
                  SquareTile(imagePath: 'lib/assets/google.png'),
                  const SizedBox(width: 25),
                  //facebook
                  SquareTile(imagePath: 'lib/assets/facebook.png'),
                ],
              ),
              SizedBox(height: 30),

              // no account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Vous n\'avez pas de compte ?',
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(width: 5), // add space between text
                  Text(' Inscrivez-vous',
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
*/