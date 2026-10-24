import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private let glassAccessibility = GlassAccessibilityStreamHandler()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    configureWindowAppearance(flutterViewController)
    delegate = self
    updateTrafficLightButtons()
    // The unified toolbar lays the buttons out again once the window shows,
    // so place them after that pass too.
    DispatchQueue.main.async { [weak self] in self?.updateTrafficLightButtons() }

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterEventChannel(
      name: "com.ardeman.bedug/glass_accessibility",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setStreamHandler(glassAccessibility)

    super.awakeFromNib()
  }

  private func configureWindowAppearance(_ flutterViewController: FlutterViewController) {
    // Keep traffic-light controls but remove visible title bar chrome.
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    isMovableByWindowBackground = true
    // An empty unified toolbar makes the titlebar tall enough to center the
    // traffic lights on the app's toolbar row (see updateTrafficLightButtons).
    let toolbar = NSToolbar()
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    toolbarStyle = .unified

    // Allow the Flutter surface to render rounded, glass-like window edges.
    isOpaque = false
    backgroundColor = .clear
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.cornerRadius = 26
    flutterViewController.view.layer?.masksToBounds = true
  }

  func windowDidResize(_ notification: Notification) {
    updateTrafficLightButtons()
  }

  private func updateTrafficLightButtons() {
    guard
      let close = standardWindowButton(.closeButton),
      let mini = standardWindowButton(.miniaturizeButton),
      let zoom = standardWindowButton(.zoomButton),
      let container = close.superview
    else { return }

    // Center the buttons on Flutter's toolbar row (kToolbarHeight, 56pt), the
    // line the location label, title capsules and action buttons sit on.
    let toolbarHeight: CGFloat = 56
    let topInset = (toolbarHeight - close.frame.height) / 2
    let leftInset: CGFloat = 14
    let spacing: CGFloat = 10
    let buttonY = container.frame.height - close.frame.height - topInset

    close.setFrameOrigin(NSPoint(x: leftInset, y: buttonY))
    mini.setFrameOrigin(NSPoint(x: leftInset + close.frame.width + spacing, y: buttonY))
    zoom.setFrameOrigin(NSPoint(x: leftInset + close.frame.width + spacing + mini.frame.width + spacing, y: buttonY))
  }
}

/// Sends the Liquid Glass tint and the Reduce Transparency and Increase
/// Contrast settings to Flutter (`lib/core/design/glass_accessibility.dart`)
/// on listen and whenever one changes, so the app's glass follows them.
final class GlassAccessibilityStreamHandler: NSObject, FlutterStreamHandler {
  /// The Clear (0) to Tinted (1) slider in System Settings → Appearance →
  /// Liquid Glass. Undocumented: Apple has no API for it, so a missing or
  /// unreadable value leaves the glass Clear.
  private static let tintAmountKey = "NSGlassTintAmount"

  private var sink: FlutterEventSink?
  private var observers: [(NotificationCenter, NSObjectProtocol)] = []

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    let workspaceCenter = NSWorkspace.shared.notificationCenter
    observers = [
      (workspaceCenter, NSWorkspace.accessibilityDisplayOptionsDidChangeNotification),
      // The tint has no change notification; read it again when the user
      // comes back from System Settings.
      (NotificationCenter.default, NSApplication.didBecomeActiveNotification),
    ].map { center, name in
      (center, center.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] _ in self?.send()
      })
    }
    // Follows the slider live while Bedug is visible behind System Settings.
    UserDefaults.standard.addObserver(self, forKeyPath: Self.tintAmountKey, context: nil)
    send()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observers.forEach { center, observer in center.removeObserver(observer) }
    observers = []
    UserDefaults.standard.removeObserver(self, forKeyPath: Self.tintAmountKey)
    sink = nil
    return nil
  }

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    DispatchQueue.main.async { [weak self] in self?.send() }
  }

  /// The slider value, which System Settings stores as a string.
  private var tintAmount: Double? {
    switch UserDefaults.standard.object(forKey: Self.tintAmountKey) {
    case let number as NSNumber: return number.doubleValue
    case let text as String: return Double(text)
    default: return nil
    }
  }

  private func send() {
    let workspace = NSWorkspace.shared
    var settings: [String: Any] = [
      "reduceTransparency": workspace.accessibilityDisplayShouldReduceTransparency,
      "increaseContrast": workspace.accessibilityDisplayShouldIncreaseContrast,
    ]
    if let tintAmount { settings["tintAmount"] = tintAmount }
    sink?(settings)
  }
}
