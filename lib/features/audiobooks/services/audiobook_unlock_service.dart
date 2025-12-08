import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage audiobook unlock codes
/// Fetches valid codes from server, stores unlocks locally
class AudiobookUnlockService {
  static const String _unlockedBooksKey = 'unlocked_audiobooks';
  static const String _usedCodesKey = 'used_audiobook_codes';

  // URL to your codes JSON file on server
  static const String _codesUrl = 'https://www.alkirtas.com/banners/AudioBooks/codes.json';

  SharedPreferences? _prefs;
  Map<String, String>? _serverCodes; // code -> audiobook_id

  // Singleton
  static final AudiobookUnlockService _instance = AudiobookUnlockService._internal();
  factory AudiobookUnlockService() => _instance;
  AudiobookUnlockService._internal();

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Fetch codes from server
  Future<bool> fetchCodesFromServer() async {
    try {
      final response = await http.get(
        Uri.parse(_codesUrl),
        headers: {'Accept-Charset': 'utf-8'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Expected format: {"codes": {"ABC123": "audiobook-id", ...}}
        if (data['codes'] != null) {
          _serverCodes = Map<String, String>.from(
            (data['codes'] as Map).map(
              (key, value) => MapEntry(key.toString().toUpperCase(), value.toString()),
            ),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error fetching codes: $e');
      return false;
    }
  }

  /// Get list of unlocked audiobook IDs
  Set<String> getUnlockedAudiobooks() {
    final list = _prefs?.getStringList(_unlockedBooksKey) ?? [];
    return list.toSet();
  }

  /// Get list of used codes (locally)
  Set<String> getUsedCodes() {
    final list = _prefs?.getStringList(_usedCodesKey) ?? [];
    return list.toSet();
  }

  /// Check if an audiobook is unlocked
  bool isUnlocked(String audiobookId) {
    return getUnlockedAudiobooks().contains(audiobookId);
  }

  /// Check if a code has been used on this device
  bool isCodeUsedLocally(String code) {
    return getUsedCodes().contains(code.toUpperCase());
  }

  /// Validate and redeem a code
  Future<UnlockResult> redeemCode(String code) async {
    await init();

    final normalizedCode = code.toUpperCase().trim();

    // Check if code is empty
    if (normalizedCode.isEmpty) {
      return UnlockResult(
        success: false,
        message: 'Veuillez entrer un code',
      );
    }

    // Fetch latest codes from server
    final fetched = await fetchCodesFromServer();
    if (!fetched || _serverCodes == null) {
      return UnlockResult(
        success: false,
        message: 'Erreur de connexion au serveur',
      );
    }

    // Check if code exists on server
    if (!_serverCodes!.containsKey(normalizedCode)) {
      return UnlockResult(
        success: false,
        message: 'Code invalide',
      );
    }

    // Check if code already used on this device
    if (isCodeUsedLocally(normalizedCode)) {
      return UnlockResult(
        success: false,
        message: 'Ce code a déjà été utilisé sur cet appareil',
      );
    }

    // Get the audiobook ID for this code
    final audiobookId = _serverCodes![normalizedCode]!;

    // Check if already unlocked
    if (isUnlocked(audiobookId)) {
      return UnlockResult(
        success: false,
        message: 'Ce livre audio est déjà déverrouillé',
        audiobookId: audiobookId,
      );
    }

    // Redeem the code locally
    await _markCodeAsUsed(normalizedCode);
    await _unlockAudiobook(audiobookId);

    return UnlockResult(
      success: true,
      message: 'Livre audio déverrouillé avec succès!',
      audiobookId: audiobookId,
    );
  }

  /// Mark a code as used locally
  Future<void> _markCodeAsUsed(String code) async {
    final usedCodes = getUsedCodes();
    usedCodes.add(code);
    await _prefs?.setStringList(_usedCodesKey, usedCodes.toList());
  }

  /// Unlock an audiobook locally
  Future<void> _unlockAudiobook(String audiobookId) async {
    final unlocked = getUnlockedAudiobooks();
    unlocked.add(audiobookId);
    await _prefs?.setStringList(_unlockedBooksKey, unlocked.toList());
  }

  /// Clear all unlocks (for testing only)
  Future<void> clearAllUnlocks() async {
    await init();
    await _prefs?.remove(_unlockedBooksKey);
    await _prefs?.remove(_usedCodesKey);
  }
}

/// Result of an unlock attempt
class UnlockResult {
  final bool success;
  final String message;
  final String? audiobookId;

  UnlockResult({
    required this.success,
    required this.message,
    this.audiobookId,
  });
}
