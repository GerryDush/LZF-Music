import 'dart:io';
import 'package:flutter/material.dart';

class AnimatedAlbumCover extends StatelessWidget {
  final String? albumArtPath;
  final String title;
  final String? artist;
  final bool isPlaying;
  final double animationProgress; // 0.0 = 大封面模式, 1.0 = 小封面模式
  final double smallCoverSize;
  final double largeCoverBorderRadius;
  final double smallCoverBorderRadius;
  final double smallCoverLeft;
  final double smallCoverTop;

  const AnimatedAlbumCover({
    Key? key,
    required this.albumArtPath,
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.animationProgress,
    this.smallCoverSize = 56.0,
    this.largeCoverBorderRadius = 20.0,
    this.smallCoverBorderRadius = 20.0,
    this.smallCoverLeft = 2.0,
    this.smallCoverTop = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final largeCoverSize = screenWidth;
        
        // 计算大封面的中心位置
        final largeCoverCenterX = screenWidth / 2;
        final largeCoverCenterY = largeCoverSize / 2;
        
        // 小封面的目标位置（左上角）
        final smallCoverCenterX = smallCoverLeft + smallCoverSize / 2;
        final smallCoverCenterY = smallCoverTop + smallCoverSize / 2;
        
        // 计算位移（从中心点到中心点）
        final deltaX = smallCoverCenterX - largeCoverCenterX;
        final deltaY = smallCoverCenterY - largeCoverCenterY;
        
        final t = animationProgress;
        
        return Stack(
          children: [
            // 封面图片
            _buildCoverImage(
              largeCoverSize: largeCoverSize,
              deltaX: deltaX,
              deltaY: deltaY,
              t: t,
            ),
            
            // 歌曲信息（仅在小封面模式时显示）
            _buildSongInfo(t),
          ],
        );
      },
    );
  }

  Widget _buildCoverImage({
    required double largeCoverSize,
    required double deltaX,
    required double deltaY,
    required double t,
  }) {
    final targetScale = smallCoverSize / largeCoverSize;
    
    // 基础缩放（歌词模式切换）
    final baseScale = 1.0 + (targetScale - 1.0) * t;
    
    final opacity = isPlaying ? 1.0 : 0.8;
    final offsetX = deltaX * t;
    final offsetY = deltaY * t;
    
    // 阴影强度：播放时更强，暂停时变浅
    final shadowOpacity = isPlaying ? 0.5 : 0.2;
    final shadowBlur = isPlaying ? 30.0 : 15.0;
    
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.scale(
        scale: baseScale,
        alignment: Alignment.center,
        child: Center(
          child: AnimatedScale(
            scale: isPlaying ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    largeCoverBorderRadius + (smallCoverBorderRadius - largeCoverBorderRadius) * t,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(shadowOpacity),
                      blurRadius: shadowBlur,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    largeCoverBorderRadius + (smallCoverBorderRadius - largeCoverBorderRadius) * t,
                  ),
                  child: albumArtPath != null && File(albumArtPath!).existsSync()
                      ? Image.file(
                          File(albumArtPath!),
                          width: largeCoverSize,
                          height: largeCoverSize,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: largeCoverSize,
                          height: largeCoverSize,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(double t) {
    if (t < 0.3) {
      return const SizedBox.shrink();
    }
    
    return Opacity(
      opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(left: 0 + smallCoverSize + 12, top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              artist ?? '未知艺术家',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
