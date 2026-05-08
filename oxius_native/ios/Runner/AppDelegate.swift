import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase as early as possible. Safe to call even if Flutter
    // also calls Firebase.initializeApp(); FirebaseApp.configure() is a no-op
    // when an app is already configured.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Required because FirebaseAppDelegateProxyEnabled is false in Info.plist.
  // Without this, FCM cannot obtain an APNS token and FCMService.initialize()
  // can hang on iOS, contributing to a blank-screen launch on iPad.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Catches APNs registration failures (certificate mismatch, entitlement issues,
  // sandbox vs production mismatch, etc.).  Without this handler, registration
  // failures are completely silent and FCM tokens are never generated on iOS.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Log the failure so it appears in Xcode console / Codemagic build logs.
    print("[AdsyClub] APNs registration FAILED: \(error.localizedDescription)")
    print("[AdsyClub] Full error: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
