import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// Google Analytics (GA4) wrapper.
///
/// - Screen names: every pushed page is reported under its widget name
///   (Get.to(() => ProductDetails()) → "ProductDetails"), and the bottom-bar
///   tabs are reported by [logTab]. These show up in
///   Reports → Engagement → Pages and screens.
/// - Customer: [setUser] sends only the PrestaShop customer id number,
///   never a name or email.
/// - Product events: view_item, add_to_wishlist, add_to_cart.
///
/// Every call is fire-and-forget and silently skipped when Firebase is not
/// initialised (e.g. a platform without Firebase config).
class AnalyticsService {
  AnalyticsService._();

  static const String _currency = 'TND';

  /// Name of the screen shown under the bottom-bar shell, used when the user
  /// pops back to it. Set by [logTab].
  static String _currentTab = 'HomeScreen';

  static FirebaseAnalytics? get _ga =>
      Firebase.apps.isEmpty ? null : FirebaseAnalytics.instance;

  static void _run(Future<void> Function(FirebaseAnalytics ga) call) {
    final ga = _ga;
    if (ga == null) return;
    call(ga).catchError((Object e) {
      AlkLoggerHelper.error('Analytics call failed', e);
    });
  }

  static void logScreen(String name) {
    if (name.isEmpty) return;
    _run((ga) => ga.logScreenView(screenName: name, screenClass: name));
  }

  /// Called when the bottom bar / FAB switches the visible tab page.
  static void logTab(String name) {
    _currentTab = name;
    logScreen(name);
  }

  /// [customerId] empty = logged out.
  static void setUser(String customerId) {
    _run((ga) async {
      await ga.setUserId(id: customerId.isEmpty ? null : customerId);
      await ga.setUserProperty(
          name: 'logged_in', value: customerId.isEmpty ? 'no' : 'yes');
    });
  }

  static AnalyticsEventItem _item(
          String id, String name, String brand, double price) =>
      AnalyticsEventItem(
        itemId: id,
        itemName: name,
        itemBrand: brand.isEmpty ? null : brand,
        price: price > 0 ? price : null,
      );

  static void logViewItem({
    required String productId,
    required String name,
    String brand = '',
    double price = 0,
  }) {
    _run((ga) => ga.logViewItem(
          currency: _currency,
          value: price > 0 ? price : null,
          items: [_item(productId, name, brand, price)],
        ));
  }

  /// Seconds a product page stayed on screen. In GA4, register
  /// "seconds" as a custom metric and "item_id" as a custom dimension
  /// (Admin → Custom definitions) to rank products by reading time.
  static void logProductTime({
    required String productId,
    required String name,
    required int seconds,
  }) {
    _run((ga) => ga.logEvent(name: 'product_time', parameters: {
          'item_id': productId,
          'item_name': name.length > 100 ? name.substring(0, 100) : name,
          'seconds': seconds,
        }));
  }

  static void logAddToWishlist({
    required String productId,
    required String name,
    double price = 0,
  }) {
    _run((ga) => ga.logAddToWishlist(
          currency: _currency,
          value: price > 0 ? price : null,
          items: [_item(productId, name, '', price)],
        ));
  }

  static void logAddToCart({
    required String productId,
    required String name,
    String brand = '',
    double price = 0,
    int quantity = 1,
  }) {
    _run((ga) => ga.logAddToCart(
          currency: _currency,
          value: price > 0 ? price * quantity : null,
          items: [
            AnalyticsEventItem(
              itemId: productId,
              itemName: name,
              itemBrand: brand.isEmpty ? null : brand,
              price: price > 0 ? price : null,
              quantity: quantity,
            )
          ],
        ));
  }

  /// Turns a GetX/Navigator route name into a screen name.
  /// "/ProductDetails" → "ProductDetails"; "/" (the app shell) → current tab.
  /// [onReturn] = the route is being shown again after a pop.
  static String? _screenNameFor(Route<dynamic>? route, {bool onReturn = false}) {
    if (route is! PageRoute) return null; // skip dialogs, sheets, popups
    final raw = route.settings.name ?? '';
    var name = raw.startsWith('/') ? raw.substring(1) : raw;
    // GetX names anonymous builders like "/() => Foo" on some versions.
    name = name.replaceAll(RegExp(r'^\(\)\s*=>\s*'), '');
    if (name.isEmpty || name == 'NavigationMenu') {
      // The bottom-bar shell: it reports its own tab when first shown, and
      // we report the visible tab when the user comes back to it.
      return onReturn && Get.isRegistered<_ShellMarker>() ? _currentTab : null;
    }
    return name;
  }

  /// Call once the bottom-bar shell (NavigationMenu) is shown, so popping
  /// back to the root route reports the visible tab instead of "/".
  static void markShellReady() {
    if (!Get.isRegistered<_ShellMarker>()) {
      Get.put(_ShellMarker(), permanent: true);
    }
  }
}

class _ShellMarker {}

/// Add to GetMaterialApp.navigatorObservers.
class AnalyticsRouteObserver extends NavigatorObserver {
  void _report(Route<dynamic>? route, {bool onReturn = false}) {
    final name = AnalyticsService._screenNameFor(route, onReturn: onReturn);
    if (name != null) AnalyticsService.logScreen(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _report(previousRoute, onReturn: true);
  }
}
