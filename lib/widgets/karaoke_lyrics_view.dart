import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
  bool _isMomentumScrolling = false;
  bool _isMouseHovering = false;

  Timer? _resumeAutoScrollTimer;
  late AnimationController _momentumController;

  Timer? _wheelDebounceTimer;
  double _lastWheelDelta = 0.0;

  bool get _isInteracting =>
      _isDragging || _isMomentumScrolling || _isMouseHovering;

  @override
  void initState() {
    super.initState();
    _momentumController = AnimationController.unbounded(vsync: this);
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
      _targetScrollY = 0.0;
      _lineHeights.clear();
      _forceResetState();
    });
  }

  void _forceResetState() {
    _resumeAutoScrollTimer?.cancel();
    _wheelDebounceTimer?.cancel();
    if (_momentumController.isAnimating) _momentumController.stop();
    _isDragging = false;
    _isMomentumScrolling = false;
  }

  void _onPositionChanged() {
    if (_lyricLines.isEmpty) return;
    if (_isInteracting) return;

    final pos = widget.currentPosition.value;
    final newIndex = _lyricLines.lastIndexWhere(
      (line) => (pos + const Duration(milliseconds: 400)) >= line.startTime,
    );

    if (newIndex != -1 && newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
        _recalculateAutoScrollTarget();
      });
    }
  }

  double selectTopPadding() {
    return PlatformUtils.isMobileWidth(context) ? 80 : 160;
  }

  void _recalculateAutoScrollTarget() {
    if (_lineHeights.isEmpty) return;

    final topPadding = selectTopPadding();
    double offset = 0.0;
    for (int i = 0; i < _currentLineIndex; i++) {
      offset += (_lineHeights[i] ?? 80.0);
    }
    offset += topPadding;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentLineHeight = _lineHeights[_currentLineIndex] ?? 80.0;

    double target = 0;
    if (topPadding == 160.0) {
      target = offset + (currentLineHeight / 2) - (screenHeight * 0.30);
    } else {
      target = offset + (currentLineHeight / 2) - (screenHeight * 0.2);
    }

    target = _clampScrollTarget(target);

    setState(() {
      _targetScrollY = target;
    });
  }

  double _clampScrollTarget(double target) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = selectTopPadding();
    double totalContentHeight = topPadding + (screenHeight * 0.5);
    for (var h in _lineHeights.values) totalContentHeight += h;

    if (totalContentHeight < screenHeight) return 0;
    final maxScroll = totalContentHeight - screenHeight;

    if (target < 0) return 0;
    if (target > maxScroll) return maxScroll;
    return target;
  }

  void _performRestore() {
    if (!mounted) return;
    setState(() {
      _isDragging = false;
      _isMomentumScrolling = false;
      _recalculateAutoScrollTarget();
    });
  }

  void _scheduleResumeAutoScroll() {
    _resumeAutoScrollTimer?.cancel();

    if (PlatformUtils.isDesktop) {
      if (_isMouseHovering) return;
      _resumeAutoScrollTimer = Timer(const Duration(milliseconds: 50), () {
        _performRestore();
      });
    } else {
      if (!_isDragging && !_isMomentumScrolling) {
        _resumeAutoScrollTimer = Timer(const Duration(milliseconds: 500), () {
          _performRestore();
        });
      }
    }
  }

  void _handleMouseWheel(PointerScrollEvent event) {
    if (!_isMomentumScrolling && !_isDragging) {
      _momentumController.stop();
      _resumeAutoScrollTimer?.cancel();
      setState(() => _isMomentumScrolling = true);
    }

    final double delta = -event.scrollDelta.dy * 1.5;
    _handleDragUpdate(delta);
    _lastWheelDelta = delta;

    _wheelDebounceTimer?.cancel();
    _wheelDebounceTimer = Timer(const Duration(milliseconds: 60), () {
      final double simulatedVelocity = _lastWheelDelta * 20;
      _handleDragEnd(simulatedVelocity);
    });
  }

  void _handleDragUpdate(double delta) {
    setState(() {
      double newTarget = _targetScrollY - delta;
      final maxScroll = _getMaxScrollExtent();
      if (newTarget < 0 || newTarget > maxScroll) {
        newTarget = _targetScrollY - (delta * 0.5);
      }
      _targetScrollY = _clampScrollTarget(newTarget);
    });
  }

  double _getMaxScrollExtent() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = selectTopPadding();
    double total = topPadding + (screenHeight * 0.5);
    for (var h in _lineHeights.values) total += h;
    return (total - screenHeight).clamp(0.0, double.infinity);
  }

  void _handleDragEnd(double velocity) {
    setState(() {
      _isDragging = false;
      _isMomentumScrolling = true;
    });

    final simulation = FrictionSimulation(0.135, _targetScrollY, -velocity);
    _momentumController.animateWith(simulation);

    void tick() {
      if (!mounted) return;
      final double newVal = _momentumController.value;
      final double clamped = _clampScrollTarget(newVal);
      setState(() {
        _targetScrollY = clamped;
      });
      if ((newVal < 0 && velocity > 0) ||
          (newVal > _getMaxScrollExtent() && velocity < 0)) {
        _momentumController.stop();
      }
    }

    _momentumController.addListener(tick);
    _momentumController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _momentumController.removeListener(tick);
        if (mounted) {
          setState(() {
            _isMomentumScrolling = false;
          });
          _scheduleResumeAutoScroll();
        }
      }
    });
  }

  @override
  void dispose() {
    widget.currentPosition.removeListener(_onPositionChanged);
    _momentumController.dispose();
    _resumeAutoScrollTimer?.cancel();
    _wheelDebounceTimer?.cancel();
    super.dispose();
  }

  // --- 全局交互逻辑 ---
  void _onGlobalPointerEnter() {
    // 只有当状态确实改变时才调用 setState，避免频繁重建
    if (!_isMouseHovering) {
      setState(() => _isMouseHovering = true);
    }
    _resumeAutoScrollTimer?.cancel();
    _wheelDebounceTimer?.cancel();
    if (_momentumController.isAnimating) _momentumController.stop();
    if (_isMomentumScrolling || _isDragging) {
      setState(() {
        _isMomentumScrolling = false;
        _isDragging = false;
      });
    }
  }

  void _onGlobalPointerExit() {
    setState(() => _isMouseHovering = false);
    _scheduleResumeAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    if (_lyricLines.isEmpty) {
      return const Center(
          child: Text("暂无歌词",
              style: TextStyle(color: Colors.white54, fontSize: 24)));
    }

    final double activeScrollY = _targetScrollY;
    final double topPadding = selectTopPadding();

    final bool interacting = _isInteracting;
    final bool isUserMoving = _isDragging || _isMomentumScrolling;

    // 修复点：外层 Listener 监听滚轮，内部包裹 MouseRegion 监听进出
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleMouseWheel(event);
        }
      },
      child: MouseRegion(
        // 关键：监听进入和离开
        onEnter: (_) => _onGlobalPointerEnter(),
        onExit: (_) => _onGlobalPointerExit(),
        // 双重保险：只要鼠标在区域内移动，就强制确认为 Hovering 状态
        // 解决有时快速移动导致 onExit 触发后 _isMouseHovering 没变回来的问题
        onHover: (_) => _onGlobalPointerEnter(),

        // 确保 MouseRegion 不会遮挡点击，同时允许事件穿透到空白处
        opaque: false,

        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // 确保空白区域也能响应拖拽
          onVerticalDragStart: (_) {
            _momentumController.stop();
            _resumeAutoScrollTimer?.cancel();
            _wheelDebounceTimer?.cancel();
            setState(() => _isDragging = true);
          },
          onVerticalDragUpdate: (details) {
            _handleDragUpdate(details.delta.dy);
          },
          onVerticalDragEnd: (details) {
            _handleDragEnd(details.velocity.pixelsPerSecond.dy);
          },
          onTap: () {
            if (_isMomentumScrolling) {
              _momentumController.stop();
              _wheelDebounceTimer?.cancel();
              setState(() => _isMomentumScrolling = false);
              _scheduleResumeAutoScroll();
            }
          },
          child: Container(
            color: Colors.transparent, // 必须透明色，确保 HitTestBehavior 生效
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                ScrollConfiguration(
  // 关键代码：创建一个不显示滚动条的配置
  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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

                        return MeasureSize(
                          key: ValueKey('lyric_$index'),
                          onChange: (size) {
                            if (_lineHeights[index] != size.height) {
                              _lineHeights[index] = size.height;
                              if (isCurrent && !interacting) {
                                Future.microtask(_recalculateAutoScrollTarget);
                              }
                            }
                          },
                          child: IndependentLyricLine(
                            index: index,
                            currentIndex: _currentLineIndex,
                            targetScrollY: activeScrollY,
                            isUserDragging: isUserMoving,
                            isInteracting: interacting,
                            onTap: () {
                              widget.onTapLine(line.startTime);
                              setState(() {
                                _currentLineIndex = index;
                                _forceResetState();
                                _recalculateAutoScrollTarget();
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InterpolatedPosition(
                                  sourcePosition: widget.currentPosition,
                                  builder: (position) {
                                    return _buildKaraokeText(
                                        line, position, isCurrent);
                                  },
                                ),
                                if (line.translations != null &&
                                    line.translations!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      opacity: isCurrent ? 0.8 : 0.4,
                                      child: Text(
                                        line.translations!.values.first,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400,
                                        ),
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
)
              ],
            ),
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
    final currentSpanIndex =
        line.spans.lastIndexWhere((s) => position >= s.start);

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

    final transitionWidthPixels = 1.0;
    final gradientStart = progressInPixels;
    final gradientEnd = progressInPixels + transitionWidthPixels;

    final widgets = <Widget>[];
    for (int i = 0; i < line.spans.length; i++) {
      final spanStart = spanOffsets[i];
      final spanEnd = spanStart + spanWidths[i];

      // 计算当前字的状态：-1 未播放，0 正在播放，1 已播放
      int charState;
      double animationProgress = 0.0;
      
      if (spanEnd <= gradientStart) {
        charState = 1; // 已播放完
      } else if (spanStart >= gradientEnd) {
        charState = -1; // 未播放
      } else {
        charState = 0; // 正在播放
        // 使用固定的200ms动画时长
        final span = line.spans[i];
        final timeSinceStart = position.inMilliseconds - span.start.inMilliseconds;
        const fixedAnimationDuration = 200; // 固定200ms动画时长
        animationProgress = (timeSinceStart / fixedAnimationDuration).clamp(0.0, 1.0);
      }

      // 根据状态设置垂直偏移
      double verticalOffset;
      if (charState == 1) {
        verticalOffset = 0.0; // 已播放：保持原位
      } else if (charState == -1) {
        verticalOffset = 0.7; // 未播放：向下偏移
      } else {
        // 正在播放：从下沉位置(0.7)平滑上浮到原位(0.0)
        // 可选曲线：
        // Curves.easeOutQuart - 更平滑的四次方缓出
        // Curves.fastOutSlowIn - Material Design 标准曲线
        // Curves.easeOutBack - 带轻微回弹效果，更生动
        // Curves.decelerate - 持续减速
        final curvedProgress = Curves.fastOutSlowIn.transform(animationProgress);
        verticalOffset = 0.7 - (curvedProgress * 0.7);
      }

      final shaderWidget = ShaderMask(
        shaderCallback: (rect) {
          if (spanEnd <= gradientStart) {
            return const LinearGradient(colors: [Colors.white, Colors.white])
                .createShader(rect);
          }
          if (spanStart >= gradientEnd) {
            return const LinearGradient(
                colors: [Colors.white54, Colors.white54]).createShader(rect);
          }
          final localStart = (gradientStart - spanStart) / rect.width;
          final localEnd = (gradientEnd - spanStart) / rect.width;

          return LinearGradient(
            colors: const [Colors.white, Colors.white54],
            stops: [localStart.clamp(0.0, 1.0), localEnd.clamp(0.0, 1.0)],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcIn,
        child: Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Text(line.spans[i].text, style: textStyle),
        ),
      );
      widgets.add(shaderWidget);
    }
    return Wrap(alignment: WrapAlignment.start, children: widgets);
  }
}

class IndependentLyricLine extends StatefulWidget {
  final int index;
  final int currentIndex;
  final double targetScrollY;
  final bool isUserDragging;
  final bool isInteracting;
  final Widget child;
  final VoidCallback onTap;

  const IndependentLyricLine({
    Key? key,
    required this.index,
    required this.currentIndex,
    required this.targetScrollY,
    required this.isUserDragging,
    required this.isInteracting,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  @override
  State<IndependentLyricLine> createState() => _IndependentLyricLineState();
}

class _IndependentLyricLineState extends State<IndependentLyricLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _yAnimation;
  double _currentTranslateY = 0.0;
  bool _isHovered = false;

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

    if (widget.isUserDragging) {
      if (_animController.isAnimating) _animController.stop();
      setState(() {
        _currentTranslateY = widget.targetScrollY;
      });
      _yAnimation = AlwaysStoppedAnimation(widget.targetScrollY);
      return;
    }

    if (widget.targetScrollY != oldWidget.targetScrollY) {
      _startSpringAnimation(from: _currentTranslateY, to: widget.targetScrollY);
    }
  }

  void _startSpringAnimation({required double from, required double to}) {
    int distance = (widget.index - widget.currentIndex) + 1;
    Duration animDuration = const Duration(milliseconds: 900);
    if (distance < 0) animDuration = const Duration(milliseconds: 800);
    _animController.duration = animDuration;

    bool isScrollingBackwards = to < from;

    int delayMs = 0;
    int step = isScrollingBackwards ? 20 : 45; // FCK:20 : 80
    if (distance >= 0 && distance <= 12) {
      delayMs = (distance * step).clamp(0, 1600);
    }

    _yAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutQuart,
      ),
    );

    _animController.reset();
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && !widget.isUserDragging) _animController.forward();
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

    double targetScale;
    double targetOpacity;
    double targetBlur;

    if (widget.isInteracting || _isHovered) {
      targetScale = 1.0;
      targetOpacity = 1.0;
      targetBlur = 0.0;
    } else {
      if (isCurrent) {
        targetScale = 1.0;
        targetOpacity = 1.0;
        targetBlur = 0.0;
      } else {
        targetScale = 0.96;
        targetOpacity = (1.0 - (dist * 0.15)).clamp(0.2, 0.6);
        targetBlur = (dist * 0.8).clamp(0.0, 4.0);
      }
    }

    return Transform.translate(
      offset: Offset(0, -_currentTranslateY),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: targetScale),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, scaleValue, child) {
                return Transform.scale(
                  scale: scaleValue,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
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

// ... _InterpolatedPosition 和 MeasureSize 保持不变，请确保包含在文件中 ...
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
    widget.sourcePosition.addListener(_onPositionChanged);
    _lastKnownPosition = widget.sourcePosition.value;
    _lastUpdateTime = DateTime.now();
    _ticker = createTicker((elapsed) {
      final now = DateTime.now();
      final timeSinceUpdate = now.difference(_lastUpdateTime);
      if (timeSinceUpdate.inMilliseconds > 500) {
        _currentPosition = _lastKnownPosition;
      } else {
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
