import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignUpController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers for user input
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // Function to check if the email is already used
  Future<bool> isEmailUnique(String email) async {
    final String apiUrl =
        "https://www.alkirtas.com/api/customers?display=full&filter[email]=$email&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU&output_format=JSON";

    try {
      log("Checking if email exists: $email");

      final response = await http.get(Uri.parse(apiUrl));

      log("Email Check Response Status: ${response.statusCode}");
      log("Email Check Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["customers"] == null || data["customers"].isEmpty;
      }
    } catch (e) {
      log("Email Check Error: $e");
    }
    return false;
  }

  // Function to create XML request for PrestaShop API
  String generateXmlData() {
    return '''
    <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <customer>
            <passwd><![CDATA[${passwordController.text}]]></passwd>
            <lastname><![CDATA[${lastNameController.text}]]></lastname>
            <firstname><![CDATA[${firstNameController.text}]]></firstname>
            <email><![CDATA[${emailController.text}]]></email>
            <phone><![CDATA[${phoneController.text}]]></phone>
            <id_default_group><![CDATA[3]]></id_default_group>
            <active>1</active>
        </customer>
    </prestashop>
    ''';
  }

  // Function to send API request
  Future<String?> registerUser() async {
    if (!formKey.currentState!.validate()) return null;

    isLoading = true;

    final String email = emailController.text;

    // Check if email is already in use before proceeding
    bool isUnique = await isEmailUnique(email);
    if (!isUnique) {
      return "L'adresse e-mail est déjà utilisée. Veuillez en choisir une autre.";
    }

    final String apiUrl =
        "https://www.alkirtas.com/api/customers?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
    final String xmlData = generateXmlData();

    try {
      log("Sending signup request to: $apiUrl");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/xml",
          "Accept": "application/xml",
        },
        body: xmlData,
      );

      log("Response Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return null; // Success
      } else {
        return "Erreur: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      log("Signup Error: $e");
      return "Une erreur s'est produite: $e";
    } finally {
      isLoading = false;
    }
  }
}
