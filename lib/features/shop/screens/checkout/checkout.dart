import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/signIn/AlkTOU.dart';
import 'package:alkirtas/data/controllers/addresses_controller.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';

class CheckoutScreen extends StatefulWidget {
  CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>(); // Form Key for validation

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final adressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  final gouverneratController = TextEditingController();

  bool isTermsAccepted = false; // Checkbox state

  // Validator for required fields
  String? _validateField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  //  phone number (must be exactly 8 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Le numéro de téléphone doit contenir 8 chiffres';
    }
    return null;
  }

    //  phone number (must be exactly 8 digits)
  String? _validatePostCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Le code postale doit contenir 4 chiffres';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AlkSize.defaultSpace),
          child: Form(
            key: _formKey, // Assign the form key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    SizedBox(width: AlkSize.spaceBtwInputFields),
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
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.mobile),
                  ),
                  validator: _validatePhoneNumber, // Apply phone number validation
                ),

                const SizedBox(height: AlkSize.spaceBtwInputFields),
                TextFormField(
                  controller: adressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse ',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.house),
                  ),
                  validator: _validateField,
                ),

                const SizedBox(height: AlkSize.spaceBtwInputFields),
                TextFormField(
                  controller: postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code postale',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.direct),
                  ),
                  validator: _validatePostCode,
                ),

                const SizedBox(height: AlkSize.spaceBtwInputFields),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville ',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.building),
                  ),
                  validator: _validateField,
                ),

                const SizedBox(height: AlkSize.spaceBtwInputFields),
                TextFormField(
                  controller: gouverneratController,
                  decoration: const InputDecoration(
                    labelText: 'Gouvernorat',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Iconsax.map_1),
                  ),
                  validator: _validateField,
                ),

                const SizedBox(height: AlkSize.spaceBtwInputFields),
                // CheckBox field to chose delivery Method
                const SizedBox(height: AlkSize.spaceBtwInputFields),
                /// mode de livraison
                Text(" Mode de livraison ", style: Theme.of(context).textTheme.titleMedium),
                Column(
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: "Alkirtas corniche",
                          //groupValue: _controller.selectedTitle
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                             // _controller.updateTitle(value!);
                            });
                          },
                        ),
                        const Text("Alkirtas corniche"),
                      ],
                    ),
                    
                    const SizedBox(height: AlkSize.xs),
                    Row(
                      children: [
                        Radio<String>(
                          value: "First Delivery",
                          //groupValue: _controller.selectedTitle,
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              //_controller.updateTitle(value!);
                            });
                          },
                        ),
                           const Text(" First Delivery"),
                      ],
                    ),
                 
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),


                /// Terms & Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          isTermsAccepted = value!;
                        });
                      },
                    ),
                    AlkTOUCHeckbox()
                  ],
                ),
                const SizedBox(height: AlkSize.spaceBtwInputFields),

                
                /// Confirm Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        isTermsAccepted ? Colors.purpleAccent[700] : Colors.grey, // Button color changes
                      ),
                    ),
                    onPressed: isTermsAccepted
                        ? () async {
                            if (_formKey.currentState!.validate()) { // Validate the form
                              print(" Checkout button clicked !");

                              // Store user input into AddressData
                              AddressData.id_customer = UserData.id;
                              AddressData.lastname = lastNameController.text;
                              AddressData.firstname = firstNameController.text;
                              AddressData.address1 = adressController.text;
                              AddressData.postcode = postalCodeController.text;
                              AddressData.city = cityController.text;
                              AddressData.phone = phoneController.text;
                              AddressData.id_country = "208"; // Tunisia

                              // Ensure the AddressController is initialized
                              final AddressController addressController =
                                  Get.put(AddressController(), permanent: true);

                              

                              // Fetch or create an address before proceeding with the order
                              await addressController.fetchCustomerAddress();

                              // Ensure the address is set before proceeding
                              if (AddressData.id.isNotEmpty) {
                                print("✅ Address confirmed: ${AddressData.id}");
                                print(" Proceeding to order...");
                              } else {
                                print("❌ Address creation failed! Cannot proceed.");
                              }
                            }
                          }
                        : null, // Disable the button if checkbox is not checked
                    child: const Text('Confirmer la commande'),
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
