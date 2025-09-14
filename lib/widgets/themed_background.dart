import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';
import '../utils/theme_utils.dart';

class ThemedBackground extends StatelessWidget {
  final Widget Function(BuildContext context, Color sidebar, Color body, bool isFloat) builder;

  const ThemedBackground({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        Color sidebarBg = ThemeUtils.backgroundColor(context);
        Color bodyBg = ThemeUtils.backgroundColor(context);

        if (["window", "sidebar"].contains(themeProvider.opacityTarget)) {
          sidebarBg = sidebarBg.withValues(alpha: themeProvider.seedAlpha);
        }
        if (["window", "body"].contains(themeProvider.opacityTarget)) {
          bodyBg = bodyBg.withValues(alpha: themeProvider.seedAlpha);
        }

        final isFloat = (themeProvider.opacityTarget == 'sidebar' ||
            themeProvider.seedAlpha > 0.98);

        return builder(context, sidebarBg, bodyBg, isFloat);
      },
    );
  }
}