import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let audioSessionChannel = FlutterMethodChannel(
        name: "com.lzf.music/audio_session",
        binaryMessenger: controller.binaryMessenger
      )

      audioSessionChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "activateSession":
          do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try session.setActive(true, options: [])
            UIApplication.shared.beginReceivingRemoteControlEvents()
            if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
              MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
