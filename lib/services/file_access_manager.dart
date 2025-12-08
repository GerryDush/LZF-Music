import 'package:flutter/services.dart';
import 'package:lzf_music/utils/platform_utils.dart';

class FileAccessManager {
  static const MethodChannel _channel =
      MethodChannel('com.lzf_music/secure_bookmarks');

  /// 为文件路径创建持久化访问书签 (支持 iOS & macOS)
  /// [filePath] 原始文件路径
  /// 返回: Base64 编码的书签字符串
  static Future<String?> createBookmark(String filePath) async {
    if (!PlatformUtils.isMacOS && !PlatformUtils.isIOS) return null;

    try {
      final String? bookmark =
          await _channel.invokeMethod('createBookmark', {'path': filePath});
      return bookmark;
    } catch (e) {
      print('[FileAccessManager] 创建书签失败: $e');
      return null;
    }
  }

  /// 解析并开始访问 (支持 iOS & macOS)
  /// [bookmark] Base64 编码的书签
  /// 返回: 解析后的真实文件路径
  static Future<String?> startAccessing(String bookmark) async {
    if (!PlatformUtils.isMacOS && !PlatformUtils.isIOS) return null;

    try {
      final String? resolvedPath =
          await _channel.invokeMethod('startAccessing', {'bookmark': bookmark});
      return resolvedPath;
    } catch (e) {
      print('[FileAccessManager] 解析书签失败: $e');
      return null;
    }
  }

  /// 停止访问 (释放资源)
  static Future<void> stopAccessing(String bookmark) async {
    if (!PlatformUtils.isMacOS && !PlatformUtils.isIOS) return;

    try {
      await _channel.invokeMethod('stopAccessing', {'bookmark': bookmark});
    } catch (e) {
      print('[FileAccessManager] 停止访问失败: $e');
    }
  }
}
