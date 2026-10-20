import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
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
