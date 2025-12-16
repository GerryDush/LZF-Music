import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LiquidGeneratorPage extends StatefulWidget {
  final List<Color> liquidColors;
  final bool isPlaying;
  final Duration speed;

  const LiquidGeneratorPage({
    super.key,
    List<Color>? liquidColors,
    this.isPlaying = true,
    this.speed = const Duration(seconds: 15),
  }) : liquidColors = liquidColors ??
            const [
              Color(0xFF00C6FB),
              Color(0xFF005BEA),
              Color(0xFFFF1053),
              Color(0xFFFF8D00),
            ];

  @override
  State<LiquidGeneratorPage> createState() => _LiquidGeneratorPageState();
}

class _LiquidGeneratorPageState extends State<LiquidGeneratorPage>
    with TickerProviderStateMixin {
  late AnimationController _loopController;
  late AnimationController _colorTransitionController;

  late List<Color> _oldColors;
  late List<Color> _targetColors;
  
  // 【核心修改 1】定义一个固定的球体数量
  // 选一个由质数组成的稍大数字（如7），可以让颜色分布看起来更随机自然
  // 无论传入多少颜色，屏幕上始终只有 7 个流体球，保证位置不跳变
  static const int _fixedBlobCount = 7;

  @override
  void initState() {
    super.initState();
    _oldColors = widget.liquidColors;
    _targetColors = widget.liquidColors;

    _loopController = AnimationController(
      vsync: this,
      duration: widget.speed,
    );
    if (widget.isPlaying) {
      _loopController.repeat();
    }

    _colorTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2秒平滑过渡
      value: 1.0, 
    );
  }

  @override
  void didUpdateWidget(LiquidGeneratorPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _loopController.repeat();
      } else {
        _loopController.stop();
      }
    }

    if (widget.speed != oldWidget.speed) {
      _loopController.duration = widget.speed;
      if (widget.isPlaying) _loopController.repeat();
    }

    // 处理颜色变化
    if (!_areListsEqual(widget.liquidColors, oldWidget.liquidColors)) {
      // 1. 捕捉当前瞬间的视觉状态作为 "旧颜色"
      // 这里的关键是：_getCurrentMixedColors 返回的永远是长度为 _fixedBlobCount 的列表
      // 所以下一次动画是从当前屏幕上的颜色开始过渡的，绝对丝滑
      _oldColors = _getCurrentMixedColors();
      _targetColors = widget.liquidColors;

      // 2. 重置控制器开始过渡
      _colorTransitionController.forward(from: 0.0);
    }
  }

  bool _areListsEqual(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // 【核心修改 2】生成固定长度的颜色列表
  List<Color> _getCurrentMixedColors() {
    // 即使动画完成了，我们也要重新计算映射，
    // 以防止 targetColors 长度变化导致的索引错位
    final double t = _colorTransitionController.value;
    final List<Color> result = [];

    // 强制生成 _fixedBlobCount 个颜色
    for (int i = 0; i < _fixedBlobCount; i++) {
      // 使用模运算循环取色
      // 比如：旧列表2个色，新列表3个色，球有7个
      // 球1：Lerp(旧[0], 新[0])
      // 球3：Lerp(旧[0], 新[2])  <-- 索引通过取模对齐
      final Color c1 = _oldColors[i % _oldColors.length];
      final Color c2 = _targetColors[i % _targetColors.length];
      
      // 如果处于过渡结束状态，直接添加目标色（优化性能）
      if (_colorTransitionController.isCompleted) {
        result.add(c2);
      } else {
        result.add(Color.lerp(c1, c2, t)!);
      }
    }
    return result;
  }

  @override
  void dispose() {
    _loopController.dispose();
    _colorTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_loopController, _colorTransitionController]),
      builder: (context, child) {
        final List<Color> currentColors = _getCurrentMixedColors();

        return CustomPaint(
          painter: LiquidGradientPainter(
            colors: currentColors, // 这里传入的列表长度永远是 7
            progress: _loopController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class LiquidGradientPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;

  LiquidGradientPainter({required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制底色
    final Paint bgPaint = Paint()..color = _getDominantColor();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. 绘制流体 Blob
    // 【核心修改 3】直接使用列表长度（它现在固定是 7）
    // 不再根据 length 动态计算 max，防止相位(Phase)跳变
    final int blobCount = colors.length;

    for (int i = 0; i < blobCount; i++) {
      final color = colors[i]; // 不需要取模了，因为是一一对应的
      _drawResponsiveBlob(canvas, size, i, blobCount, color);
    }
  }

  Color _getDominantColor() {
    if (colors.isEmpty) return Colors.black;
    // 取前两个球的颜色混合做背景
    final Color mix = Color.alphaBlend(
        colors[0].withOpacity(0.5), colors.length > 1 ? colors[1] : colors[0]);
    
    // 简单压暗背景
    return _adjustColor(mix, saturation: 0.8, value: 0.25);
  }
  
  // 简单的颜色调整辅助函数 (替代 HSVColor 手写逻辑)
  Color _adjustColor(Color c, {double? saturation, double? value}) {
     final hsv = HSVColor.fromColor(c);
     return hsv.withSaturation(saturation ?? hsv.saturation)
               .withValue(value ?? hsv.value)
               .toColor();
  }

  void _drawResponsiveBlob(
    Canvas canvas,
    Size size,
    int index,
    int total,
    Color color,
  ) {
    // 响应式计算
    final double maxSide = max(size.width, size.height);
    final double minSide = min(size.width, size.height);

    // 动态模糊：确保在大屏上看不出圆的边缘
    // 设定为短边的 1/5，足够模糊
    final double blurSigma = minSide * 0.2; 

    final Paint paint = Paint()
      ..color = color.withOpacity(0.65)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    // 运动算法
    final double angle = 2 * pi * progress;
    final double speedX = (index % 3) + 1.0;
    final double speedY = (index % 2) + 1.0;
    // 相位计算依赖于 total。因为我们固定了 total=7，所以这个值永远不变，位置不会跳
    final double phase = index * (2 * pi / total); 

    final double moveX = sin(angle * speedX + phase);
    final double moveY = cos(angle * speedY + phase);

    // 运动范围
    final double centerX = size.width / 2 + moveX * (size.width * 0.45);
    final double centerY = size.height / 2 + moveY * (size.height * 0.45);

    // 动态半径：确保能覆盖大屏幕
    final double baseRadius = maxSide * 0.55;
    final double radiusBreath = sin(angle * 2 + index) * (minSide * 0.1);
    final double radius = baseRadius + radiusBreath;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGradientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}