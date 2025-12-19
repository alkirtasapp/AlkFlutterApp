import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:alkirtas/config/app_config.dart';

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
  String selectedTitle = "M."; // Default gender selection

  // Getter for gender ID
  int get idGender => selectedTitle == "M." ? 1 : 2;

  // Method to update gender selection
  void updateTitle(String value) {
    selectedTitle = value;
    log("Updated gender: $selectedTitle, id_gender: $idGender");
  }

  // Function to check if the email is unique
  Future<bool> isEmailUnique(String email) async {
    final String apiUrl =
        "https://www.alkirtas.com/api/customers?display=full&filter[email]=$email&ws_key=${AppConfig.prestashopApiKey}&output_format=JSON";

    try {
      log("Checking if email exists: $email");

      final response = await http.get(Uri.parse(apiUrl));

      log("Email Check Response Status: ${response.statusCode}");
      log("Email Check Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic>) {
            // Handle response like {"customers": []}
          if (decodedData.containsKey("customers") &&
              decodedData["customers"] is List) {
            return decodedData["customers"].isEmpty;
          } else {
            log("Email Check: Unexpected response format");
             return false ; 
          }
        } else if (decodedData is List) {
            // Handle response like [] (empty list directly)
          return decodedData.isEmpty;
        } else {
          log("Email Check: Unexpected response type");
          return false ;
        }
      } else {
        log("Email Check: Non-200 response");
        return false;
      }
    } catch (e) {
      log("Email Check Error: $e");
      return false;
    }
  }

  // Function to create XML request for PrestaShop API
  String generateXmlData() {
    final int genderId = idGender;
    const int idLang = 1;

    final xmlData = '''
    <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <customer>
            <id_gender><![CDATA[$genderId]]></id_gender>
            <id_lang><![CDATA[$idLang]]></id_lang>
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

    log("Generated XML Data: \n$xmlData");
    log("Final Gender Sent: id_gender = $genderId");

    return xmlData;
  }

  // Function to send API request
  Future<bool> registerUser() async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;

    final String email = emailController.text;

    // Check if email is already in use before proceeding
    bool isUnique = await isEmailUnique(email);
    if (!isUnique) {
      isLoading = false;
      _showErrorDialog(
          "L'adresse e-mail est déjà utilisée. Veuillez en choisir une autre.");
      return false;
    }

    final String apiUrl =
        "https://www.alkirtas.com/api/customers?ws_key=${AppConfig.prestashopApiKey}";
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

      log("Signup Request Response Status Code: ${response.statusCode}");
      log("Signup Request Response Body: ${response.body}");

      // Log the entire response headers for debugging
      log("Response Headers: ${response.headers}");

      if (response.statusCode == 201) {
        log("Signup successful: Customer created");
        _showSuccessDialog();
        return true; // Success
      } else {
        log("Signup failed: Non-201 status code");

        // Handle potential XML errors from PrestaShop
        try {
          final document = XmlDocument.parse(response.body);
          final errors = document.findAllElements('errors');

          if (errors.isNotEmpty) {
            final errorMessages = errors.first
                .findAllElements('message')
                .map((e) => e.text)
                .join('\n');
            log("PrestaShop Error Messages: $errorMessages");
            _showErrorDialog("Erreur de PrestaShop:\n$errorMessages");
          } else {
            log("No specific error messages in XML");
            _showErrorDialog("Erreur: ${response.statusCode}\n${response.body}");
          }
        } catch (e) {
          log("Signup: XML Parsing Error: $e");
          log(
              "Signup: Response body (in case of parsing error): ${response.body}");
          _showErrorDialog(
              "Erreur de l'API: ${response.statusCode}\n${response.body}");
        }
        return false;
      }
    } catch (e) {
      log("Signup Request Error: $e");
      _showErrorDialog("Une erreur s'est produite: $e");
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Success message
  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Succès"),
        content: const Text("Compte créé avec succès !"),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // Use Get.back to close the dialog
            child: const Text("OK"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Error message
  void _showErrorDialog(String message) {
    Get.dialog(
        AlertDialog(
          title: const Text("Erreur"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // Use Get.back to close the dialog
              child: const Text("OK"),
            ),
          ],
        ),
        barrierDismissible: false);
  }
}
