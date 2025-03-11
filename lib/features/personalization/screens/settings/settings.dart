import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:test/common/widgets/icons/circularIcons.dart';
import 'package:test/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:test/common/widgets/texts/section_heading.dart';
import 'package:test/features/authentication/screens/login/log_in.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/list_tiles/userProfile_tile.dart';
import '../../../../utils/backendData/userData.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //header
            AlkPrimaryHeaderContainer(
              child: Column(
                children: [
                  // App Bar
                  AlkAppBar(
                    showBackArrow: false,
                    title: Text(
                      ' Mon profile',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .apply(color: AlkColors.white),
                    ),
                  ),
                  const SizedBox(
                    height: AlkSize.spaceBtwSections / 2,
                  ),

                  // User ICON

                  const AlkProfileTile(),
                  const SizedBox(
                    height: AlkSize.spaceBtwSections,
                  ),
                ],
              ),
            ),

            //body

            Padding(
              padding: const EdgeInsets.all(AlkSize.defaultSpace),
              child: Column(
                children: [
                  // Account Setting
                  AlkSectionHeading(
                    title: 'Paramètres du compte',
                    showActionButton: false,
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),

                  AlkSettingMenuTile(
                      icon: Iconsax.safe_home,
                      title: 'Mes Adresses',
                      subtitle: 'Définir l\'adresse de livraison'),
                  AlkSettingMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: 'Mon Panier',
                      subtitle:
                          'Ajouter, supprimer des produits et passer à la caisse'),
                  AlkSettingMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Mes Commandes',
                      subtitle: 'Commandes en cours et terminées'),
                  AlkSettingMenuTile(
                      icon: Iconsax.discount_shape,
                      title: 'Mes Coupons',
                      subtitle: 'Liste de tous les coupons de réduction'),
                  AlkSettingMenuTile(
                      icon: Iconsax.notification,
                      title: 'Notifications',
                      subtitle: 'Définir tout type de message de notification'),
                  SizedBox(height: AlkSize.spaceBtwSections),
                  // Log out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            backgroundColor: AlkColors.primaryColor),               
                        onPressed: () => Get.to(()=> LoginScreen()),
                        child: const Text('Déconnexion',style: TextStyle(
                          color: Colors.white
                        ),)),
                        
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
