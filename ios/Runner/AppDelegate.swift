import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private let glassAccessibility = GlassAccessibilityStreamHandler()

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GlassAccessibility") {
      FlutterEventChannel(
        name: "com.ardeman.bedug/glass_accessibility",
        binaryMessenger: registrar.messenger()
      ).setStreamHandler(glassAccessibility)
    }
  }
}

/// Sends Reduce Transparency and Increase Contrast to Flutter
/// (`lib/core/design/glass_accessibility.dart`) on listen and whenever either
/// changes, so the app's glass follows them. iOS has no API for the Clear or
/// Tinted Liquid Glass style.
final class GlassAccessibilityStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    observers = [
      UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
    ].map { name in
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] _ in self?.send()
      }
    }
    send()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers = []
    sink = nil
    return nil
  }

  private func send() {
    sink?([
      "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
      "increaseContrast": UIAccessibility.isDarkerSystemColorsEnabled,
    ])
  }
}
