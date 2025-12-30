import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import './lyric/lyrics_models.dart';

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

class _KaraokeLyricsViewState extends State<KaraokeLyricsView>
    with TickerProviderStateMixin {
  List<LyricLine> _lyricLines = [];
  int _currentLineIndex = 0;

  double _targetScrollY = 0.0;
  final Map<int, double> _lineHeights = {};

  bool _isDragging = false;
  double _dragOffset = 0.0;
  bool _isAnyLineHovered = false;
  DateTime? _lastUserScrollTime;
  bool _disableBlurDueToUserScroll = false;

  @override
  void initState() {
    super.initState();
    _updateLyricsData();
    // 只需要监听行变化的大概逻辑，具体的微秒级更新交给 ValueListenableBuilder
    widget.currentPosition.addListener(_onPositionChanged);
    
    // 初始化后根据当前位置定位到正确的歌词行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPosition();
    });
  }
  
  void _scrollToCurrentPosition() {
    if (_lyricLines.isEmpty) return;
    
    final pos = widget.currentPosition.value;
    final newIndex = _lyricLines.lastIndexWhere(
      (line) => (pos + const Duration(milliseconds: 400)) >= line.startTime,
    );
    
    if (newIndex != -1) {
      setState(() {
        _currentLineIndex = newIndex;
        _recalculateScrollTarget(selectTopPadding());
      });
    }
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
      _targetScrollY = 0.0;
      _lineHeights.clear();
      _dragOffset = 0.0;
    });
  }

  void _onPositionChanged() {
    if (_lyricLines.isEmpty || _isDragging) return;
    
    // 如果用户在3秒内滚动过，不自动滚动
    if (_lastUserScrollTime != null) {
      final timeSinceScroll = DateTime.now().difference(_lastUserScrollTime!);
      if (timeSinceScroll.inSeconds < 3) {
        // 仍然更新当前行索引（用于高亮），但不触发滚动
        final pos = widget.currentPosition.value;
        final newIndex = _lyricLines.lastIndexWhere(
          (line) => (pos + const Duration(milliseconds: 400)) >= line.startTime,
        );
        if (newIndex != -1 && newIndex != _currentLineIndex) {
          setState(() {
            _currentLineIndex = newIndex;
          });
        }
        return;
      }
    }
    
    final pos = widget.currentPosition.value;

    // 提前 400ms 滚动
    final newIndex = _lyricLines.lastIndexWhere(
      (line) => (pos + const Duration(milliseconds: 400)) >= line.startTime,
    );

    if (newIndex != -1 && newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
        _recalculateScrollTarget(selectTopPadding());
        // 自动滚动时恢复模糊效果
        _disableBlurDueToUserScroll = false;
      });
    }
  }

  // PlatformUtils.isMobileWidth(context) ? 80 : 160
  double selectTopPadding() {
    return PlatformUtils.isMobileWidth(context) ? 80 : 160;
  }

  void _recalculateScrollTarget(double topPadding) {
    if (_lineHeights.isEmpty) return;

    double offset = 0.0;
    for (int i = 0; i < _currentLineIndex; i++) {
      // 使用缓存的高度
      offset += (_lineHeights[i] ?? 80.0);
    }
    offset += topPadding; // Top Padding

    final screenHeight = MediaQuery.of(context).size.height;
    final currentLineHeight = _lineHeights[_currentLineIndex] ?? 80.0;

    // 目标位置：屏幕 30% 处
    double target = 0;
    if (topPadding == 160.0) {
      target = offset + (currentLineHeight / 2) - (screenHeight * 0.30);
    } else {
      target = offset + (currentLineHeight / 2) - (screenHeight * 0.2);
    }

    if (target < 0) target = 0;

    double totalHeight = topPadding + screenHeight;
    for (var h in _lineHeights.values) totalHeight += h;
    if (totalHeight > screenHeight && target > totalHeight - screenHeight) {
      target = totalHeight - screenHeight;
    }

    setState(() {
      _targetScrollY = target;
    });
  }

  @override
  void dispose() {
    widget.currentPosition.removeListener(_onPositionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lyricLines.isEmpty) {
      return const Center(
          child: Text("暂无歌词",
              style: TextStyle(color: Colors.white54, fontSize: 24)));
    }

    final double activeScrollY = _targetScrollY - _dragOffset;
    final double topPadding = selectTopPadding();

    return GestureDetector(
      onVerticalDragStart: (_) {
        _isDragging = true;
        _dragOffset = 0.0;
      },
      onVerticalDragUpdate: (details) {
        _lastUserScrollTime = DateTime.now();
        if (!_disableBlurDueToUserScroll) {
          setState(() => _disableBlurDueToUserScroll = true);
        }
        setState(() {
          _targetScrollY -= details.delta.dy;
          if (_targetScrollY < 0) _targetScrollY = 0;
        });
      },
      onVerticalDragEnd: (details) {
        _isDragging = false;
        // 不再强制滚动回当前行，让用户自由浏览
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPadding),
              ..._lyricLines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                final isCurrent = index == _currentLineIndex;

                // 计算当前行的累积Y位置
                double cumulativeY = topPadding;
                for (int i = 0; i < index; i++) {
                  cumulativeY += (_lineHeights[i] ?? 80.0);
                }

                return MeasureSize(
                  onChange: (size) {
                    // 只有当高度发生实质性变化时才更新
                    if (_lineHeights[index] != size.height) {
                      _lineHeights[index] = size.height;
                      if (isCurrent)
                        Future.microtask(
                            () => _recalculateScrollTarget(topPadding));
                    }
                  },
                  child: IndependentLyricLine(
                    index: index,
                    currentIndex: _currentLineIndex,
                    targetScrollY: activeScrollY,
                    lineYPosition: cumulativeY,
                    screenHeight: MediaQuery.of(context).size.height,
                    lineHeight: _lineHeights[index] ?? 80.0,
                    isUserDragging: _isDragging,
                    isAnyLineHovered: _isAnyLineHovered,
                    disableBlurDueToUserScroll: _disableBlurDueToUserScroll,
                    onHoverChanged: (isHovered) {
                      setState(() => _isAnyLineHovered = isHovered);
                    },
                    onTap: () {
                      widget.onTapLine(line.startTime);
                      setState(() {
                        _currentLineIndex = index;
                        _recalculateScrollTarget(topPadding);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 让歌词内部的 ShaderMask 能够监听到每一帧的进度变化
                        _InterpolatedPosition(
                          sourcePosition: widget.currentPosition,
                          builder: (position) {
                            return _buildKaraokeText(line, position, isCurrent);
                          },
                        ),

                        if (line.translations != null &&
                            line.translations!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: isCurrent ? 0.8 : 0.4,
                              child: Text(
                                line.translations![
                                    line.translations!.keys.first]!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(context).size.height / 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaraokeText(LyricLine line, Duration position, bool isCurrent) {
    final textStyle = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.4,
      shadows:
          isCurrent ? [Shadow(color: Colors.black.withOpacity(0.5))] : null,
    );

    // 优化：不在播放范围内的，直接返回静态文本，节省 Shader 计算资源
    if (position < line.startTime || position > line.endTime) {
      final color = (position > line.endTime) ? Colors.white : Colors.white54;
      return Wrap(
        children: line.spans
            .map((span) =>
                Text(span.text, style: textStyle.copyWith(color: color)))
            .toList(),
      );
    }

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
        spanProgress =
            (position.inMilliseconds - span.start.inMilliseconds) / durationMs;
        spanProgress = spanProgress.clamp(0.0, 1.0);
      } else if (position >= span.end) {
        spanProgress = 1.0;
      }
      progressInPixels = offset + (width * spanProgress);
    }

    final transitionWidthPixels = 12.0;
    final gradientStart = progressInPixels;
    final gradientEnd = progressInPixels + transitionWidthPixels;

    final widgets = <Widget>[];
    for (int i = 0; i < line.spans.length; i++) {
      final spanStart = spanOffsets[i];
      final spanEnd = spanStart + spanWidths[i];

      final shaderWidget = ShaderMask(
        shaderCallback: (rect) {
          // 这里的 rect.width 是当前这个字(Span)的宽度

          // 1. 完全已唱过
          if (spanEnd <= gradientStart) {
            return const LinearGradient(colors: [Colors.white, Colors.white])
                .createShader(rect);
          }
          // 2. 完全未唱
          if (spanStart >= gradientEnd) {
            // 只有当前行未唱部分是半透明，其他行由外层 Opacity 控制
            return const LinearGradient(
                colors: [Colors.white54, Colors.white54]).createShader(rect);
          }

          // 3. 交界处：计算渐变条在当前这个 Span 内部的相对位置
          // 相对位置 = (全局位置 - 本Span起始位置) / 本Span宽度
          final localStart = (gradientStart - spanStart) / rect.width;
          final localEnd = (gradientEnd - spanStart) / rect.width;

          return LinearGradient(
            colors: const [Colors.white, Colors.white54],
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

class _InterpolatedPosition extends StatefulWidget {
  final ValueNotifier<Duration> sourcePosition;
  final Widget Function(Duration position) builder;

  const _InterpolatedPosition({
    required this.sourcePosition,
    required this.builder,
  });

  @override
  State<_InterpolatedPosition> createState() => _InterpolatedPositionState();
}

class _InterpolatedPositionState extends State<_InterpolatedPosition>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _currentPosition = Duration.zero;
  Duration _lastKnownPosition = Duration.zero;
  DateTime _lastUpdateTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // 监听真实音频位置
    widget.sourcePosition.addListener(_onPositionChanged);
    _lastKnownPosition = widget.sourcePosition.value;
    _lastUpdateTime = DateTime.now();

    // 60fps 插值
    _ticker = createTicker((elapsed) {
      final now = DateTime.now();
      final timeSinceUpdate = now.difference(_lastUpdateTime);

      // 如果超过 500ms 没更新，停止插值（可能暂停了）
      if (timeSinceUpdate.inMilliseconds > 500) {
        _currentPosition = _lastKnownPosition;
      } else {
        // 线性插值
        _currentPosition = _lastKnownPosition + timeSinceUpdate;
      }

      setState(() {});
    });
    _ticker.start();
  }

  void _onPositionChanged() {
    _lastKnownPosition = widget.sourcePosition.value;
    _lastUpdateTime = DateTime.now();
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.sourcePosition.removeListener(_onPositionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_currentPosition);
  }
}

class IndependentLyricLine extends StatefulWidget {
  final int index;
  final int currentIndex;
  final double targetScrollY;
  final double lineYPosition;
  final double screenHeight;
  final double lineHeight;
  final bool isUserDragging;
  final bool isAnyLineHovered;
  final bool disableBlurDueToUserScroll;
  final ValueChanged<bool> onHoverChanged;
  final Widget child;
  final VoidCallback onTap;

  const IndependentLyricLine({
    Key? key,
    required this.index,
    required this.currentIndex,
    required this.targetScrollY,
    required this.lineYPosition,
    required this.screenHeight,
    required this.lineHeight,
    required this.isUserDragging,
    required this.isAnyLineHovered,
    required this.disableBlurDueToUserScroll,
    required this.onHoverChanged,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  @override
  State<IndependentLyricLine> createState() => _IndependentLyricLineState();
}

class _IndependentLyricLineState extends State<IndependentLyricLine>
    with SingleTickerProviderStateMixin {
  // Padding 变量
  double get _horizontalPadding =>
      PlatformUtils.isMobileWidth(context) ? 0.0 : 12.0;
  static const double _verticalPadding = 12.0;

  late AnimationController _animController;
  late Animation<double> _yAnimation;
  double _currentTranslateY = 0.0;
  bool _isHovered = false;
  bool _wasJustDragging = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        setState(() {
          _currentTranslateY = _yAnimation.value;
        });
      });

    _currentTranslateY = widget.targetScrollY;
    _yAnimation = AlwaysStoppedAnimation(widget.targetScrollY);
  }

  @override
  void didUpdateWidget(IndependentLyricLine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检测拖动状态变化
    if (oldWidget.isUserDragging && !widget.isUserDragging) {
      // 刚结束拖动，标记状态并延迟恢复
      _wasJustDragging = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _wasJustDragging = false;
          });
        }
      });
    }

    if (widget.targetScrollY != oldWidget.targetScrollY) {
      if (widget.isUserDragging || _wasJustDragging) {
        // 用户手动拖动时或刚结束拖动时，禁用所有动画和延迟，立即跟随
        if (_animController.isAnimating) _animController.stop();
        setState(() {
          _currentTranslateY = widget.targetScrollY;
        });
      } else {
        // 自动滚动时，使用弹簧动画和延迟
        _startSpringAnimation(
            from: _currentTranslateY, to: widget.targetScrollY);
      }
    }
  }

  void _startSpringAnimation({required double from, required double to}) {
    int distance = widget.index - widget.currentIndex;
    // 默认时长
    Duration animDuration = const Duration(milliseconds: 900);

    // 上方歌词稍快一点
    if (distance < 0) {
      animDuration = const Duration(milliseconds: 800);
    }

    // 动态更新控制器的时长
    _animController.duration = animDuration;

    int delayMs = 0;
    
    // 用户手动拖动时，禁用延迟
    if (!widget.isUserDragging) {
      // 判断滚动方向
      final bool isScrollingDown = to > from; // 向下滚动（内容向上移动）
      
      // 基于实际位置计算延迟
      final double lineScreenY = widget.lineYPosition - widget.targetScrollY;
      
      if (isScrollingDown) {
        // 向下滚动：顶部的歌词先动（拉着下面的走）
        if (lineScreenY < 0) {
          delayMs = 0;
        } else {
          final double lineIndex = (lineScreenY / widget.lineHeight).clamp(0.0, double.infinity);
          const int delayPerLine = 40;
          delayMs = (lineIndex * delayPerLine).round();
        }
      } else {
        // 向上滚动：底部的歌词先动（拉着上面的走）
        if (lineScreenY > widget.screenHeight) {
          delayMs = 0;
        } else {
          // 计算从屏幕底部往上是第几行
          final double distanceFromBottom = widget.screenHeight - lineScreenY;
          final double lineIndexFromBottom = (distanceFromBottom / widget.lineHeight).clamp(0.0, double.infinity);
          const int delayPerLine = 20;
          delayMs = (lineIndexFromBottom * delayPerLine).round();
        }
      }
    }

    _yAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutQuart,
      ),
    );

    _animController.reset();
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = widget.index == widget.currentIndex;
    final int dist = (widget.index - widget.currentIndex).abs();

    // 状态计算
    double targetScale = 1.0;
    double targetOpacity = 1.0;
    double targetBlur = 0.0;

    if (isCurrent) {
      targetScale = 1.0;
      targetOpacity = 1.0;
      targetBlur = 0.0;
    } else {
      targetScale = 0.96;
      targetOpacity = (1.0 - (dist * 0.15)).clamp(0.4, 0.8);
      targetBlur = (dist * 0.8).clamp(0.0, 2.6);
    }

    // 如果用户正在拖动、悬浮在任意歌词上，或用户刚滚动过，去除所有模糊效果
    if (widget.isUserDragging || widget.isAnyLineHovered || widget.disableBlurDueToUserScroll) {
      targetBlur = 0.0;
      targetOpacity = isCurrent ? 1.0 : 0.7;
    }

    return Transform.translate(
      offset: Offset(0, -_currentTranslateY),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          widget.onHoverChanged(true);
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          widget.onHoverChanged(false);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
                vertical: _verticalPadding, horizontal: _horizontalPadding),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: targetScale),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, scaleValue, child) {
                return Transform.scale(
                  scale: scaleValue,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: targetOpacity,
                child: ImageFiltered(
                  imageFilter:
                      ImageFilter.blur(sigmaX: targetBlur, sigmaY: targetBlur),
                  child: widget.child,
                ),
              ),
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
      if (size != null &&
          (_oldSize == null || (_oldSize!.height - size.height).abs() > 0.5)) {
        _oldSize = size;
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}
