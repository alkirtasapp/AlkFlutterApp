import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  const LoginForm(
      {super.key,
      this.controller,
      required this.hintText,
      required this.icon,
      required this.obscureText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(50),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(50),
          ),
          fillColor: Colors.grey[200],
          filled: true,
          hintText: hintText,
          prefixIcon: Icon(icon),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
