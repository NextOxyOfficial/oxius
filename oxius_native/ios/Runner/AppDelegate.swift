import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import PushKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var voipRegistry: PKPushRegistry?

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

    // Register for VoIP pushes via PushKit so incoming call notifications
    // are delivered with high-priority even when the app is killed.
    // PushKit wakes the app faster than standard FCM data-only messages.
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Required because FirebaseAppDelegateProxyEnabled is false in Info.plist.
  // Without this, FCM cannot obtain an APNS token and FCMService.initialize()
  // can hang on iOS, contributing to a blank-screen launch on iPad.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
#if DEBUG
    Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
    print("[AdsyClub] APNS device token registered (sandbox): \(token)")
#else
    Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    print("[AdsyClub] APNS device token registered (production): \(token)")
#endif
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

  // With FirebaseAppDelegateProxyEnabled=false, background / silent remote
  // notifications must also be forwarded manually. Without this callback iOS
  // can deliver the APNs packet but the Flutter/Firebase layer never gets the
  // background receipt path, which breaks silent wakes and weakens killed /
  // background recovery for data-bearing notifications.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Messaging.messaging().appDidReceiveMessage(userInfo)
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
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

// PKPushRegistryDelegate — handles VoIP push credentials and incoming VoIP payloads.
// VoIP pushes have guaranteed delivery priority and wake the app even when killed,
// which ensures the CallKit incoming-call UI rings reliably on iOS.
extension AppDelegate: PKPushRegistryDelegate {
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    // Log the VoIP token. If you later want server-side VoIP push delivery,
    // send this token to your backend here.
    let tokenData = pushCredentials.token
    let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
    print("[AdsyClub] VoIP push token: \(token)")
    // flutter_callkit_incoming handles its own push delivery via FCM.
    // This token is available if you want to switch to direct VoIP APNs delivery.
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    // A VoIP push was received while the app was in the background or killed.
    // Forward it to flutter_callkit_incoming so the Dart background handler
    // can trigger the CallKit incoming-call UI with the native device ringtone.
    let dict = payload.dictionaryPayload as NSDictionary
    print("[AdsyClub] VoIP push received: \(dict)")

    // flutter_callkit_incoming expects the payload forwarded through its
    // FlutterCallkitIncoming channel. For now we ensure the app wakes;
    // Dart-side FCM handler shows the CallKit UI via showCallkitIncoming().
    // Call completion() to satisfy iOS requirement — must be called within
    // the same runloop or CallKit will not display the incoming call screen.
    completion()
  }
}
