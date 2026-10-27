import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Ask Apple for the push token explicitly; the result lands in the two
    // callbacks below.
    application.registerForRemoteNotifications()
    return launched
  }

  // Apple's answer is kept in UserDefaults under the "flutter." prefix so the
  // Dart side can read it through shared_preferences for the status screen.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    UserDefaults.standard.set("ok", forKey: "flutter.apns_result")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    UserDefaults.standard.set("erreur: \(error.localizedDescription)", forKey: "flutter.apns_result")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
