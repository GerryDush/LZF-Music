import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

// 歌词行数据模型
class LyricLine {
  final int timeInMs;
  final String text;
  final Duration timestamp;

  LyricLine({required this.timeInMs, required this.text})
    : timestamp = Duration(milliseconds: timeInMs);
}

// 改进的歌词解析器
class LyricsParser {
  // 解析LRC格式歌词（支持双语歌词）
  static List<LyricLine> parseLRC(String lrcContent) {
    final Map<int, List<String>> timeToTexts = {};
    final lines = lrcContent.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 匹配时间戳格式 [mm:ss.x] 或 [mm:ss.xx] 或 [mm:ss]
      final timeMatch = RegExp(
        r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]',
      ).firstMatch(line);

      if (timeMatch != null) {
        final minutes = int.parse(timeMatch.group(1)!);
        final seconds = int.parse(timeMatch.group(2)!);
        String? millisecondsStr = timeMatch.group(3);

        int milliseconds = 0;
        if (millisecondsStr != null) {
          // 处理不同长度的毫秒数
          if (millisecondsStr.length == 1) {
            milliseconds = int.parse(millisecondsStr) * 100;
          } else if (millisecondsStr.length == 2) {
            milliseconds = int.parse(millisecondsStr) * 10;
          } else {
            milliseconds = int.parse(millisecondsStr.substring(0, 3));
          }
        }

        final timeInMs = (minutes * 60 + seconds) * 1000 + milliseconds;
        final text = line.substring(timeMatch.end).trim();

        // 如果text不为空，添加到对应时间点
        if (text.isNotEmpty) {
          if (!timeToTexts.containsKey(timeInMs)) {
            timeToTexts[timeInMs] = [];
          }
          timeToTexts[timeInMs]!.add(text);
        }
      }
    }

    // 转换为LyricLine列表，合并同一时间点的多行歌词
    final List<LyricLine> lyrics = [];
    final sortedTimes = timeToTexts.keys.toList()..sort();

    for (int timeInMs in sortedTimes) {
      final texts = timeToTexts[timeInMs]!;
      // 用换行符连接同一时间点的多行歌词（如原文+翻译）
      final combinedText = texts.join('\n');
      lyrics.add(LyricLine(timeInMs: timeInMs, text: combinedText));
    }

    return lyrics;
  }

  // 简单文本格式解析（保留所有行，包括空行）
  static List<LyricLine> parseSimple(String content, Duration totalDuration) {
    final lines = content.split('\n'); // 不过滤空行
    if (lines.isEmpty) return [];

    final List<LyricLine> lyrics = [];
    final intervalMs = totalDuration.inMilliseconds > 0
        ? totalDuration.inMilliseconds ~/ lines.length
        : 3000; // 默认3秒一行

    for (int i = 0; i < lines.length; i++) {
      lyrics.add(
        LyricLine(
          timeInMs: i * intervalMs,
          text: lines[i], // 保留原始文本，包括空行
        ),
      );
    }

    return lyrics;
  }
}


// 歌词数据处理器类
class LyricsDataProcessor {
  // 处理歌词数据并返回处理结果
  static LyricsProcessResult processLyricsData({
    required String? lyricsContent,
    required Duration totalDuration,
    required Duration currentPosition,
    required List<LyricLine> parsedLyrics,
    int syncOffset = 500, // 歌词同步偏移量（毫秒）
    int fallbackInterval = 3, // 无时间戳歌词的默认间隔（秒）
  }) {
    // 解析歌词
    LyricsManager.parseLyrics(lyricsContent, totalDuration, parsedLyrics);

    // 计算当前行
    final int currentLine = _calculateCurrentLine(
      parsedLyrics: parsedLyrics,
      currentPosition: currentPosition,
      syncOffset: syncOffset,
      fallbackInterval: fallbackInterval,
      lyricsContent: lyricsContent,
    );

    // 准备显示的歌词列表
    final List<String> lyrics = _prepareLyricsForDisplay(
      parsedLyrics: parsedLyrics,
      lyricsContent: lyricsContent,
    );

    return LyricsProcessResult(
      currentLine: currentLine,
      lyrics: lyrics,
      parsedLyrics: parsedLyrics,
    );
  }

