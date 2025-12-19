import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration class for accessing environment variables.
/// All API keys and sensitive configuration should be accessed through this class.
class AppConfig {
  // PrestaShop Configuration
  static String get prestashopApiKey => dotenv.env['PRESTASHOP_API_KEY'] ?? '';
  static String get prestashopBaseUrl => dotenv.env['PRESTASHOP_BASE_URL'] ?? 'https://www.alkirtas.com/api';

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  /// Helper to build PrestaShop API URLs with the API key
  static String prestashopUrl(String endpoint, {Map<String, String>? params}) {
    final baseUrl = prestashopBaseUrl;
    final queryParams = {
      'ws_key': prestashopApiKey,
      'output_format': 'JSON',
      ...?params,
    };
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$baseUrl/$endpoint?$queryString';
  }
}
