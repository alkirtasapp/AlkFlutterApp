import 'package:alkirtas/features/personalization/screens/address/address.dart';
import 'package:alkirtas/features/personalization/screens/settings/wishlist_screen.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:alkirtas/features/personalization/screens/settings/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/widgets/list_tiles/userProfile_tile.dart';
import '../../../../common/widgets/providers/product_provider.dart';
import '../../../../features/audiobooks/controllers/audio_player_provider.dart';
import '../../../../features/shop/controllers/cart_provider.dart';
import '../../../../utils/backendData/userData.dart';
import 'package:provider/provider.dart';
import '../../../../providers/coupon_provider.dart';
import 'package:alkirtas/features/shop/widgets/coupons_sheet.dart';
import '../../../../providers/loyalty_provider.dart';
import '../../../../providers/odoo_account_provider.dart';
import '../../../../features/authentication/services/google_sign_in_service.dart';
import 'package:alkirtas/data/controllers/ets_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch loyalty points when screen loads, then auto-link to Odoo if data exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final loyaltyProvider =
          Provider.of<LoyaltyProvider>(context, listen: false);
      final odooProvider =
          Provider.of<OdooAccountProvider>(context, listen: false);

      await odooProvider.loadStatus();
      await loyaltyProvider.fetchLoyaltyPoints();

      // If the loyalty endpoint returned any meaningful data, the customer
      // already has an Odoo partner — no need to show "create account".
      final hasOdooData = loyaltyProvider.hasBarcode ||
          loyaltyProvider.hasPoints ||
          loyaltyProvider.programs.isNotEmpty;
      if (hasOdooData) {
        await odooProvider.markAsExisting();
      }
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
    final odooAccountProvider = Provider.of<OdooAccountProvider>(context, listen: false);

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

      odooAccountProvider.clear();

      // Sign out from Google (no-op if user logged in classically)
      await GoogleSignInService.signOut();
      await EtsService.clearTicket();

      // 2. Clear static UserData
      UserData.id = '';
      UserData.email = '';
      UserData.firstname = '';
      UserData.lastname = '';
      UserData.secure_key = '';
      UserData.password = '';
      UserData.phone = '';

      // 3. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await UserData.clearSession();
      await prefs.remove('pendingNavigation');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('remember_me');
      await prefs.remove('current_user_password');

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

  Future<void> _handleDeleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse('https://www.alkirtas.com/supprimer-compte.html');
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                Get.snackbar(
                  'Erreur',
                  'Impossible d\'ouvrir le lien. Veuillez réessayer.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                    title: 'Mon Adresse',
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
                          onPressed: () => Get.find<NavigationController>().navigateToCart()
                          ),
                  AlkSettingMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Historique des Commandes',
                      subtitle: 'Vos commandes en ligne et en magasin',
                      onPressed: () {
                        Get.to(() => const CartHistoryScreen());
                      },),
                  AlkSettingMenuTile(
                    icon: Iconsax.discount_shape,
                    title: 'Mes Coupons',
                    subtitle: 'Liste de tous les coupons de reduction',
                    onPressed: () => showCouponsSheet(context),
                  ),
                  AlkSettingMenuTile(
                    icon: Iconsax.notification_bing,
                    title: 'Ma liste de souhaits',
                    subtitle: 'Baisse de prix et retour en stock de vos produits',
                    onPressed: () => Get.to(() => const WishlistScreen()),
                  ),
                  AlkSettingMenuTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subtitle: 'Promotions et nouveautés reçues',
                    onPressed: () => Get.to(() => const NotificationsScreen()),
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
                  const SizedBox(height: AlkSize.spaceBtwItems),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _handleDeleteAccount(context),
                      child: const Text(
                        'Supprimer mon compte',
                        style: TextStyle(color: Colors.red),
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

/// Widget to display loyalty points, balance, and QR code as a loyalty card
class LoyaltyPointsCard extends StatefulWidget {
  const LoyaltyPointsCard({super.key});

  @override
  State<LoyaltyPointsCard> createState() => _LoyaltyPointsCardState();
}

class _LoyaltyPointsCardState extends State<LoyaltyPointsCard> {
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

        final deepColor =
            Color.lerp(AlkColors.AppFirstColor, Colors.black, 0.4)!;
        final endColor = Color.lerp(AlkColors.AppSecColor, Colors.black, 0.1)!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [deepColor, endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: deepColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    top: -45,
                    right: -35,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(loyaltyProvider),
                        const SizedBox(height: 16),
                        _buildBalances(loyaltyProvider),

                        // Expanded content
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: double.infinity,
                            child: _isExpanded
                                ? Column(
                                    children: [
                                      if (loyaltyProvider.hasBarcode) ...[
                                        const SizedBox(height: 16),
                                        _buildCodePanel(
                                            loyaltyProvider.barcode!,
                                            deepColor),
                                      ],
                                      _buildClaimButton(),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Format points: integer if whole, otherwise up to 2 decimals (trimmed), with
  /// French comma and thousands separator.
  /// e.g. 100.0 → "100", 100.5 → "100,5", 100.55 → "100,55", 1240.0 → "1 240"
  String _formatPoints(double points) {
    var s = points.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    final parts = s.split('.');
    parts[0] = parts[0]
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');
    return parts.join(',');
  }

  Widget _buildHeader(LoyaltyProvider loyaltyProvider) {
    return Row(
      children: [
        const Icon(Iconsax.medal_star, color: Color(0xFFFFC83D), size: 26),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Carte fidélité',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: loyaltyProvider.fetchLoyaltyPoints,
          tooltip: 'Actualiser',
          icon: const Icon(Iconsax.refresh, color: Colors.white70, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
    );
  }

  Widget _buildBalances(LoyaltyProvider loyaltyProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Loyalty Points
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solde actuel',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0, end: loyaltyProvider.totalPoints),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        _formatPoints(v),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'points',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Wallet Balance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.wallet, color: Colors.white70, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Portefeuille',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                    begin: 0, end: loyaltyProvider.walletBalance),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '${v.toStringAsFixed(2)} TND',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// White strip holding the QR code, like the barcode area of a physical card.
  Widget _buildCodePanel(String code, Color qrColor) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQrDialog(code, qrColor),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _buildQr(code, qrColor, 84),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code-barres',
                      style: TextStyle(
                        color: qrColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Touchez pour agrandir',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQr(String code, Color color, double size) {
    return QrImageView(
      data: code,
      version: QrVersions.auto,
      size: size,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: color,
      ),
    );
  }

  /// Larger QR code so it is easy to scan at the till.
  void _showQrDialog(String code, Color qrColor) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQr(code, qrColor, 220),
              const SizedBox(height: 12),
              Text(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Odoo account creation button — hidden once created
  Widget _buildClaimButton() {
    return Consumer<OdooAccountProvider>(
      builder: (context, odooProvider, _) {
        if (odooProvider.isCreated) return const SizedBox.shrink();
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              odooProvider.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          _showOdooAccountFlow(context, odooProvider),
                      icon: const Icon(Iconsax.card, size: 16),
                      label: const Text('Réclamer votre carte de fidélité'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
              if (odooProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    odooProvider.error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Normalize a Tunisian phone number to always start with +216.
  /// Strips spaces/dashes, keeps a leading +, and prepends +216 if missing.
  String _normalizePhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (p.isEmpty) return '';
    if (p.startsWith('+216')) return p;
    if (p.startsWith('216')) return '+$p';
    if (p.startsWith('00216')) return '+${p.substring(2)}';
    if (p.startsWith('+')) return p; // some other country prefix — leave as-is
    return '+216$p';
  }

  /// Shows password dialog (if needed), uses stored phone (or asks if missing),
  /// then calls the API with a normalized +216 phone.
  Future<void> _showOdooAccountFlow(
      BuildContext context, OdooAccountProvider odooProvider) async {
    // Step 1: get password
    // - Classic users: already in memory (set at login)
    // - Google users: derive a deterministic throwaway password (alk + email).
    //   Never shown to the user; only forwarded to Odoo as the portal password.
    String password = UserData.password;
    if (password.isEmpty) {
      password = 'alk${UserData.email.toLowerCase()}';
      UserData.password = password;
      OdooAccountProvider.savePassword(password);
    }

    // Step 2: phone — use stored, otherwise ask
    String phone = UserData.phone;
    if (phone.isEmpty) {
      if (!context.mounted) return;
      final entered = await _showPhoneDialog(context);
      if (entered == null || entered.isEmpty) return;
      phone = entered;
      // Persist for next time, keyed by email like at signup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_phone_${UserData.email.toLowerCase()}', phone);
      UserData.phone = phone;
    }
    phone = _normalizePhone(phone);
    if (phone.isEmpty) return;

    // Step 3: call the API
    if (!context.mounted) return;
    final success = await odooProvider.createOdooAccount(phone: phone);

    if (!context.mounted) return;
    if (success) {
      // Refresh loyalty data — for existing customers, this now returns
      // their points/wallet/barcode because the partner is linked via presta_id.
      Provider.of<LoyaltyProvider>(context, listen: false).fetchLoyaltyPoints();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte de fidélité réclamée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Dialog asking the user for their phone number.
  Future<String?> _showPhoneDialog(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Numéro de téléphone'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Téléphone (ex: +216 XX XXX XXX)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) Navigator.of(ctx).pop(val);
            },
            child: const Text('Créer le compte'),
          ),
        ],
      ),
    );
  }
}
