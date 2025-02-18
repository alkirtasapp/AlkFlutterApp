import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/signIn/AlkTOU.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AlkSize.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text('Créons votre compte...',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(
                height: AlkSize.spaceBtwSections,
              ),

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
                            decoration: const InputDecoration(
                              labelText: 'Nom',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.user) ,
                            ),
                          ),
                        ),
                        SizedBox(width: AlkSize.spaceBtwInputFields),
                           Expanded(
                          child: TextFormField(
                            expands: false,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.user) 
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
                              prefixIcon: Icon(Iconsax.call) 
                            ),
                    ),
                    
                    /// Email
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Email',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.direct) 
                            ),
                    ),
                    /// Password 
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Mot de passe ',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.password_check) ,
                              suffix: Icon(Iconsax.eye_slash),
                            ),
                    ),
                     /// Password check
                    const SizedBox(height: AlkSize.spaceBtwInputFields),
                    TextFormField(
                      obscureText: true,
                      expands: false,
                      decoration: const InputDecoration(
                              labelText: 'Saisissez à nouveau votre mot de passe',labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.password_check) ,
                              suffix: Icon(Iconsax.eye_slash),
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
                    child: ElevatedButton(onPressed: (){}, child: const Text('Créer un compte')),)
                    
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

