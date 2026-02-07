import 'package:in_app_update/in_app_update.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class AppUpdateService {
  /// Checks Google Play for an available update and prompts the user.
  /// Uses flexible update by default (non-blocking, downloads in background).
  /// Set [immediate] to true for critical updates that block app usage.
  static Future<void> checkForUpdate({bool immediate = false}) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (immediate && updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          // Once downloaded, prompt user to install
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // Silently fail — update check should never break the app.
      // Common reasons: debug mode, no Play Store, no internet.
      AlkLoggerHelper.warning('In-app update check failed: $e');
    }
  }
}
