import 'dart:ui';
import 'package:flutter/material.dart';
import './lyric/lyrics_models.dart'; // 引入上面的 Model

class KaraokeLyricsView extends StatefulWidget {
  final LyricsData? lyricsData; 
  final ValueNotifier<Duration> currentPosition;
  final Function(Duration) onTapLine;

  const KaraokeLyricsView({
    Key? key,
    required this.lyricsData,
    required this.currentPosition,
    required this.onTapLine,
  }) : super(key: key);

  @override
  State<KaraokeLyricsView> createState() => _KaraokeLyricsViewState();
}

class _KaraokeLyricsViewState extends State<KaraokeLyricsView> {
  // 缓存行数据引用
  List<LyricLine> _lyricLines = [];
  int _currentLineIndex = 0;

  late ScrollController _scrollController;
  final Map<int, double> _lineHeights = {};
  bool _isHoveringLyrics = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updateLyricsData();
    widget.currentPosition.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(KaraokeLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lyricsData != oldWidget.lyricsData) {
      _updateLyricsData();
    }
    if (widget.currentPosition != oldWidget.currentPosition) {
      oldWidget.currentPosition.removeListener(_onPositionChanged);
      widget.currentPosition.addListener(_onPositionChanged);
    }
  }

  void _updateLyricsData() {
    setState(() {
      _lyricLines = widget.lyricsData?.lines ?? [];
      _currentLineIndex = 0;
      _lineHeights.clear();
      // if (_scrollController.hasClients) _scrollController.jumpTo(0);
      Future.microtask(() {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
    });
    // 立即计算一次当前位置
    
    
  }

  void _onPositionChanged() {
    final pos = widget.currentPosition.value;
    _updateCurrentLine(pos);
  }

  @override
  void dispose() {
    widget.currentPosition.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCurrentLine(Duration position) {
    if (_lyricLines.isEmpty) return;
    
    // 查找逻辑：找到开始时间 <= 当前时间 的最后一行
    final newIndex = _lyricLines.lastIndexWhere(
      (line) => (position + const Duration(milliseconds: 200)) >= line.startTime,
    );

    if (newIndex != -1 && newIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = newIndex);
      _scrollToCurrentLine();
    }
  }

  Future<void> _scrollToCurrentLine({bool force = false}) async {
    if (!_scrollController.hasClients) return;
    if (_isHoveringLyrics && !force) return;

    double offsetUpToCurrent = 0;
    for (int i = 0; i < _currentLineIndex; i++) {
      offsetUpToCurrent += _lineHeights[i] ?? 100.0;
    }
    

    double maxScroll = _scrollController.position.maxScrollExtent;
    double targetOffset = offsetUpToCurrent.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: const Cubic(0.46, 1.2, 0.43, 1.04),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight = MediaQuery.of(context).size.height;
    
    if (_lyricLines.isEmpty) {
      return const Center(
        child: Text("暂无歌词", style: TextStyle(color: Colors.white70, fontSize: 24)),
      );
    }

    return MouseRegion(
      onExit: (_) {
        _scrollToCurrentLine(force: true);
      },
      child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const SizedBox(height: 160),
            ..._lyricLines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              final isCurrent = index == _currentLineIndex;

              return ValueListenableBuilder<Duration>(
                valueListenable: widget.currentPosition,
                builder: (context, position, child) {
                  return HoverableLyricLine(
                    isCurrent: isCurrent,
                    onSizeChange: (size) => _lineHeights[index] = size.height,
                    onHoverChanged: (hover) => _isHoveringLyrics = hover,
                    onTap: () {
                      widget.onTapLine(line.startTime);
                      setState(() => _currentLineIndex = index);
                      _scrollToCurrentLine(force: true);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKaraokeText(line, position,isCurrent),
                        if (line.translation != null && line.translation!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              line.translation!,
                              style: TextStyle(
                                color: isCurrent ? Colors.white.withOpacity(0.8) : Colors.white54,
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
            SizedBox(height: contentHeight - 320),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildKaraokeText(LyricLine line, Duration position, bool isCurrent) {
    final textStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.4,
      shadows: isCurrent?[Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)]:null,
    );

    if (position < line.startTime || position > line.endTime) {
      final color = (position > line.endTime) ? Colors.white.withAlpha(230) : Colors.white70.withAlpha(200);
      return Wrap(
        children: line.spans.map((span) => Text(span.text, style: textStyle.copyWith(color: color))).toList(),
      );
    }

    // 2. 预计算每个 Span 的宽度
    final List<double> spanWidths = [];
    final List<double> spanOffsets = [];
    double currentOffset = 0.0;

    for (final span in line.spans) {
      final painter = TextPainter(
        text: TextSpan(text: span.text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      spanWidths.add(painter.width);
      spanOffsets.add(currentOffset);
      currentOffset += painter.width;
    }
    double progressInPixels = 0.0;
    
    final currentSpanIndex = line.spans.lastIndexWhere((s) => position >= s.start);

    if (currentSpanIndex != -1) {
      final span = line.spans[currentSpanIndex];
      final offset = spanOffsets[currentSpanIndex];
      final width = spanWidths[currentSpanIndex];

      double spanProgress = 0.0;
      final durationMs = (span.end - span.start).inMilliseconds;
      if (durationMs > 0) {
        spanProgress = (position.inMilliseconds - span.start.inMilliseconds) / durationMs;
        spanProgress = spanProgress.clamp(0.0, 1.0);
      } else if (position >= span.end) {
        spanProgress = 1.0;
      }

      progressInPixels = offset + (width * spanProgress);
    }

    final transitionWidthPixels = 20.0;
    final gradientStart = progressInPixels;
    final gradientEnd = progressInPixels + transitionWidthPixels;

    final widgets = <Widget>[];
    for (int i = 0; i < line.spans.length; i++) {
      final spanStart = spanOffsets[i];
      final spanEnd = spanStart + spanWidths[i];

      final shaderWidget = ShaderMask(
        shaderCallback: (rect) {
          // 完全已唱过
          if (spanEnd <= gradientStart) {
            return const LinearGradient(colors: [Colors.white, Colors.white]).createShader(rect);
          }
          // 完全未唱
          if (spanStart >= gradientEnd) {
            return const LinearGradient(colors: [Colors.white70, Colors.white70]).createShader(rect);
          }
          // 交界处渐变
          final localStart = (gradientStart - spanStart) / rect.width;
          final localEnd = (gradientEnd - spanStart) / rect.width;
          
          return LinearGradient(
            colors: const [Colors.white, Colors.white70],
            stops: [localStart.clamp(0.0, 1.0), localEnd.clamp(0.0, 1.0)],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcIn,
        child: Text(line.spans[i].text, style: textStyle),
      );
      widgets.add(shaderWidget);
    }

    return Wrap(alignment: WrapAlignment.start, children: widgets);
  }
}

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
        onExit: (_)=>_updateHover(false),
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