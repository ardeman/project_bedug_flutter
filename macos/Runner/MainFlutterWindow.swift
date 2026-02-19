import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    configureWindowAppearance(flutterViewController)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func configureWindowAppearance(_ flutterViewController: FlutterViewController) {
    // Keep traffic-light controls but remove visible title bar chrome.
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    isMovableByWindowBackground = true

    // Allow the Flutter surface to render rounded, glass-like window edges.
    isOpaque = false
    backgroundColor = .clear
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.cornerRadius = 24
    flutterViewController.view.layer?.masksToBounds = true
  }
}