  // 计算当前歌词行
  static int _calculateCurrentLine({
    required List<LyricLine> parsedLyrics,
    required Duration currentPosition,
    required int syncOffset,
    required int fallbackInterval,
    required String? lyricsContent,
  }) {
    if (parsedLyrics.isNotEmpty) {
      return LyricsManager.getCurrentLyricIndex(
        parsedLyrics,
        currentPosition.inMilliseconds + syncOffset,
      );
    } else {
      // 回退到基于时间的简单计算
      final totalLines = lyricsContent?.split('\n').length ?? 1;
      return (currentPosition.inSeconds / fallbackInterval)
          .floor()
          .clamp(0, totalLines - 1);
    }
  }

  // 准备用于显示的歌词列表
  static List<String> _prepareLyricsForDisplay({
    required List<LyricLine> parsedLyrics,
    required String? lyricsContent,
  }) {
    if (parsedLyrics.isNotEmpty) {
      return parsedLyrics.map((line) => line.text).toList();
    } else {
      return lyricsContent?.split('\n') ?? ["暂无歌词"];
    }
  }
}

// 歌词处理结果类
class LyricsProcessResult {
  final int currentLine;
  final List<String> lyrics;
  final List<LyricLine> parsedLyrics;

  LyricsProcessResult({
    required this.currentLine,
    required this.lyrics,
    required this.parsedLyrics,
  });
}

// 歌词管理器类
class LyricsManager {
  // 解析歌词方法
  static void parseLyrics(
    String? lyricsContent, 
    Duration totalDuration, 
    List<LyricLine> parsedLyrics,
  ) {
    parsedLyrics.clear();
    if (lyricsContent == null || lyricsContent.isEmpty) {
      return;
    }

    // 检查是否为LRC格式
    if (lyricsContent.contains(RegExp(r'\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]'))) {
      parsedLyrics.addAll(LyricsParser.parseLRC(lyricsContent));
    } else {
      parsedLyrics.addAll(LyricsParser.parseSimple(lyricsContent, totalDuration));
    }
  }

  // 获取当前歌词索引
  static int getCurrentLyricIndex(List<LyricLine> parsedLyrics, int currentPositionMs) {
    if (parsedLyrics.isEmpty) return -1;

    for (int i = parsedLyrics.length - 1; i >= 0; i--) {
      if (currentPositionMs >= parsedLyrics[i].timeInMs) {
        return i;
      }
    }
    return 0;
  }
}

// 歌词工具类
class LyricsUtils {
  // 滚动到当前歌词行
  static void scrollToCurrentLine(
    ScrollController controller,
    int currentLine,
    int highlightIndex,
    Map<int, double> lineHeights,
    double placeholderHeight, {
    bool force = false,
    bool isHoveringLyrics = false,
  }) {
    if (isHoveringLyrics && !force) return;

    double highlightLineOffset =
        lineHeights[highlightIndex - 1] ?? placeholderHeight;

    double offsetUpToCurrent = 0;
    for (int i = 0; i < currentLine; i++) {
      offsetUpToCurrent += lineHeights[i] ?? placeholderHeight;
    }

    double targetOffset = offsetUpToCurrent - highlightLineOffset;
    if (targetOffset < 0) targetOffset = 0;

    final maxScroll = controller.position.hasContentDimensions
        ? controller.position.maxScrollExtent
        : 10000.0;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: const Cubic(0.46, 1.2, 0.43, 1.04),
    );
  }
}

// 测量Widget尺寸的工具类
typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({Key? key, required this.onChange, required this.child})
    : super(key: key);

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contextSize = context.size;
      if (contextSize != null && oldSize != contextSize) {
        oldSize = contextSize;
        widget.onChange(contextSize);
      }
    });

    return widget.child;
  }
}

// 可交互的歌词行组件
class HoverableLyricLine extends StatefulWidget {
  final String text;
  final bool isCurrent;
  final Function(Size) onSizeChange;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;

  const HoverableLyricLine({
    super.key,
    required this.text,
    required this.isCurrent,
    required this.onSizeChange,
    this.onTap,
    this.onHoverChanged,
  });

  @override
  State<HoverableLyricLine> createState() => _HoverableLyricLineState();
}

class _HoverableLyricLineState extends State<HoverableLyricLine> {
  bool isHovered = false;

