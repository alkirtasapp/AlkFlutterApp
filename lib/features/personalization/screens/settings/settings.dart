import 'package:alkirtas/features/personalization/screens/address/address.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
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
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/widgets/list_tiles/userProfile_tile.dart';
import '../../../../common/widgets/providers/product_provider.dart';
import '../../../../features/audiobooks/controllers/audio_player_provider.dart';
import '../../../../features/shop/controllers/cart_provider.dart';
import '../../../../utils/backendData/userData.dart';
import 'package:provider/provider.dart';
import '../../../../providers/coupon_provider.dart';
import '../../../../providers/loyalty_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch loyalty points when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LoyaltyProvider>(context, listen: false).fetchLoyaltyPoints();
    });
  }

  /// Handle logout: clear all cached and saved data
  Future<void> _handleLogout(BuildContext context) async {
    // Capture providers before async operations
    final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
    final couponProvider = Provider.of<CouponProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final audioPlayerProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. Clear all providers
      loyaltyProvider.clear();
      couponProvider.clearCoupons();
      await cartProvider.clearCart();
      await cartProvider.clearCartHistory();
      productProvider.clearCart();
      audioPlayerProvider.clearAudiobook();

      // 2. Clear static UserData
      UserData.id = '';
      UserData.email = '';
      UserData.firstname = '';
      UserData.lastname = '';
      UserData.secure_key = '';

      // 3. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('pendingNavigation');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('remember_me');

      // 4. Clear Hive caches (untyped boxes only)
      // Note: couponsBox and savedCartsBox are already cleared by the providers above
      final productBox = await Hive.openBox('productCache');
      await productBox.clear();
      final bannerBox = await Hive.openBox('bannerBox');
      await bannerBox.clear();
      final sectionsBox = await Hive.openBox('sectionsBox');
      await sectionsBox.clear();
      final cartBox = await Hive.openBox('cartBox');
      await cartBox.clear();

      // Close loading dialog and navigate to login
      Get.back(); // Close loading dialog
      Get.offAll(() => LoginScreen());
    } catch (e) {
      // Close loading dialog on error
      Get.back();
      // Show error message using GetX snackbar
      Get.snackbar(
        'Erreur',
        'Erreur lors de la deconnexion: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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

                  // Loyalty Points Card
                  SizedBox(height: AlkSize.spaceBtwItems),
                  LoyaltyPointsCard(),

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
                    title: 'Parametres du compte',
                    showActionButton: false,
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),

                  AlkSettingMenuTile(
                    icon: Iconsax.safe_home,
                    title: 'Mes Adresses',
                    subtitle: 'Definir l\'adresse de livraison',
                    onPressed: () {
                      Get.to(() => const AddressScreen());
                    },
                  ),

                  AlkSettingMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: 'Panier Actuel',
                      subtitle:
                          'Ajouter, supprimer des produits et passer a la caisse',
                          onPressed:  (){Get.offAll(() => const NavigationMenu(selectedMenu: 2));}
                          ),
                  AlkSettingMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Historique des Commandes',
                      subtitle: 'Accedez a vos paniers sauvegardes',
                      onPressed: () {
                        Get.to(() => const CartHistoryScreen());
                      },),
                  AlkSettingMenuTile(
                    icon: Iconsax.discount_shape,
                    title: 'Mes Coupons',
                    subtitle: 'Liste de tous les coupons de reduction',
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
                    subtitle: 'Definir tout type de message de notification',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Fonctionnalite indisponible'),
                            content: Text('Cette fonctionnalite n\'est pas encore disponible.'),
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
                        backgroundColor: AlkColors.AppFirstColor,
                      ),
                      onPressed: () => _handleLogout(context),
                      child: const Text(
                        'Deconnexion',
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

/// Widget to display loyalty points, balance, and QR code in an expandable card
class LoyaltyPointsCard extends StatefulWidget {
  const LoyaltyPointsCard({super.key});

  @override
  State<LoyaltyPointsCard> createState() => _LoyaltyPointsCardState();
}

class _LoyaltyPointsCardState extends State<LoyaltyPointsCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LoyaltyProvider>(
      builder: (context, loyaltyProvider, child) {
        if (loyaltyProvider.isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Chargement...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (loyaltyProvider.error != null) {
          return const SizedBox.shrink();
        }

        // Don't show if no data at all
        final hasData = loyaltyProvider.hasPoints ||
            loyaltyProvider.hasBalance ||
            loyaltyProvider.hasBarcode;
        if (!hasData) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AlkColors.AppFirstColor.withOpacity(0.7),
                    AlkColors.AppSecColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AlkColors.AppFirstColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Collapsed header - always visible
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.card,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Summary info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Carte de fidelite',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (loyaltyProvider.hasPoints) ...[
                                    Icon(Iconsax.gift, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${loyaltyProvider.totalPoints.toStringAsFixed(0)} pts',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (loyaltyProvider.hasBalance) ...[
                                    Icon(Iconsax.wallet, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${loyaltyProvider.walletBalance.toStringAsFixed(2)} TND',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Expand/collapse indicator
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Iconsax.arrow_down_1,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded content
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildExpandedContent(loyaltyProvider),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(LoyaltyProvider loyaltyProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // QR Code section
          if (loyaltyProvider.hasBarcode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Code-barres',
                    style: TextStyle(
                      color: AlkColors.AppFirstColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loyaltyProvider.barcode!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: loyaltyProvider.barcode!,
                    version: QrVersions.auto,
                    size: 120,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AlkColors.AppFirstColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AlkColors.AppFirstColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Points and Balance row
          Row(
            children: [
              // Loyalty Points
              if (loyaltyProvider.hasPoints)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Iconsax.gift, color: Colors.white70, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          loyaltyProvider.totalPoints.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          loyaltyProvider.programs.isNotEmpty
                              ? loyaltyProvider.programs.first.pointName
                              : 'point(s)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (loyaltyProvider.hasPoints && loyaltyProvider.hasBalance)
                const SizedBox(width: 12),

              // Wallet Balance
              if (loyaltyProvider.hasBalance)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Iconsax.wallet, color: Colors.white70, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          loyaltyProvider.walletBalance.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'TND',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Refresh button
          TextButton.icon(
            onPressed: () {
              loyaltyProvider.fetchLoyaltyPoints();
            },
            icon: const Icon(Iconsax.refresh, size: 16),
            label: const Text('Actualiser'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}


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
                          _error = success ? null : 'Code invalide ou deja utilise.';
                          if (success) _controller.clear();
                        });
                      },
                      child: Text('Ajouter'),
                    ),
              Divider(),
              Text('Coupons collectes :'),
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
                                                color: AlkColors.AppSecColor,
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
                                      'Expire le : ${coupon.expiryDate != null ? "${coupon.expiryDate.day.toString().padLeft(2, '0')}/${coupon.expiryDate.month.toString().padLeft(2, '0')}/${coupon.expiryDate.year}" : "Inconnue"}',
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