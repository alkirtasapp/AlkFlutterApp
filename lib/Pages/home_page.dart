import 'package:flutter/material.dart';
import 'auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // signUserOut Method (manual sign-out)
  void signUserOut(BuildContext context) {
    // Clear user data (e.g., SharedPreferences, local storage, etc.)
    // You can implement the data clearing if you're using any persistence method.
    // For now, we'll simply navigate back to the login page.

    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => LoginPage()), // Redirect to LoginPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () =>
                  signUserOut(context), // Pass context to signUserOut
              icon: Icon(Icons.logout),
            )
          ],
        ),
        body: Center(child: Text('Welcome to the Home Page !')));
  }
}
