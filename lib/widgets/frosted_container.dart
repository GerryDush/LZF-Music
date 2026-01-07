import 'package:flutter/material.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'dart:ui';
import '../utils/theme_utils.dart';

class FrostedContainer extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Color? backgroundColor;

  const FrostedContainer({
    super.key,
    required this.child,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled && PlatformUtils.isDesktop) return  CommonUtils.select(backgroundColor==null, t: child, f: Container(decoration: BoxDecoration(color: backgroundColor),child: child,));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: (backgroundColor ?? ThemeUtils.backgroundColor(context))
                .withValues(alpha: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }
}
