import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/signIn/AlkTOU.dart';
import 'package:test/data/controllers/addresses_controller.dart';
import 'package:test/utils/backendData/addressData.dart';
import 'package:test/utils/backendData/userData.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';

class CheckoutScreen extends StatelessWidget {
 CheckoutScreen({super.key});
   // handle user inputs 
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();  
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  final gouverneratController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confiramtion'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AlkSize.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form
              Form(
                child: Column(
                  children: [
                    Row(
                      children: [
                        /// Nom et Prénom
                        Expanded(
                          child: TextFormField(
                            controller:  lastNameController,
                                                 
                            expands: false,
                            decoration: InputDecoration(
                              labelText: 'Nom',
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Iconsax.user) ,
                            ),
                          ),
                        ),




                        SizedBox(width: AlkSize.spaceBtwInputFields),
                           Expanded(
                          child: TextFormField(
                            controller:  firstNameController,
                            expands: false,
                            decoration: InputDecoration(
                            
                              labelText: 'Prénom',
                              
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Iconsax.user) ,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                      /// Phone 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                       TextFormField(
                        controller: phoneController,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Téléphone',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.mobile) 
                            ),
                    ),



                    /// Phone 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                       TextFormField(
                        controller: addressController,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Adresse ',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.house) 
                            ),
                    ),



                    
                    /// Email
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      controller: postalCodeController,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Code postale',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.direct) 
                            ),
                    ),




                    /// Password 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      controller: cityController,
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Ville ',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.building) ,
                              
                            ),
                    ),



                     /// Password check
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      controller: gouverneratController,
                      
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Gouvernerat',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.map_1),
                              
                            ),
                    ),




                     const SizedBox(height: AlkSize.spaceBtwInputFields),
                    /// TermesOfConditions Checkbox
                    Row(
                      children: [
                        Checkbox(value: true, onChanged: (value){}),
                        AlkTOUCHeckbox()
                      ],
                    ),
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.all(Colors.purpleAccent[700]),
                      ),

                      onPressed: (){},
                     child: const Text('Confirmer la commande')),
                     )
                    
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
