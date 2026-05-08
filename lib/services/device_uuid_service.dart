import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Generates and persists a device UUID used to track one-time scratch card claims.
///
/// On iOS, the UUID is stored in Keychain and survives app reinstalls.
/// On Android, it is cleared on reinstall (acceptable trade-off for Play Store compliance).
class DeviceUuidService {
  static const _key = 'alkirtas_device_uuid';
  static const _storage = FlutterSecureStorage();

  static Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final newUuid = const Uuid().v4();
    await _storage.write(key: _key, value: newUuid);
    return newUuid;
  }
}
