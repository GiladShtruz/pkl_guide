import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.gilad.pklGuide/intent"
  private var sharedData: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup method channel
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }

      if call.method == "getSharedData" {
        result(self.sharedData)
        self.sharedData = nil // Clear after reading
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle opening files from other apps
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    do {
      let data = try String(contentsOf: url, encoding: .utf8)
      sharedData = data
    } catch {
      print("Error reading file: \(error)")
    }
    return true
  }

  // Handle opening files (alternative method for newer iOS versions)
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      do {
        let data = try String(contentsOf: url, encoding: .utf8)
        sharedData = data
      } catch {
        print("Error reading file: \(error)")
      }
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
