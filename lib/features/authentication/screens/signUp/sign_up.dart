import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/features/authentication/controllers/sign_up_controller.dart';
import 'package:test/utils/constants/size.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpController _controller = SignUpController();
  bool _isChecked = false; // Terms of Use checkbox state

  void _handleSignUp() async {
    setState(() => _controller.isLoading = true);

    String? errorMessage = await _controller.registerUser();

    setState(() => _controller.isLoading = false);

    if (errorMessage == null) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(errorMessage);
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
          child: Form(
            key: _controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créons votre compte...', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AlkSize.spaceBtwSections),

                /// Nom et Prénom
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controller.lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom', prefixIcon: Icon(Iconsax.user),
                        ),
                        validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                      ),
                    ),
                    SizedBox(width: AlkSize.spaceBtwInputFields),
                    Expanded(
                      child: TextFormField(
                        controller: _controller.firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom', prefixIcon: Icon(Iconsax.user),
                        ),
                        validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                /// Phone Number
                TextFormField(
                  controller: _controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone', prefixIcon: Icon(Iconsax.call),
                  ),
                  validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                /// Email
                TextFormField(
                  controller: _controller.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Iconsax.direct),
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
                  controller: _controller.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe ', prefixIcon: Icon(Iconsax.password_check),
                    suffixIcon: Icon(Iconsax.eye_slash),
                  ),
                  validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                /// Confirm Password
                TextFormField(
                  controller: _controller.confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Saisissez à nouveau votre mot de passe', prefixIcon: Icon(Iconsax.password_check),
                    suffixIcon: Icon(Iconsax.eye_slash),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Champ obligatoire";
                    if (value != _controller.passwordController.text) return "Les mots de passe ne correspondent pas";
                    return null;
                  },
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                /// Terms of Use Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? newValue) {
                        setState(() => _isChecked = newValue!);
                      },
                    ),
                    const Expanded(
                      child: Text("J'accepte les termes et conditions."),
                    ),
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                /// Button (Disabled if terms are not accepted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_controller.isLoading || !_isChecked) ? null : _handleSignUp,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (!_isChecked) return Colors.grey; // Gray when disabled
                          return Theme.of(context).primaryColor; // Default color
                        },
                      ),
                    ),
                    child: _controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Créer un compte"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
