import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/slider_custom.dart';
import '../services/player_provider.dart';
import '../contants/app_contants.dart' show PlayMode;

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

// 改进的NowPlayingScreen
class ImprovedNowPlayingScreen extends StatefulWidget {
  const ImprovedNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedNowPlayingScreen> createState() =>
      _ImprovedNowPlayingScreenState();
}

class _ImprovedNowPlayingScreenState extends State<ImprovedNowPlayingScreen> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool isHoveringLyrics = false;

  // 新增属性
  List<LyricLine> parsedLyrics = [];
  int lastCurrentIndex = -1;

  Map<int, double> lineHeights = {};
  double get placeholderHeight => 80;

  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 启动歌词更新定时器
    _startLyricsTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // 新增：启动定时器的方法
  void _startLyricsTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;

      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      if (!playerProvider.isPlaying) return;

      //getCurrentLyricIndex(
      //(playerProvider.position.inSeconds * 1000).toInt() +800,
      //) // 如果歌词延迟可以适当 + 1000
      final newCurrentLine = parsedLyrics.isNotEmpty
          ? getCurrentLyricIndex(playerProvider.position.inMilliseconds+500)
          : (playerProvider.position.inSeconds / 3).floor().clamp(
              0,
              parsedLyrics.isNotEmpty ? parsedLyrics.length - 1 : 0,
            );

      if (newCurrentLine != lastCurrentIndex && newCurrentLine >= 0) {
        lastCurrentIndex = newCurrentLine;
        setState(() {});
        scrollToCurrentLine(
          _scrollController,
          newCurrentLine,
          0,
          lineHeights,
          placeholderHeight,
        );
      }
    });
  }

  // 新增：解析歌词方法
  void _parseLyrics(String? lyricsContent, Duration totalDuration) {
    if (lyricsContent == null || lyricsContent.isEmpty) {
      parsedLyrics = [];
      return;
    }

    // 检查是否为LRC格式
    if (lyricsContent.contains(RegExp(r'\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]'))) {
      parsedLyrics = LyricsParser.parseLRC(lyricsContent);
    } else {
      parsedLyrics = LyricsParser.parseSimple(lyricsContent, totalDuration);
    }
  }

  // 新增：获取当前歌词索引
  int getCurrentLyricIndex(int currentPositionMs) {
    if (parsedLyrics.isEmpty) return -1;

    for (int i = parsedLyrics.length - 1; i >= 0; i--) {
      if (currentPositionMs >= parsedLyrics[i].timeInMs) {
        return i;
      }
    }
    return 0;
  }

  // 你原有的方法保持不变
  void scrollToCurrentLine(
    ScrollController controller,
    int currentLine,
    int highlightIndex,
    Map<int, double> lineHeights,
    double placeholderHeight, {
    bool force = false,
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

  Widget buildLyricLine(
    String text,
    bool isCurrent,
    int index,
    void Function(int) onTap,
    void Function(bool) onHoverChanged,
  ) {
    return HoverableLyricLine(
      text: text,
      isCurrent: isCurrent,
      onSizeChange: (size) {
        if (lineHeights[index] != size.height) {
          setState(() {
            lineHeights[index] = size.height;
          });
        }
      },
      onTap: () => onTap(index),
      onHoverChanged: onHoverChanged,
      isGloballyHovered: isHoveringLyrics,
      distanceToCurrentLine: (index - lastCurrentIndex).abs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;
        final bool isPlaying = playerProvider.isPlaying;
        final double currentPosition = playerProvider.position.inSeconds
            .toDouble();
        final double totalDuration = playerProvider.duration.inSeconds
            .toDouble();

        // 解析歌词
        _parseLyrics(currentSong?.lyrics, playerProvider.duration);

        // 使用解析后的歌词获取当前行
        final int currentLine = parsedLyrics.isNotEmpty
            ? getCurrentLyricIndex(
                playerProvider.position.inMilliseconds+500,
              ) //? getCurrentLyricIndex((currentPosition * 1000).toInt() +800)  // 如果延迟可以适当 + 1000
            : (currentPosition / 3).floor().clamp(
                0,
                (currentSong?.lyrics?.split('\n').length ?? 1) - 1,
              );

        // 准备显示的歌词列表（保持你的原有逻辑）
        final List<String> lyrics = parsedLyrics.isNotEmpty
            ? parsedLyrics.map((line) => line.text).toList()
            : currentSong?.lyrics?.split('\n') ?? ["暂无歌词"];

        // 你的原有UI代码保持完全不变
        return FocusScope(
  canRequestFocus: false,
  child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'player_background',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (currentSong?.albumArtPath != null &&
                        File(currentSong!.albumArtPath!).existsSync())
                      Image.file(
                        File(currentSong.albumArtPath!),
                        fit: BoxFit.cover,
                      )
                    else
                      Container(color: Colors.black),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black87.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Row(
                  children: [
                    Flexible(
                      flex: 20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 50,
                        ),
                        child: AspectRatio(
                          aspectRatio: 0.55, // 2:3 宽高比
                          child: Center(
                          
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HoverIconButton(
                                  onPressed: () => Navigator.pop(context),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.0, // 固定1:1宽高比
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child:
                                          currentSong?.albumArtPath != null &&
                                              File(
                                                currentSong!.albumArtPath!,
                                              ).existsSync()
                                          ? Image.file(
                                              File(currentSong.albumArtPath!),
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.music_note_rounded,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentSong?.title ?? "未知歌曲",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentSong?.artist ?? "未知歌手",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 18,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 9),
                                AnimatedTrackHeightSlider(
                                  value: _tempSliderValue >= 0
                                      ? _tempSliderValue
                                      : currentPosition,
                                  max: totalDuration,
                                  min: 0,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white30,
                                  onChanged: (value) {
                                    setState(() {
                                      _tempSliderValue = value; // 暂存比例
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    setState(() {
                                      _tempSliderValue =
                                          -1; // 复位，用实时 position 控制
                                    });
                                    playerProvider.seekTo(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      formatDuration(
                                        Duration(
                                          seconds: currentPosition.toInt(),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "${currentSong?.bitrate != null ? (currentSong!.bitrate! / 1000).toStringAsFixed(0) : '未知'} kbps",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatDuration(
                                        Duration(
                                          seconds: totalDuration.toInt(),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      iconSize: 20,
                                      color: Colors.white70,
                                      icon: Icon(
                                        Icons.shuffle_rounded,
                                        color:
                                            playerProvider.playMode ==
                                                PlayMode.shuffle
                                            ? Colors.white
                                            : null,
                                      ),
                                      onPressed: () {
                                        if (playerProvider.playMode ==
                                            PlayMode.shuffle) {
                                          playerProvider.setPlayMode(
                                            PlayMode.sequence,
                                          );
                                          return;
                                        }
                                        playerProvider.setPlayMode(
                                          PlayMode.shuffle,
                                        );
                                      },
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            iconSize: 48,
                                            color:
                                                (playerProvider.hasPrevious ||
                                                    playerProvider.playMode ==
                                                        PlayMode.loop)
                                                ? Colors.white
                                                : Colors.white70,
                                            icon: const Icon(
                                              Icons.skip_previous_rounded,
                                            ),
                                            onPressed: () =>
                                                playerProvider.previous(),
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            iconSize: 64,
                                            color: Colors.white,
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                            ),
                                            onPressed: () =>
                                                playerProvider.togglePlay(),
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            iconSize: 48,
                                            color:
                                                (playerProvider.hasNext ||
                                                    playerProvider.playMode ==
                                                        PlayMode.loop)
                                                ? Colors.white
                                                : Colors.white70,
                                            icon: const Icon(
                                              Icons.skip_next_rounded,
                                            ),
                                            onPressed: () =>
                                                playerProvider.next(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 20,
                                      color: Colors.white70,
                                      icon: Icon(
                                        playerProvider.playMode ==
                                                PlayMode.singleLoop
                                            ? Icons.repeat_one_rounded
                                            : Icons.repeat_rounded,
                                        color:
                                            playerProvider.playMode ==
                                                    PlayMode.loop ||
                                                playerProvider.playMode ==
                                                    PlayMode.singleLoop
                                            ? Colors.white
                                            : null,
                                      ),
                                      onPressed: () {
                                        if (playerProvider.playMode ==
                                            PlayMode.singleLoop) {
                                          playerProvider.setPlayMode(
                                            PlayMode.sequence,
                                          );
                                          return;
                                        }
                                        playerProvider.setPlayMode(
                                          playerProvider.playMode ==
                                                  PlayMode.loop
                                              ? PlayMode.singleLoop
                                              : PlayMode.loop,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 0),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.volume_down_rounded,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        playerProvider.setVolume(
                                          playerProvider.volume - 0.1,
                                        );
                                      },
                                    ),
                                    Expanded(
                                      child: AnimatedTrackHeightSlider(
                                        trackHeight: 4,
                                        value: playerProvider.volume,
                                        max: 1.0,
                                        min: 0,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                        onChanged: (value) {
                                          playerProvider.setVolume(value);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.volume_up_rounded,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        playerProvider.setVolume(
                                          playerProvider.volume + 0.1,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1), // 使用Spacer创建可变间距
                    Flexible(
                      flex: 20,
                      child: Center(
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.1, 0.9, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ScrollConfiguration(
                              behavior: NoGlowScrollBehavior(),
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const ClampingScrollPhysics(),
                                itemCount: 1 + lyrics.length + 2,
                                itemBuilder: (context, index) {
                                  if (index == 0)
                                    return SizedBox(height: placeholderHeight);
                                  int i = index - 1;
                                  if (i < lyrics.length) {
                                    return buildLyricLine(
                                      lyrics[i],
                                      i == currentLine,
                                      i,
                                      (idx) {
                                        // 精确跳转逻辑 - 点击哪行就跳到哪行
                                        if (parsedLyrics.isNotEmpty &&
                                            idx < parsedLyrics.length) {
                                          // 立即更新当前行索引，避免短暂滚动到上一条
                                          lastCurrentIndex = idx;
                                          // 直接跳转到点击行的精确时间
                                          playerProvider.seekTo(
                                            parsedLyrics[idx].timestamp,
                                          );
                                        } else {
                                          // 回退到原有逻辑
                                          lastCurrentIndex = idx;
                                          playerProvider.seekTo(
                                            Duration(seconds: idx * 3),
                                          );
                                        }
                                        scrollToCurrentLine(
                                          _scrollController,
                                          idx,
                                          0,
                                          lineHeights,
                                          placeholderHeight,
                                          force: true,
                                        );
                                      },
                                      (hover) {
                                        setState(() {
                                          isHoveringLyrics = hover;
                                        });
                                      },
                                    );
                                  } else {
                                    return const SizedBox(height: 500);
                                  }
                                },
                              ),
                            ),
                          ),
                        
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
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

class HoverableLyricLine extends StatefulWidget {
  final String text;
  final bool isCurrent;
  final Function(Size) onSizeChange;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;
  final bool isGloballyHovered;
  final int distanceToCurrentLine;

  const HoverableLyricLine({
    super.key,
    required this.text,
    required this.isCurrent,
    required this.onSizeChange,
    this.onTap,
    this.onHoverChanged,
    this.isGloballyHovered = false,
    required this.distanceToCurrentLine,
  });

  @override
  State<HoverableLyricLine> createState() => _HoverableLyricLineState();
}

class _HoverableLyricLineState extends State<HoverableLyricLine> {
  bool isHovered = false;

  void _updateHover(bool hover) {
    if (isHovered != hover) {
      setState(() => isHovered = hover);
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
              begin: (widget.isGloballyHovered || widget.isCurrent) ? 0 : (1 + widget.distanceToCurrentLine * 0.85).clamp(0, 2.7),
              end: (widget.isGloballyHovered || widget.isCurrent) ? 0 : (1 + widget.distanceToCurrentLine * 0.85).clamp(0, 2.7),//0-2.7模糊量
            ),
            duration: const Duration(milliseconds: 150),
            builder: (context, blurValue, child) {
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
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
                  fontSize: 32,
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

class HoverIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const HoverIconButton({super.key, required this.onPressed});

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(4), // 圆角大小
      onHover: (v) {
        setState(() {
          _isHovered = !_isHovered;
        });
      },
      child: Icon(
        _isHovered ? Icons.keyboard_arrow_down_rounded : Icons.remove_rounded,
        color: Colors.white,
        size: 50,
      ),
    );
  }
}
