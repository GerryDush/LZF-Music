import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

// ===============================================================
// 数据模型
// ===============================================================

class LyricLine {
  final List<LyricChar> chars;
  final Duration startTime;
  final Duration endTime;
  LyricLine({
    required this.chars,
    required this.startTime,
    required this.endTime,
  });
}

class LyricChar {
  final String char;
  final Duration start;
  final Duration end;
  LyricChar({required this.char, required this.start, required this.end});
}

// ===============================================================
// 主 Widget: KaraokeLyricsView
// ===============================================================

class KaraokeLyricsView extends StatefulWidget {
  final String? lyricsContent;
  final ValueNotifier<Duration> currentPosition;
  final Function(Duration) onTapLine;

  const KaraokeLyricsView({
    Key? key,
    required this.lyricsContent,
    required this.currentPosition,
    required this.onTapLine,
  }) : super(key: key);

  @override
  State<KaraokeLyricsView> createState() => _KaraokeLyricsViewState();
}

class _KaraokeLyricsViewState extends State<KaraokeLyricsView> {
  List<LyricLine> _lyricLines = [];
  int _currentLineIndex = 0;

  late ScrollController _scrollController;
  final Map<int, double> _lineHeights = {};
  bool _isHoveringLyrics = false;
  final int _highlightLineOffsetIndex = 2; // 滚动到第3行

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parseLyrics();
    widget.currentPosition.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(KaraokeLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lyricsContent != oldWidget.lyricsContent) {
      _parseLyrics();
    }
    // 如果父 Widget 替换了 ValueNotifier，需要重新监听
    if (widget.currentPosition != oldWidget.currentPosition) {
      oldWidget.currentPosition.removeListener(_onPositionChanged);
      widget.currentPosition.addListener(_onPositionChanged);
    }
     
  }

  void _onPositionChanged() {
    // 每次 currentPosition.value 改变都会调用这里
    final pos = widget.currentPosition.value;
    _updateCurrentLine(pos); // 更新高亮歌词
  }

  @override
  void dispose() {
    widget.currentPosition.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // ... 在 _KaraokeLyricsViewState 类中 ...

  Future<void> _parseLyrics() async {
    if (widget.lyricsContent == null || widget.lyricsContent!.trim().isEmpty) {
      if (mounted) setState(() => _lyricLines = []);
      return;
    }

    List<LyricLine> parsed;

    // --- 智能格式检测 ---
    final trimmedLyrics = widget.lyricsContent!.trim();

    // LRC格式通常以时间戳 [mm:ss.xx] 开头
    if (trimmedLyrics.startsWith('<tt')) {
      parsed = await _parseTtmlContent(trimmedLyrics);
    }
    // LRC格式的新检查：不要求时间戳在开头，只要整个文件包含时间戳即可
    else if (RegExp(r'\[\d{2}:\d{2}\.\d{1,3}\]').hasMatch(trimmedLyrics)) {
      parsed = await _parseLrcContent(trimmedLyrics);
    } else {
      // 无法识别格式
      debugPrint("无法识别的歌词格式。");
      parsed = [];
    }
    // --- 检测结束 ---

    if (mounted) {
      setState(() {
        _lyricLines = parsed;
        _currentLineIndex = 0;
        _lineHeights.clear();
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
      // 解析完成后立即更新一次当前行
      _updateCurrentLine(widget.currentPosition.value);
    }
  }

  void _updateCurrentLine(Duration position) {
    if (_lyricLines.isEmpty) return;
    final newIndex = _lyricLines.lastIndexWhere(
      (line) => position >= line.startTime,
    );

    if (newIndex != -1 && newIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = newIndex);
      _scrollToCurrentLine();
    }
  }

  Future<void> _scrollToCurrentLine({bool force = false}) async {
    // 等待 ScrollController 挂载
    while (!_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 16));
    }

    if (_isHoveringLyrics && !force) return;

    double placeholderHeight = MediaQuery.of(context).size.height / 3.5;
    
    double offsetUpToCurrent = 0;
    for (int i = 0; i < _currentLineIndex; i++) {
      offsetUpToCurrent += _lineHeights[i] ?? 80.0;
    }
    double targetOffset =
        placeholderHeight + offsetUpToCurrent - 160;
    targetOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: const Cubic(0.46, 1.2, 0.43, 1.04),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholderHeight = MediaQuery.of(context).size.height / 3.5;
    if (_lyricLines.isEmpty) {
      return const Center(
        child: Text(
          "暂无歌词",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SizedBox(height: placeholderHeight),
            ..._lyricLines.asMap().entries.map((entry) {
              int index = entry.key;
              LyricLine line = entry.value;
              bool isCurrentLine = index == _currentLineIndex;
              return ValueListenableBuilder<Duration>(
                valueListenable: widget.currentPosition,
                builder: (context, position, child) {
                  return HoverableLyricLine(
                    isCurrent: isCurrentLine,
                    onSizeChange: (size) => _lineHeights[index] = size.height,
                    child: _buildLyricLine(line, isCurrentLine, position),
                    onHoverChanged: (hover) {
                      _isHoveringLyrics = hover;
                    },
                    onTap: () {
                      widget.onTapLine(line.startTime);
                      setState(() => _currentLineIndex = index);
                      _scrollToCurrentLine(force: true);
                    },
                  );
                },
              );
            }),
            SizedBox(height: placeholderHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricLine(
    LyricLine line,
    bool isCurrentLine,
    Duration position,
  ) {
    final textStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.4,
      shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
    );

    // --- 核心修正点 ---
    // 当 position 在当前行时间范围之外时...
    if (position < line.startTime || position > line.endTime) {
      // 我们需要精确判断它是“未唱到”还是“已唱完”

      // 如果 position 小于开始时间，说明是“未唱到”，应为暗色
      final Color nonActiveColor = Colors.white70;

      // 只有当 position 大于结束时间时，才是“已唱完”，应为亮色
      final Color color = (position > line.endTime)
          ? Colors.white
          : nonActiveColor;

      return Wrap(
        children: line.chars
            .map((c) => Text(c.char, style: textStyle.copyWith(color: color)))
            .toList(),
      );
    }
    // --- 修正结束 ---

    final List<double> charWidths = [], charOffsets = [];
    double currentOffset = 0.0;
    for (final lyricChar in line.chars) {
      final painter = TextPainter(
        text: TextSpan(text: lyricChar.char, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      charWidths.add(painter.width);
      charOffsets.add(currentOffset);
      currentOffset += painter.width;
    }
    final totalWidth = currentOffset > 0 ? currentOffset : 1.0;
    final lineDuration =
        line.endTime.inMilliseconds - line.startTime.inMilliseconds;
    final lineProgressRatio = lineDuration > 0
        ? (position.inMilliseconds - line.startTime.inMilliseconds) /
              lineDuration
        : 0.0;
    final progressInPixels = totalWidth * lineProgressRatio;
    final transitionWidthPixels = 20.0;
    final gradientStart = progressInPixels;
    final gradientEnd = progressInPixels + transitionWidthPixels;
    final charWidgets = <Widget>[];
    for (int i = 0; i < line.chars.length; i++) {
      final charStartOffset = charOffsets[i],
          charEndOffset = charStartOffset + charWidths[i];
      final shaderMaskedChar = ShaderMask(
        shaderCallback: (rect) {
          if (charEndOffset <= gradientStart)
            return const LinearGradient(
              colors: [Colors.white, Colors.white],
            ).createShader(rect);
          if (charStartOffset >= gradientEnd)
            return LinearGradient(
              colors: [Colors.white70, Colors.white70],
            ).createShader(rect);
          final localGradientStart =
                  (gradientStart - charStartOffset) / rect.width,
              localGradientEnd = (gradientEnd - charStartOffset) / rect.width;
          return LinearGradient(
            colors: [Colors.white, Colors.white70],
            stops: [
              localGradientStart.clamp(0.0, 1.0),
              localGradientEnd.clamp(0.0, 1.0),
            ],
          ).createShader(rect);
        },
        child: Text(
          line.chars[i].char,
          style: textStyle.copyWith(color: Colors.white),
        ),
      );
      charWidgets.add(shaderMaskedChar);
    }
    return Wrap(alignment: WrapAlignment.start, children: charWidgets);
  }
}

// ===============================================================
// 辅助 Widget 和 TTML 解析器
// ===============================================================

class HoverableLyricLine extends StatefulWidget {
  final Widget child;
  final bool isCurrent;
  final Function(Size) onSizeChange;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;

  const HoverableLyricLine({
    super.key,
    required this.child,
    required this.isCurrent,
    required this.onSizeChange,
    this.onTap,
    this.onHoverChanged,
  });

  @override
  State<HoverableLyricLine> createState() => _HoverableLyricLineState();
}

class _HoverableLyricLineState extends State<HoverableLyricLine> {
  bool _isHovered = false;

  void _updateHover(bool hover) {
    if (_isHovered != hover) {
      setState(() => _isHovered = hover);
      widget.onHoverChanged?.call(hover);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              end: (widget.isCurrent || _isHovered) ? 0 : 2.5,
            ),
            duration: const Duration(milliseconds: 250),
            builder: (context, blurValue, child) {
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.1)
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
              tween: Tween<double>(end: widget.isCurrent ? 1.05 : 1.0),
              duration: const Duration(milliseconds: 400),
              curve: const Cubic(0.46, 1.2, 0.43, 1.04),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _LrcLineInfo {
  final int timeInMs;
  final String text;
  _LrcLineInfo(this.timeInMs, this.text);
}

class MeasureSize extends StatefulWidget {
  final Widget child;
  final Function(Size) onChange;
  const MeasureSize({Key? key, required this.onChange, required this.child})
    : super(key: key);
  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size != null && _oldSize != size) {
        _oldSize = size;
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}

// 在 karaoke_lyrics_view.dart 文件中找到并替换这个函数
// 在 karaoke_lyrics_view.dart 文件中

Future<List<LyricLine>> _parseLrcContent(
  String lrcContent, {
  bool originalOnly = true,
}) async {
  // 步骤 1 & 2: 分组和合并歌词 (保持不变)
  final Map<int, List<String>> timeToTexts = {};
  final lines = lrcContent.split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final matches = RegExp(r'\[(\d{2}):(\d{2})\.(\d{1,3})\]').allMatches(line);
    final text = line.substring(line.lastIndexOf(']') + 1).trim();
    if (matches.isNotEmpty && text.isNotEmpty) {
      for (final match in matches) {
        final m = int.parse(match.group(1)!), s = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0'));
        final timeInMs = (m * 60 + s) * 1000 + ms;
        if (!timeToTexts.containsKey(timeInMs)) timeToTexts[timeInMs] = [];
        timeToTexts[timeInMs]!.add(text);
      }
    }
  }
  final rawLines = <_LrcLineInfo>[];
  final sortedTimes = timeToTexts.keys.toList()..sort();
  for (final timeInMs in sortedTimes) {
    List<String> texts = timeToTexts[timeInMs]!;
    rawLines.add(_LrcLineInfo(timeInMs, originalOnly ? texts.first : texts.join('\n')));
  }
  if (rawLines.isEmpty) return [];

  // --- 步骤 3: 构建逐字/逐词时间戳 (核心修改点) ---
  final lyricLines = <LyricLine>[];
  for (int i = 0; i < rawLines.length; i++) {
    final currentLrcLine = rawLines[i];
    final nextTimeInMs = (i + 1 < rawLines.length) ? rawLines[i + 1].timeInMs : currentLrcLine.timeInMs + 5000;
    final startTime = Duration(milliseconds: currentLrcLine.timeInMs);
    final endTime = Duration(milliseconds: nextTimeInMs);
    final lineDurationMs = (endTime - startTime).inMilliseconds;
    
    final chars = <LyricChar>[];
    final lineText = currentLrcLine.text;

    if (lineDurationMs > 0 && lineText.isNotEmpty) {
      // --- 语言检测与分词 (简化版) ---
      // 简单地检查是否包含英文字母来判断
      final isEnglishLike = RegExp(r'[a-zA-Z]').hasMatch(lineText);
      List<String> tokens;
      
      if (isEnglishLike) {
        // 英文：按空格分词
        final words = lineText.split(' ');
        tokens = [];
        for (int w = 0; w < words.length; w++) {
          // 将空格加回到前一个单词的末尾，以保持正确的间距
          tokens.add(words[w] + (w < words.length - 1 ? ' ' : ''));
        }
      } else {
        // 中文或其他语言：按单字分词
        tokens = lineText.split('');
      }
      // --- 分词结束 ---

      if (tokens.isEmpty) continue;

      // 按字符数比例分配时间 (逻辑保持不变)
      final totalChars = lineText.length;
      if (totalChars == 0) continue;
      
      double msPerChar = lineDurationMs.toDouble() / totalChars;
      Duration currentTokenStart = startTime;

      for (final token in tokens) {
        final tokenDurationMs = (msPerChar * token.length).round();
        final tokenDuration = Duration(milliseconds: tokenDurationMs);
        final tokenEndTime = currentTokenStart + tokenDuration;
        
        chars.add(LyricChar(
          char: token, // token 可能是 "word " 或 "字"
          start: currentTokenStart,
          end: tokenEndTime,
        ));
        currentTokenStart = tokenEndTime;
      }
    } else {
      chars.add(LyricChar(char: lineText, start: startTime, end: endTime));
    }
    
    lyricLines.add(LyricLine(chars: chars, startTime: startTime, endTime: endTime));
  }
  
  return lyricLines;
}



Future<List<LyricLine>> _parseTtmlContent(String ttmlContent) async {
  try {
    final document = XmlDocument.parse(ttmlContent);
    final paragraphs = document.findAllElements('p');
    final lyricLines = <LyricLine>[];

    for (final p in paragraphs) {
      final lineStartTimeStr = p.getAttribute('begin') ?? '0.0s';
      final lineEndTimeStr = p.getAttribute('end') ?? '0.0s';
      final lineStartTime = _parseTtmlTime(lineStartTimeStr);
      final lineEndTime = _parseTtmlTime(lineEndTimeStr);

      final chars = <LyricChar>[];

      for (final node in p.children) {
        
        if (node is XmlElement) { // 如果是 <span> 标签
          if (node.name.local != 'span' || node.getAttribute('ttm:role') != null) {
            continue; 
          }

          final charText = node.text;
          if (charText.isEmpty) continue;

          final charStartTimeStr = node.getAttribute('begin') ?? lineStartTimeStr;
          final charEndTimeStr = node.getAttribute('end') ?? lineEndTimeStr;
          final charStartTime = _parseTtmlTime(charStartTimeStr);
          final charEndTime = _parseTtmlTime(charEndTimeStr);
          
          final spanDuration = charEndTime.inMilliseconds - charStartTime.inMilliseconds;

          if (spanDuration <= 0 || charText.length == 1) {
            chars.add(LyricChar(char: charText, start: charStartTime, end: charEndTime));
          } else {
            final singleCharDuration = Duration(milliseconds: spanDuration ~/ charText.length);
            for (int i = 0; i < charText.length; i++) {
              final start = charStartTime + (singleCharDuration * i);
              final end = start + singleCharDuration;
              chars.add(LyricChar(char: charText[i], start: start, end: end));
            }
          }
        } 
        else if (node is XmlText) {
          final text = node.text;
          if (text.trim().isEmpty && chars.isNotEmpty) {
            final lastChar = chars.last;
            chars[chars.length - 1] = LyricChar(
              char: lastChar.char + text,
              start: lastChar.start,
              end: lastChar.end,
            );
          }
        }
      }

      if (chars.isNotEmpty) {
        lyricLines.add(
          LyricLine(chars: chars, startTime: lineStartTime, endTime: lineEndTime),
        );
      }
    }

    return lyricLines;
  } catch (e) {
    debugPrint('Error parsing TTML content: $e');
    return [];
  }
}

Duration _parseTtmlTime(String time) {
  if (time.endsWith('s')) {
    final seconds = double.tryParse(time.replaceAll('s', '')) ?? 0.0;
    return Duration(milliseconds: (seconds * 1000).round());
  }
  final parts = time.split(':');
  int h = 0, m = 0;
  double s = 0;
  try {
    if (parts.length == 3) {
      h = int.parse(parts[0]);
      m = int.parse(parts[1]);
      s = double.parse(parts[2]);
    } else if (parts.length == 2) {
      m = int.parse(parts[0]);
      s = double.parse(parts[1]);
    } else if (parts.length == 1) {
      s = double.parse(parts[0]);
    }
    return Duration(milliseconds: h * 3600000 + m * 60000 + (s * 1000).round());
  } catch (e) {
    debugPrint('Error parsing time format "$time": $e');
    return Duration.zero;
  }
}
