import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image/image.dart' as img;

class LiquidGeneratorPage extends StatefulWidget {
  final List<Color> liquidColors;

  const LiquidGeneratorPage({
    super.key,
    List<Color>? liquidColors,
  }) : liquidColors = liquidColors??const [
          Color(0xFF00C6FB),
          Color(0xFF005BEA),
          Color(0xFFFF1053),
          Color(0xFFFF8D00),
        ];

  @override
  State<LiquidGeneratorPage> createState() => _LiquidGeneratorPageState();
}

class _LiquidGeneratorPageState extends State<LiquidGeneratorPage>
    with SingleTickerProviderStateMixin {
  

  late AnimationController _controller;
  bool _isExtractingColors = false;
  bool _isGeneratingGif = false;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    // 统一设置为 6 秒，与下方 GIF 生成时长保持一致，确保完美循环
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: LiquidGradientPainter(
            colors: widget.liquidColors,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }


  // ==========================================
  // 修改点 1：只提取鲜艳颜色，并进行暴力增强
  // ==========================================
  


  Future<void> _generateGif() async {
    setState(() => _isGeneratingGif = true);

    try {
      // 【建议修改】GIF 60帧/20秒会让内存爆炸(1200帧)。
      // 建议：FPS 改为 20-24，时长 6-10秒即可保持流畅且不崩。
      const int fps = 24;
      const int durationSec = 6;
      const int totalFrames = fps * durationSec;
      const int exportSize = 500;

      img.Image? rootImage;

      for (int i = 0; i < totalFrames; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        double progress = i / totalFrames;

        final painter = LiquidGradientPainter(
          colors: widget.liquidColors,
          progress: progress,
        );

        // 绘制一帧
        painter.paint(
          canvas,
          Size(exportSize.toDouble(), exportSize.toDouble()),
        );

        // 结束录制
        final picture = recorder.endRecording();

        // 转为图片
        final imgObj = await picture.toImage(exportSize, exportSize);
        final byteData = await imgObj.toByteData(
          format: ui.ImageByteFormat.png,
        );

        // 【内存优化】及时释放 GPU 资源，防止由 picture 堆积导致的 crash
        picture.dispose();
        imgObj.dispose();

        if (byteData != null) {
          final frameImg = img.decodePng(byteData.buffer.asUint8List());
          if (frameImg != null) {
            // image v4 API: frameDuration 单位是毫秒
            frameImg.frameDuration = (1000 / fps).round();

            if (rootImage == null) {
              rootImage = frameImg;
            } else {
              rootImage.addFrame(frameImg);
            }
          }
        }
      }

      if (rootImage != null) {
        // 编码 GIF (这是一个耗时且耗内存的操作)
        final gifBytes = img.encodeGif(rootImage);

        final dir = await getApplicationDocumentsDirectory();
        final saveFile = File(
          '${dir.path}/liquid_bright_${DateTime.now().millisecondsSinceEpoch}.gif',
        );
        await saveFile.writeAsBytes(gifBytes);

        if (mounted) setState(() => _savedPath = saveFile.path);
      }
    } catch (e) {
      debugPrint("GIF生成错误: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingGif = false);
    }
  }
}

// ==========================================
// 核心绘制器 (无噪点版)
// ==========================================
class LiquidGradientPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;

  LiquidGradientPainter({required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制底色
    // 【优化】：不再简单混合，而是使用第一个颜色的“深色浓郁版”作为背景
    // 这样能形成 "深色背景 + 亮色流体" 的发光感，而不是灰蒙蒙的一片
    final Paint bgPaint = Paint()..color = _getDeepBackground();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. 绘制流体 Blob
    final int blobCount = max(colors.length, 5);

    for (int i = 0; i < blobCount; i++) {
      final color = colors[i % colors.length];
      _drawFluidBlob(canvas, size, i, blobCount, color);
    }
  }

  Color _getDeepBackground() {
    if (colors.isEmpty) return const Color(0xFF101018);
    // 取第一个颜色的极深版本 (Hue保持，Sat高，Val低)
    return HSVColor.fromColor(
      colors[0],
    ).withValue(0.15).withSaturation(0.9).toColor();
  }

  void _drawFluidBlob(
    Canvas canvas,
    Size size,
    int index,
    int total,
    Color color,
  ) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.8) // 稍微提高透明度让颜色更实
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // 完美循环算法
    final double angle = 2 * pi * progress;
    final double speedX = (index % 3) + 1.0;
    final double speedY = (index % 2) + 1.0;
    final double phase = index * (2 * pi / total);

    final double moveX = sin(angle * speedX + phase);
    final double moveY = cos(angle * speedY + phase);

    final double centerX = size.width / 2 + moveX * (size.width * 0.4);
    final double centerY = size.height / 2 + moveY * (size.height * 0.4);

    final double baseRadius = size.shortestSide * 0.5;
    final double radiusBreath = sin(angle * 2 + index) * (baseRadius * 0.15);
    final double radius = baseRadius + radiusBreath;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGradientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}

Future<List<Color>> extractColorsFromImages(List<File> images) async {
    final Set<Color> combinedColors = {};
    for (var file in images) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          FileImage(file),
          maximumColorCount: 16,
          timeout: const Duration(milliseconds: 800),
        );

        // 优先取最鲜艳的颜色
        final List<PaletteColor?> candidates = [
          palette.lightVibrantColor,
          palette.vibrantColor,
          palette.dominantColor,
          palette.lightMutedColor,
          palette.mutedColor,
        ];

        for (var pc in candidates) {
          if (pc == null) continue;

          // 【核心】颜色增强：让颜色变亮、变饱和
          final Color boosted = _boostVibrancy(pc.color);

          // 过滤掉仍然是灰黑色的脏色
          if (!_isDull(boosted)) {
            combinedColors.add(boosted);
          }
        }
      } catch (e) {
        debugPrint("Error extracting color: $e");
      }
    }

    // 兜底：如果没提取出颜色（比如全黑白图），补几个霓虹色
    if (combinedColors.length < 2) {
      combinedColors.addAll([
        const Color(0xFF00C6FB),
        const Color(0xFF005BEA),
        const Color(0xFFFF1053),
        const Color(0xFFFF8D00),
      ]);
    }

    var list = combinedColors.toList();
    if (list.length > 6) {
      list.shuffle();
      list = list.take(6).toList();
    } else {
      list.shuffle();
    }
    return combinedColors.toList();
  }

  // 辅助函数：HSV 增强算法
  Color _boostVibrancy(Color color) {
    final hsv = HSVColor.fromColor(color);

    // 饱和度提升 50%，最低不低于 0.6 (0.0-1.0)
    double newS = (hsv.saturation * 1.5).clamp(0.6, 1.0);

    // 亮度提升 20%，最低不低于 0.8 (保证明亮)
    double newV = (hsv.value * 1.2).clamp(0.8, 1.0);

    // 特殊处理：极浅色（接近白）保持高亮
    if (hsv.value > 0.9 && hsv.saturation < 0.2) {
      newS = 0.2;
      newV = 1.0;
    }

    return hsv.withSaturation(newS).withValue(newV).toColor();
  }

  // 辅助函数：判断是否是脏色
  bool _isDull(Color color) {
    final hsv = HSVColor.fromColor(color);
    return (hsv.saturation < 0.3 && hsv.value < 0.3) || hsv.value < 0.2;
  }