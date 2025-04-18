import 'package:alkirtas/utils/constants/images_strings.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:flutter/material.dart';

class AlkLoginHeader extends StatelessWidget {
  const AlkLoginHeader({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'app_logo',
          child: Image(
            height: 150,
            image: AssetImage(
                dark ? AlkImages.darkAppLogo : AlkImages.lighAppLogo),
          ),
        ),
        const SizedBox(height: AlkSize.lg),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 1.0,
          child: Text(
            'Connectez-vous à votre Compte',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}