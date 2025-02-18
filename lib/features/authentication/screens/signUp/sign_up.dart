import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'dart:developer';

import 'package:test/utils/constants/size.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for user input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Added phone number
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Function to create XML request for PrestaShop API
  String _generateXmlData() {
    final xmlData = '''
    <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <customer>
            <passwd><![CDATA[${_passwordController.text}]]></passwd>
            <lastname><![CDATA[${_lastNameController.text}]]></lastname>
            <firstname><![CDATA[${_firstNameController.text}]]></firstname>
            <email><![CDATA[${_emailController.text}]]></email>
            <phone><![CDATA[${_phoneController.text}]]></phone> <!-- Added phone number -->
            <id_default_group><![CDATA[3]]></id_default_group>
            <active>1</active>
        </customer>
    </prestashop>
    ''';

    log("Generated XML Data: \n$xmlData");
    return xmlData;
  }

  // Function to send API request
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String apiUrl = "https://www.alkirtas.com/api/customers?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
    final String xmlData = _generateXmlData();

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
        _showSuccessDialog();
      } else {
        _showErrorDialog("Erreur: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      log("Signup Error: $e");
      _showErrorDialog("Une erreur s'est produite: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Success message
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Succès"),
        content: const Text("Compte créé avec succès !"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Error message
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlkAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AlkSize.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text('Créons votre compte...', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AlkSize.spaceBtwSections),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        /// Nom et Prénom
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            expands: false,
                            decoration: const InputDecoration(
                              labelText: 'Nom', labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.user),
                            ),
                            validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                          ),
                        ),
                        SizedBox(width: AlkSize.spaceBtwInputFields),
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            expands: false,
                            decoration: const InputDecoration(
                              labelText: 'Prénom', labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.user),
                            ),
                            validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),

                    /// Phone Number
                    TextFormField(
                      controller: _phoneController,
                      expands: false,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone', labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Iconsax.call),
                      ),
                      validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),

                    /// Email
                    TextFormField(
                      controller: _emailController,
                      expands: false,
                      decoration: const InputDecoration(
                        labelText: 'Email', labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Iconsax.direct),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return "Champ obligatoire";
                        if (!RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(value)) {
                          return "Email invalide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),

                    /// Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe ', labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Iconsax.password_check),
                        suffix: Icon(Iconsax.eye_slash),
                      ),
                      validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),

                    /// Password check
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                        labelText: 'Saisissez à nouveau votre mot de passe', labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Iconsax.password_check),
                        suffix: Icon(Iconsax.eye_slash),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return "Champ obligatoire";
                        if (value != _passwordController.text) return "Les mots de passe ne correspondent pas";
                        return null;
                      },
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),

                    /// Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Créer un compte"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
