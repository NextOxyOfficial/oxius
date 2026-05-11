import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

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

    // Required when FirebaseAppDelegateProxyEnabled is false: set the FCM
    // messaging delegate so token-refresh events are forwarded and logged.
    Messaging.messaging().delegate = self

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

  // CRITICAL: Without this override, FlutterAppDelegate calls completionHandler([])
  // — empty options — so remote push notifications are silently discarded when the
  // app is in the foreground.  FirebaseAppDelegateProxyEnabled=false means Firebase
  // cannot inject its own willPresent handling via swizzling, so we must do it here.
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Inform Firebase so it can fire the Dart onMessage stream.
    let userInfo = notification.request.content.userInfo
    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Display the notification as a banner with sound and badge even when
    // the app is open.  .banner and .list are iOS 14+; fall back to .alert
    // on older versions (both result in the same visual banner in practice).
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Forward notification taps to Firebase so the Dart onMessageOpenedApp /
  // getInitialMessage streams receive the payload correctly.
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    Messaging.messaging().appDidReceiveMessage(userInfo)
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}

// MessagingDelegate — required when FirebaseAppDelegateProxyEnabled is false.
// Logs FCM token refreshes to Xcode console / Codemagic build logs so you can
// verify the device is successfully registered with FCM.
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("[AdsyClub] FCM registration token refreshed: \(fcmToken ?? "nil")")
  }
}
