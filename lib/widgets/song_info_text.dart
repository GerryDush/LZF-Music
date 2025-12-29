import 'package:flutter/material.dart';

/// 歌曲信息文本组件
/// 
/// 统一处理歌曲标题、艺术家等文本的显示，支持：
/// - 单行/多行显示
/// - 文本溢出处理
/// - 可选的水平滚动
/// - 点击事件
class SongInfoText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final bool scrollable;
  final VoidCallback? onTap;

  const SongInfoText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.scrollable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (scrollable) {
      textWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: textWidget,
      );
    }

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: textWidget,
        ),
      );
    }

    return textWidget;
  }
}

/// 歌曲标题和艺术家组合组件
class SongTitleAndArtist extends StatelessWidget {
  final String title;
  final String? artist;
  final TextStyle? titleStyle;
  final TextStyle? artistStyle;
  final bool scrollable;
  final VoidCallback? onTap;
  final CrossAxisAlignment alignment;
  final double spacing;

  const SongTitleAndArtist({
    super.key,
    required this.title,
    this.artist,
    this.titleStyle,
    this.artistStyle,
    this.scrollable = false,
    this.onTap,
    this.alignment = CrossAxisAlignment.start,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SongInfoText(
          text: title,
          style: titleStyle ?? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          scrollable: scrollable,
          onTap: onTap,
        ),
        if (artist != null && artist!.isNotEmpty) ...[
          SizedBox(height: spacing),
          SongInfoText(
            text: artist!,
            style: artistStyle ?? TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
            scrollable: scrollable,
            onTap: onTap,
          ),
        ],
      ],
    );
  }
}

/// 带有淡入淡出效果的歌曲信息组件
class AnimatedSongInfo extends StatelessWidget {
  final String title;
  final String? artist;
  final double opacity;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final TextStyle? artistStyle;

  const AnimatedSongInfo({
    super.key,
    required this.title,
    this.artist,
    this.opacity = 1.0,
    this.padding = EdgeInsets.zero,
    this.titleStyle,
    this.artistStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: double.infinity,
        padding: padding,
        child: SongTitleAndArtist(
          title: title,
          artist: artist,
          titleStyle: titleStyle,
          artistStyle: artistStyle,
        ),
      ),
    );
  }
}
