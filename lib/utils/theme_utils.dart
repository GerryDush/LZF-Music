import 'package:flutter/material.dart';

class ThemeUtils {
  ThemeUtils._();

  static const Color lightBg = Color(0xffededed);
  static const Color darkBg = Color(0xff1e1c23);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static bool isLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  static T select<T>(
    BuildContext context, {
    required T light,
    required T dark,
  }) {
    return isDark(context) ? dark : light;
  }

  static Color backgroundColor(BuildContext context) {
    return select(context, light: lightBg, dark: darkBg);
  }

  /// 获取主题主色（Primary Color）
  static Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取次要颜色（Secondary）
  static Color secondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// 获取文本主色（根据亮/暗模式自动切换）
  static Color textColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  /// 获取错误颜色
  static Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}
