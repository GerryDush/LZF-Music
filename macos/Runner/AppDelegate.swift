import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let flutterViewController = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController {
      setupAudioRouteChannel(messenger: flutterViewController.engine.binaryMessenger)
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      // 如果没有可见窗口，显示主窗口
      if let window = NSApplication.shared.windows.first {
        window.makeKeyAndOrderFront(nil)
      }
    }
    return true
  }
  
  // MARK: - Audio Route Channel
  private func setupAudioRouteChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.lzf.music/audio_route", binaryMessenger: messenger)
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "showAirPlayPicker":
        self.showAudioOutputPicker()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // MARK: - Audio Route Handler
  private func showAudioOutputPicker() {
    DispatchQueue.main.async {
      // macOS 上显示系统音频输出设置
      let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound")!
      NSWorkspace.shared.open(url)
    }
  }
}

