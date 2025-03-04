import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/signIn/AlkTOU.dart';
import 'package:test/utils/backendData/addressData.dart';
import 'package:test/utils/backendData/userData.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

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
                            expands: false,
                            decoration: InputDecoration(
                              //labelText: '',
                              labelText: UserData.firstname,
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Iconsax.user) ,
                            ),
                          ),
                        ),
                        SizedBox(width: AlkSize.spaceBtwInputFields),
                           Expanded(
                          child: TextFormField(
                            expands: false,
                            decoration: InputDecoration(
                              //labelText: 'Prénom',
                              labelText: UserData.lastname,
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
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Téléphone',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.mobile) 
                            ),
                    ),
                    /// Phone 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                       TextFormField(
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Adresse ',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.house) 
                            ),
                    ),
                    
                    /// Email
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Code postale',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.direct) 
                            ),
                    ),
                    /// Password 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
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
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Pays',labelStyle: TextStyle(color: Colors.grey),
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
                    child: ElevatedButton(onPressed: (){}, child: const Text('Confirmer la commande')),)
                    
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
