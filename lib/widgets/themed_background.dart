import 'package:flutter/material.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';
import '../utils/theme_utils.dart';

class ThemedBackgroundData {
  final Color primaryColor;
  final Color sidebarBg;
  final Color bodyBg;
  final bool isFloat;
  final bool sidebarIsExtended;
  final AppThemeProvider themeProvider;

  const ThemedBackgroundData({
    required this.primaryColor,
    required this.sidebarBg,
    required this.bodyBg,
    required this.isFloat,
    required this.sidebarIsExtended,
    required this.themeProvider,
  });
}

class ThemedBackground extends StatelessWidget {
  final Widget Function(BuildContext context, ThemedBackgroundData data)
  builder;

  const ThemedBackground({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        Color primaryColor = ThemeUtils.primaryColor(context);
        Color sidebarBg = ThemeUtils.backgroundColor(context);
        Color bodyBg = ThemeUtils.backgroundColor(context);

        if (PlatformUtils.isMobile || PlatformUtils.isMobileWidth(context)) {
          return builder(
            context,
            ThemedBackgroundData(
              primaryColor: primaryColor,
              sidebarBg: sidebarBg,
              bodyBg: bodyBg,
              isFloat: true,
              sidebarIsExtended: false,
              themeProvider: themeProvider,
            ),
          );
        }

        if (["window", "sidebar"].contains(themeProvider.opacityTarget)) {
          sidebarBg = sidebarBg.withValues(alpha: themeProvider.seedAlpha);
        }
        if (["window", "body"].contains(themeProvider.opacityTarget)) {
          bodyBg = bodyBg.withValues(alpha: themeProvider.seedAlpha);
        }

        final isFloat =
            (themeProvider.opacityTarget == 'sidebar' ||
            themeProvider.seedAlpha > 0.98);

        return builder(
          context,
          ThemedBackgroundData(
            primaryColor: primaryColor,
            sidebarBg: sidebarBg,
            bodyBg: bodyBg,
            isFloat: isFloat,
            sidebarIsExtended: themeProvider.sidebarIsExtended,
            themeProvider: themeProvider,
          ),
        );
      },
    );
  }
}
