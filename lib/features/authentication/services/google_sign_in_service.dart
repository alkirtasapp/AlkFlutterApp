import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../../../utils/backendData/userData.dart';
import '../../../utils/logging/logger.dart';

/// Handles Google Sign-In + bridging to the PrestaShop `alkirtas_google_login`
/// module's onetap endpoint (which logs in or auto-registers the customer).
class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleWebClientId.isNotEmpty
        ? AppConfig.googleWebClientId
        : null,
  );

  static const String _onetapUrl =
      'https://www.alkirtas.com/module/alkirtas_google_login/onetap?mobile=1';

  /// Trigger Google sign-in, exchange the ID token for a PrestaShop customer
  /// via the onetap endpoint, then populate `UserData`.
  ///
  /// Returns null on success, or a user-facing error message on failure.
  static Future<String?> signIn() async {
    try {
      // Force-clear any sticky session so the account picker always appears
      // and to avoid the "second sign-in stuck after logout" issue.
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore — no active session to sign out from
      }

      // 1. Google account picker
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return 'Google sign-in cancelled.';
      }

      // 2. Get the ID token (JWT) — same thing the website's One Tap flow uses
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return 'Could not retrieve Google ID token.';
      }

      // 3. POST it to the PrestaShop module endpoint
      final response = await http.post(
        Uri.parse(_onetapUrl),
        body: {'credential': idToken},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        AlkLoggerHelper.error(
            '[GoogleSignIn] onetap HTTP ${response.statusCode}: ${response.body}');
        return 'Server rejected Google sign-in (${response.statusCode}).';
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['success'] != true) {
        final err = (data is Map ? data['error']?.toString() : null) ?? 'Unknown error';
        return 'Sign-in failed: $err';
      }

      // 4. Populate UserData. No password — Google users don't have one the app knows.
      UserData.id = data['customer_id'].toString();
      UserData.email = (data['email'] ?? account.email).toString();
      UserData.firstname = (data['firstname'] ?? '').toString();
      UserData.lastname = (data['lastname'] ?? '').toString();
      UserData.password = ''; // Empty marks this as a Google session

      // 5. Restore phone from SharedPreferences if previously stored (same key as classic flow)
      final prefs = await SharedPreferences.getInstance();
      UserData.phone = prefs
              .getString('customer_phone_${UserData.email.toLowerCase()}') ??
          '';

      AlkLoggerHelper.info(
          '[GoogleSignIn] Signed in: customer_id=${UserData.id}, email=${UserData.email}');

      return null;
    } catch (e, stack) {
      AlkLoggerHelper.error('[GoogleSignIn] Exception: $e\n$stack');
      return 'Google sign-in error: $e';
    }
  }

  /// Sign out from Google (call alongside the app's existing logout flow).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      AlkLoggerHelper.error('[GoogleSignIn] signOut error: $e');
    }
  }
}
