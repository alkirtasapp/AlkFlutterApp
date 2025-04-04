import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/data/controllers/addresses_controller.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final AddressController addressController = Get.put(AddressController());
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController(text: AddressData.firstname);
  final lastNameController = TextEditingController(text: AddressData.lastname);
  final phoneController = TextEditingController(text: AddressData.phone);
  final addressFieldController = TextEditingController(text: AddressData.address1); // Renamed
  final postalCodeController = TextEditingController(text: AddressData.postcode);
  final cityController = TextEditingController(text: AddressData.city);
  final gouvernoratController = TextEditingController(text: AddressData.address2);

  @override
  void initState() {
    super.initState();
    // Fetch the existing address when the screen is initialized
    addressController.fetchCustomerAddress().then((_) {
      setState(() {
        firstNameController.text = AddressData.firstname;
        lastNameController.text = AddressData.lastname;
        phoneController.text = AddressData.phone;
        addressFieldController.text = AddressData.address1; // Updated
        postalCodeController.text = AddressData.postcode;
        cityController.text = AddressData.city;
        gouvernoratController.text = AddressData.address2;
      });
    });
  }

  // Validator for required fields
  String? _validateField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  // Validator for phone number (must be exactly 8 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Le numéro de téléphone doit contenir 8 chiffres';
    }
    return null;
  }

  // Validator for postal code (must be exactly 4 digits)
  String? _validatePostCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Le code postal doit contenir 4 chiffres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Adresses'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AlkSize.defaultSpace),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Iconsax.user),
                        ),
                        validator: _validateField,
                      ),
                    ),
                    const SizedBox(width: AlkSize.spaceBtwInputFields),
                    Expanded(
                      child: TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Iconsax.user),
                        ),
                        validator: _validateField,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // Phone Number
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.mobile),
                  ),
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // Address
                TextFormField(
                  controller: addressFieldController, // Updated
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.house),
                  ),
                  validator: _validateField,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // Postal Code
                TextFormField(
                  controller: postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code postal',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.direct),
                  ),
                  validator: _validatePostCode,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // City
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.building),
                  ),
                  validator: _validateField,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // Gouvernorat
                TextFormField(
                  controller: gouvernoratController,
                  decoration: const InputDecoration(
                    labelText: 'Gouvernorat',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.map_1),
                  ),
                  validator: _validateField,
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Save the address data
                        AddressData.firstname = firstNameController.text;
                        AddressData.lastname = lastNameController.text;
                        AddressData.phone = phoneController.text;
                        AddressData.address1 = addressFieldController.text; // Updated
                        AddressData.postcode = postalCodeController.text;
                        AddressData.city = cityController.text;
                        AddressData.id_state = gouvernoratController.text;

                        Get.snackbar(
                          'Succès',
                          'Votre adresse a été mise à jour avec succès !',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AlkColors.primaryColor,
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Iconsax.save_2, color: Colors.white),
                    label: const Text(
                      'Enregistrer',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AlkColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AlkSize.defaultSpace / 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AlkSize.defaultSpace),
                      ),
                    ),
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