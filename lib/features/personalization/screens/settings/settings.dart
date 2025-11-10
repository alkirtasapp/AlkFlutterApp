import 'package:alkirtas/features/personalization/screens/address/address.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/appbar/appbar.dart';
import 'package:alkirtas/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:alkirtas/common/widgets/icons/circularIcons.dart';
import 'package:alkirtas/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:alkirtas/common/widgets/texts/section_heading.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/features/shop/screens/cart/cart.dart';
import 'package:alkirtas/features/shop/screens/cart/cart_history.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';

import '../../../../common/widgets/list_tiles/userProfile_tile.dart';
import '../../../../utils/backendData/userData.dart';
import 'package:provider/provider.dart';
import '../../../../providers/coupon_provider.dart';

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
                    subtitle: 'Définir l\'adresse de livraison',
                    onPressed: () {
                      Get.to(() => const AddressScreen());
                    },
                  ),
                      
                  AlkSettingMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: 'Panier Actuel',
                      subtitle:
                          'Ajouter, supprimer des produits et passer à la caisse',
                          onPressed:  (){Get.offAll(() => const NavigationMenu(selectedMenu: 2));}
                          ),
                  AlkSettingMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Historique des Paniers',
                      subtitle: 'Accédez à vos paniers sauvegardés',
                      onPressed: () {
                        Get.to(() => const CartHistoryScreen());
                      },),
                /*  AlkSettingMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Mes Commandes',
                      subtitle: 'Commandes en cours et terminées', onPressed: () {  },),*/
                  AlkSettingMenuTile(
                    icon: Iconsax.discount_shape,
                    title: 'Mes Coupons',
                    subtitle: 'Liste de tous les coupons de réduction',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CouponPopup(),
                      );
                    },
                  ),
                  AlkSettingMenuTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subtitle: 'Définir tout type de message de notification',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Fonctionnalité indisponible'),
                            content: Text('Cette fonctionnalité n\'est pas encore disponible.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: AlkSize.spaceBtwSections),
                  // Log out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AlkColors.primaryColor,
                      ),
                      onPressed: () => Get.offAll(() => LoginScreen()),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
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


/// import required packages
/// Create SettingScreen stateless widget that displayes the user profile and account settings
/// Create the UI{
///   Header :  AppBar and User Icon
///  Body :
///   - Account Settings
///   - My Addresses
///   - My Cart
///   - My Orders
///   - My Coupons
/// }
/// Add a log out button at the end of the screen

class CouponPopup extends StatefulWidget {
  const CouponPopup({super.key});

  @override
  _CouponPopupState createState() => _CouponPopupState();
}

class _CouponPopupState extends State<CouponPopup> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final couponProvider = Provider.of<CouponProvider>(context);
    return AlertDialog(
      title: Text('Mes Coupons'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 450,
            maxHeight: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Ajouter un code',
                  errorText: _error,
                ),
              ),
              SizedBox(height: 8),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        final code = _controller.text.trim();
                        if (code.isEmpty) {
                          setState(() {
                            _error = 'Veuillez entrer un code.';
                            _isLoading = false;
                          });
                          return;
                        }
                        final success = await couponProvider.addCoupon(code);
                        setState(() {
                          _isLoading = false;
                          _error = success ? null : 'Code invalide ou déjà utilisé.';
                          if (success) _controller.clear();
                        });
                      },
                      child: Text('Ajouter'),
                    ),
              Divider(),
              Text('Coupons collectés :'),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: couponProvider.coupons.length,
                  itemBuilder: (context, i) {
                    final coupon = couponProvider.coupons[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.local_offer, color: Colors.orange, size: 32),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            coupon.code,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              letterSpacing: 1.2,
                                              color: Colors.orange.shade900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (coupon.reductionPercent != null && coupon.reductionPercent! > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '-${coupon.reductionPercent!.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else if (coupon.reductionAmount != null && coupon.reductionAmount! > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '-${coupon.reductionAmount!.toStringAsFixed(2)} MAD',
                                              style: TextStyle(
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      coupon.name,
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Expire le : ${coupon.expiryDate != null
                                          ? '${coupon.expiryDate.day.toString().padLeft(2, '0')}/'
                                            '${coupon.expiryDate.month.toString().padLeft(2, '0')}/'
                                            '${coupon.expiryDate.year}'
                                          : 'Inconnue'}',
                                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  couponProvider.removeCoupon(coupon);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Fermer'),
        ),
      ],
    );
  }
}

