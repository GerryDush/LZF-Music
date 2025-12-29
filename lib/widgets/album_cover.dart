import 'dart:io';
import 'package:flutter/material.dart';

/// 通用的专辑封面组件
/// 
/// 统一处理封面图片显示逻辑：
/// - 如果有封面路径且文件存在，显示图片
/// - 否则显示默认的音乐图标
class AlbumCover extends StatelessWidget {
  /// 封面图片路径（可以是完整路径或缩略图路径）
  final String? coverPath;
  
  /// 封面尺寸（宽度和高度相同）
  final double size;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 默认图标大小（当没有封面时显示）
  final double? iconSize;
  
  /// 默认图标颜色
  final Color? iconColor;
  
  /// 背景颜色（当没有封面时显示）
  final Color? backgroundColor;
  
  /// 图片适配方式
  final BoxFit fit;
  
  /// 缓存宽度（用于优化内存）
  final int? cacheWidth;
  
  /// 缓存高度（用于优化内存）
  final int? cacheHeight;
  
  /// 是否显示动画效果（播放状态）
  final bool isPlaying;
  
  /// 播放状态下的缩放比例
  final double playingScale;
  
  /// 暂停状态下的缩放比例
  final double pausedScale;
  
  /// 播放状态下的透明度
  final double playingOpacity;
  
  /// 暂停状态下的透明度
  final double pausedOpacity;

  const AlbumCover({
    super.key,
    this.coverPath,
    this.size = 50,
    this.borderRadius = 4,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.isPlaying = true,
    this.playingScale = 1.0,
    this.pausedScale = 1.0,
    this.playingOpacity = 1.0,
    this.pausedOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidCover = coverPath != null && File(coverPath!).existsSync();
    final actualIconSize = iconSize ?? size * 0.4;
    final actualBackgroundColor = backgroundColor ?? Colors.grey[800];
    
    Widget coverWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: hasValidCover
          ? Image.file(
              File(coverPath!),
              width: size,
              height: size,
              fit: fit,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
            )
          : Container(
              width: size,
              height: size,
              color: actualBackgroundColor,
              child: Icon(
                Icons.music_note_rounded,
                color: iconColor ?? Colors.white,
                size: actualIconSize,
              ),
            ),
    );
    
    // 如果有播放动画效果
    if (playingScale != 1.0 || pausedScale != 1.0 || 
        playingOpacity != 1.0 || pausedOpacity != 1.0) {
      return AnimatedScale(
        scale: isPlaying ? playingScale : pausedScale,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: isPlaying ? playingOpacity : pausedOpacity,
          duration: const Duration(milliseconds: 300),
          child: coverWidget,
        ),
      );
    }
    
    return coverWidget;
  }
}

/// 简化版本：小尺寸圆形封面（用于 mini player）
class RoundAlbumCover extends StatelessWidget {
  final String? coverPath;
  final double size;
  final double? iconSize;

  const RoundAlbumCover({
    super.key,
    this.coverPath,
    this.size = 40,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        image: coverPath != null
            ? DecorationImage(
                image: FileImage(File(coverPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: coverPath == null
          ? Icon(Icons.music_note_rounded, size: iconSize ?? 24)
          : null,
    );
  }
}
