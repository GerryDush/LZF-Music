import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'package:oklch/oklch.dart';

class PaletteUtils {
  static const List<Color> _fallbackColors = [
    Color(0xFF00C6FB),
    Color(0xFF005BEA),
    Color(0xFFFF1053),
    Color(0xFFFF8D00),
  ];

  static Future<List<Color>> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    return fromBytes(bytes);
  }

  static Future<List<Color>> fromBytes(Uint8List bytes) async {
    final Set<Color> combinedColors = {};

    try {
      final palette = await _paletteFromBytes(bytes);

      final List<PaletteColor?> candidates = [
        palette.lightVibrantColor,
        palette.vibrantColor,
        palette.dominantColor,
        palette.lightMutedColor,
        palette.mutedColor,
      ];

      for (var pc in candidates) {
        if (pc == null) continue;

        final okl = OKLCHColor.fromColor(pc.color);
        okl.lightness = okl.lightness.clamp(0.0, 66);
        combinedColors.add(okl.color);
      }
    } catch (e) {
      debugPrint('Error extracting color from bytes: $e');
    }

    if (combinedColors.isEmpty) {
      combinedColors.addAll(_fallbackColors);
    }

    final list = combinedColors.toList()..shuffle();
    return list.take(6).toList();
  }

  static Future<PaletteGenerator> _paletteFromBytes(Uint8List bytes) async {
    return PaletteGenerator.fromImageProvider(
      MemoryImage(bytes),
      maximumColorCount: 16,
      timeout: const Duration(milliseconds: 3000),
    );
  }
}
