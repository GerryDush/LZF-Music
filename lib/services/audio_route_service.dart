import 'package:flutter/services.dart';
import 'dart:io';

/// 音频路由服务
/// iOS: 显示 AirPlay 选择器
/// Android: 显示音频输出选择器
class AudioRouteService {
  static const MethodChannel _channel = MethodChannel('com.lzf.music/audio_route');

  /// 显示音频路由选择器
  /// iOS: AirPlay picker
  /// Android: Audio output selector
  static Future<void> showAudioRoutePicker() async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('showAirPlayPicker');
      } else if (Platform.isAndroid) {
        await _channel.invokeMethod('showAudioOutputPicker');
      }
    } on PlatformException catch (e) {
      print("Failed to show audio route picker: ${e.message}");
    }
  }
}
