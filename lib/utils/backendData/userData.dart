import 'package:shared_preferences/shared_preferences.dart';

 class UserData {
  static String id = '';
  static String email = '';
  static String firstname = '';
  static String lastname = '';
  static String secure_key = '';
  static String password = '';
  static String phone = '';

  // Session persistence so a killed app doesn't force a new login.
  // The password itself is persisted separately by OdooAccountProvider.
  static const String _sessionPrefix = 'session_';

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_sessionPrefix}id', id);
    await prefs.setString('${_sessionPrefix}email', email);
    await prefs.setString('${_sessionPrefix}firstname', firstname);
    await prefs.setString('${_sessionPrefix}lastname', lastname);
    await prefs.setString('${_sessionPrefix}phone', phone);
    await prefs.setBool('isLoggedIn', id.isNotEmpty);
  }

  /// Restore the last logged-in customer. Returns true if a session was found.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('${_sessionPrefix}id') ?? '';
    if (savedId.isEmpty) return false;
    id = savedId;
    email = prefs.getString('${_sessionPrefix}email') ?? '';
    firstname = prefs.getString('${_sessionPrefix}firstname') ?? '';
    lastname = prefs.getString('${_sessionPrefix}lastname') ?? '';
    phone = prefs.getString('${_sessionPrefix}phone') ?? '';
    if (phone.isEmpty) {
      phone = prefs.getString('customer_phone_${email.toLowerCase()}') ?? '';
    }
    // Classic-login password (empty for Google sessions)
    password = prefs.getString('current_user_password') ?? '';
    return true;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['id', 'email', 'firstname', 'lastname', 'phone']) {
      await prefs.remove('$_sessionPrefix$key');
    }
    await prefs.remove('isLoggedIn');
  }
}
