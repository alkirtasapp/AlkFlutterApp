import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Generates and persists a device UUID used to track one-time scratch card claims.
///
/// Note: uses SharedPreferences (cleared on app uninstall). When the scratch
/// card feature is re-enabled, consider swapping back to flutter_secure_storage
/// to make iOS Keychain persist the UUID across reinstalls.
class DeviceUuidService {
  static const _key = 'alkirtas_device_uuid';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final newUuid = const Uuid().v4();
    await prefs.setString(_key, newUuid);
    return newUuid;
  }
}
