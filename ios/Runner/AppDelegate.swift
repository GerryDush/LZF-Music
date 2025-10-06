import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioSessionChannel: FlutterMethodChannel?
  private var lastNowPlayingInfo: [String: Any]?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      audioSessionChannel = FlutterMethodChannel(
        name: "com.lzf.music/audio_session",
        binaryMessenger: controller.binaryMessenger
      )

      audioSessionChannel?.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "activateSession":
          do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true, options: [])
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            // 保存当前的 Now Playing 信息
            if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
              self?.lastNowPlayingInfo = info
              NSLog("✅ Saved Now Playing Info: \(info[MPMediaItemPropertyTitle] ?? "Unknown")")
            }
            
            result(nil)
          } catch {
            result(FlutterError(code: "AUDIO_SESSION_ACTIVATE", message: "Failed to activate audio session", details: error.localizedDescription))
          }
        case "deactivateSession":
          do {
            try AVAudioSession.sharedInstance().setActive(false, options: [])
            UIApplication.shared.endReceivingRemoteControlEvents()
            result(nil)
          } catch {
            result(FlutterError(code: "AUDIO_SESSION_DEACTIVATE", message: "Failed to deactivate audio session", details: error.localizedDescription))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      
      // 监听 App 生命周期通知
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationDidBecomeActive),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc private func applicationDidBecomeActive() {
    NSLog("🔄 App became active - restoring audio session and Now Playing info")
    
    // 重新激活 Audio Session
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setActive(true, options: [])
      UIApplication.shared.beginReceivingRemoteControlEvents()
      NSLog("✅ Audio session reactivated")
    } catch {
      NSLog("❌ Failed to reactivate audio session: \(error)")
    }
    
    // 关键：通知 Flutter 层恢复 Now Playing 信息
    // 延迟一点执行，确保 Flutter 引擎已经准备好
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.audioSessionChannel?.invokeMethod("onAppResumed", arguments: nil)
      NSLog("📱 Notified Flutter to restore Now Playing info")
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
