import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/utils/constants/size.dart';
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(AlkSize.defaultSpace),
        child: 
        Column(
          children: [
            // Title 
            Text('Title placeholder' ,style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox( height:  AlkSize.spaceBtwItems,),

            // Form   
            Form(child: Column(
              children: [
                 TextFormField(
                  expands: false,
                  decoration: const InputDecoration(
                    labelText: 'Nom ',
                    prefixIcon: Icon(Iconsax.user) ,
                  ),
                 )
              ],
            ) ,)

          ],
        ),),
      ),
    );
  }
}