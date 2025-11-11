import 'package:flutter/services.dart';

class NativeTabBarController {
  static const MethodChannel _channel = MethodChannel('native_tab_bar');

  /// 隐藏 TabBar
  static Future<void> hide() async {
    try {
      await _channel.invokeMethod('setTabBarHidden', true);
    } on PlatformException catch (e) {
      print('Failed to hide TabBar: $e');
    }
  }

  /// 显示 TabBar
  static Future<void> show() async {
    try {
      await _channel.invokeMethod('setTabBarHidden', false);
    } on PlatformException catch (e) {
      print('Failed to show TabBar: $e');
    }
  }

  /// 切换 Tab
  static Future<void> selectTab(int index) async {
    try {
      await _channel.invokeMethod('selectTab', index);
    } on PlatformException catch (e) {
      print('Failed to select Tab $index: $e');
    }
  }

  /// 监听回调事件
  static void setEventHandler({
    void Function(int index) ?onTabSelected,
    void Function(bool visible) ?onVisibilityChanged,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTabSelected':
          if (call.arguments is int) onTabSelected?.call(call.arguments);
          break;
        case 'onTabBarVisibilityChanged':
          if (call.arguments is bool) onVisibilityChanged?.call(call.arguments);
          break;
      }
    });
  }
}