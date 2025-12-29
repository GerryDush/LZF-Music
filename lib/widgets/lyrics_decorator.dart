import 'dart:ui';
import 'package:flutter/material.dart';

/// 歌词视图装饰器
/// 
/// 为歌词视图添加渐变遮罩效果，统一处理顶部和底部的渐变淡出
class LyricsDecorator extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool enableGradient;
  final List<double> gradientStops;
  final List<Color> gradientColors;
  final bool enableBlur;
  final double blurAmount;

  const LyricsDecorator({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.only(top: 100.0, bottom: 210.0),
    this.enableGradient = true,
    this.gradientStops = const [0.0, 0.1, 0.9, 1.0],
    this.gradientColors = const [
      Colors.transparent,
      Colors.black,
      Colors.black,
      Colors.transparent
    ],
    this.enableBlur = false,
    this.blurAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // 添加模糊效果
    if (enableBlur && blurAmount > 0) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
          tileMode: TileMode.decal,
        ),
        child: content,
      );
    }

    // 添加渐变遮罩
    if (enableGradient) {
      content = ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: gradientStops,
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    // 添加 padding
    if (padding != EdgeInsets.zero) {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    return Center(child: content);
  }
}

/// 动画版本的歌词装饰器
/// 支持动态调整模糊程度和padding
class AnimatedLyricsDecorator extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blurAmount;
  final bool visible;

  const AnimatedLyricsDecorator({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.only(top: 88, bottom: 184.0),
    this.blurAmount = 0.0,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: LyricsDecorator(
          padding: EdgeInsets.zero,
          enableBlur: blurAmount > 0,
          blurAmount: blurAmount,
          child: child,
        ),
      ),
    );
  }
}
