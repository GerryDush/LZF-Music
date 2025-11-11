import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // macos 26 corner
    let toolbar = NSToolbar(identifier: "MainToolbar")
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}