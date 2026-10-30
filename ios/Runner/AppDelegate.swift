import CoreLocation
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
  private let compass = CompassStreamHandler()

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GlassAccessibility") {
      FlutterEventChannel(
        name: "com.ardeman.bedug/glass_accessibility",
        binaryMessenger: registrar.messenger()
      ).setStreamHandler(glassAccessibility)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Compass") {
      FlutterEventChannel(
        name: "com.ardeman.bedug/compass",
        binaryMessenger: registrar.messenger()
      ).setStreamHandler(compass)
    }
  }
}

/// Sends Reduce Transparency, Increase Contrast and the Clear/Tinted Liquid
/// Glass style to Flutter (`lib/core/design/glass_accessibility.dart`) on
/// listen and whenever they may have changed, so the app's glass follows them.
final class GlassAccessibilityStreamHandler: NSObject, FlutterStreamHandler {
  /// The Clear (0) to Tinted (1) slider in Settings → Display & Brightness →
  /// Liquid Glass. Undocumented: Apple has no API for it, so a missing or
  /// unreadable value leaves the glass Clear.
  private static let tintAmountSuite = "com.apple.UIKit"
  private static let tintAmountKey = "UIViewGlassTintAmount"

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
      // The tint has no change notification, and the slider lives in the
      // Settings app; read it again when the user comes back.
      UIApplication.didBecomeActiveNotification,
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
    var event: [String: Any] = [
      "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
      "increaseContrast": UIAccessibility.isDarkerSystemColorsEnabled,
    ]
    if let tintAmount { event["tintAmount"] = tintAmount }
    sink?(event)
  }

  private var tintAmount: Double? {
    switch UserDefaults(suiteName: Self.tintAmountSuite)?.object(forKey: Self.tintAmountKey) {
    case let number as NSNumber: return number.doubleValue
    case let text as String: return Double(text)
    default: return nil
    }
  }
}

/// Sends the compass heading to Flutter (`lib/features/qibla/widgets/qibla_card.dart`)
/// as `[heading, accuracy]`, measured to the top of the screen as it is turned,
/// so the Qibla dial stays right in landscape. `flutter_compass` corrects with
/// the deprecated `statusBarOrientation`, which reports no rotation in a
/// scene-based app.
final class CompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private var sink: FlutterEventSink?
  private var manager: CLLocationManager?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else { return nil }
    sink = events
    let manager = CLLocationManager()
    manager.delegate = self
    manager.headingFilter = 0.1
    manager.startUpdatingHeading()
    self.manager = manager
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager?.stopUpdatingHeading()
    manager = nil
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
    // A negative accuracy marks an invalid heading.
    guard heading.headingAccuracy >= 0 else { return }
    // True north needs a location fix; until then use magnetic north.
    let north = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    let screenTop = (north + screenTopOffset + 360).truncatingRemainder(dividingBy: 360)
    sink?([screenTop, heading.headingAccuracy])
  }

  /// Degrees clockwise from the top of the device to the top of the screen.
  private var screenTopOffset: Double {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    switch scene?.effectiveGeometry.interfaceOrientation {
    case .landscapeRight: return 90
    case .landscapeLeft: return -90
    case .portraitUpsideDown: return 180
    default: return 0
    }
  }
}