  void _updateHover(bool hover) {
    if (isHovered != hover) {
      setState(() => isHovered = hover);
      // 添加调试输出
      print('歌词悬停状态改变: $hover');
      if (widget.onHoverChanged != null) {
        widget.onHoverChanged!(hover);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.text.trim().isEmpty;

    return MeasureSize(
      onChange: widget.onSizeChange,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _updateHover(true),
        onExit: (_) => _updateHover(false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: widget.isCurrent ? 0 : 2.5,
              end: (widget.isCurrent || isHovered) ? 0 : 2.5,
            ),
            duration: const Duration(milliseconds: 250),
            builder: (context, blurValue, child) {
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: isHovered
                      ? Colors.white.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurValue,
                    sigmaY: blurValue,
                  ),
                  child: child,
                ),
              );
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: widget.isCurrent ? 1.0 : 0.95,
                end: widget.isCurrent ? 1.0 : 0.95,
              ),
              duration: const Duration(milliseconds: 800),
              curve: const Cubic(0.46, 1.2, 0.43, 1.04),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft, // 保持左对齐缩放
                  child: child,
                );
              },
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 36,
                  color: widget.isCurrent ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  isEmpty ? " " : widget.text,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 歌词列表构建器类
class LyricsListItemBuilder {
  // 构建歌词列表项的回调参数
  static Widget buildItem({
    required BuildContext context,
    required int index,
    required List<String> lyrics,
    required int currentLine,
    required double placeholderHeight,
    required Map<int, double> lineHeights,
    required List<LyricLine> parsedLyrics,
    required int Function() getLastCurrentIndex,
    required void Function(int) setLastCurrentIndex,
    required void Function() setState,
    required void Function(bool) setHoveringState,
    required ScrollController scrollController,
    required bool isHoveringLyrics,
    required dynamic playerProvider,
  }) {
    // 顶部占位空间
    if (index == 0) {
      return SizedBox(height: placeholderHeight);
    }
    
    int i = index - 1;
    
    // 歌词行
    if (i < lyrics.length) {
      return LyricLineBuilder.buildLyricLine(
        lyrics[i],
        i == currentLine,
        i,
        lineHeights,
        (idx) => _handleLyricTap(
          idx: idx,
          parsedLyrics: parsedLyrics,
          getLastCurrentIndex: getLastCurrentIndex,
          setLastCurrentIndex: setLastCurrentIndex,
          playerProvider: playerProvider,
          scrollController: scrollController,
          lineHeights: lineHeights,
          placeholderHeight: placeholderHeight,
          isHoveringLyrics: isHoveringLyrics,
        ),
        (hover) => setHoveringState(hover),
        () => setState(),
      );
    } else {
      // 底部占位空间
      return const SizedBox(height: 500);
    }
  }

  // 处理歌词行点击事件
  static void _handleLyricTap({
    required int idx,
    required List<LyricLine> parsedLyrics,
    required int Function() getLastCurrentIndex,
    required void Function(int) setLastCurrentIndex,
    required dynamic playerProvider,
    required ScrollController scrollController,
    required Map<int, double> lineHeights,
    required double placeholderHeight,
    required bool isHoveringLyrics,
  }) {
    // 精确跳转逻辑 - 点击哪行就跳到哪行
    if (parsedLyrics.isNotEmpty && idx < parsedLyrics.length) {
      // 立即更新当前行索引，避免短暂滚动到上一条
      setLastCurrentIndex(idx);
      // 直接跳转到点击行的精确时间
      playerProvider.seekTo(parsedLyrics[idx].timestamp);
    } else {
      // 回退到原有逻辑
      setLastCurrentIndex(idx);
      playerProvider.seekTo(Duration(seconds: idx * 3));
    }
    
    LyricsUtils.scrollToCurrentLine(
      scrollController,
      idx,
      0,
      lineHeights,
      placeholderHeight,
      force: true,
      isHoveringLyrics: isHoveringLyrics,
    );
  }
}

// 歌词行构建工具类
class LyricLineBuilder {
  static Widget buildLyricLine(
    String text,
    bool isCurrent,
    int index,
    Map<int, double> lineHeights,
    void Function(int) onTap,
    void Function(bool) onHoverChanged,
    void Function() setState,
  ) {
    return HoverableLyricLine(
      text: text,
      isCurrent: isCurrent,
      onSizeChange: (size) {
        if (lineHeights[index] != size.height) {
          setState();
          lineHeights[index] = size.height;
        }
      },
      onTap: () => onTap(index),
      onHoverChanged: onHoverChanged,
    );
  }
}

// 自定义滚动行为
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
  
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}