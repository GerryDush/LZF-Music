import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';

// --- 核心改动：导入新的歌词视图，并移除旧的 ---
import 'package:lzf_music/widgets/karaoke_lyrics_view.dart';

// 保持您项目中所有其他导入不变
import 'package:lzf_music/widgets/music_control_panel.dart';

// 改进的NowPlayingScreen
class ImprovedNowPlayingScreen extends StatefulWidget {
  const ImprovedNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedNowPlayingScreen> createState() =>
      _ImprovedNowPlayingScreenState();
}

class _ImprovedNowPlayingScreenState extends State<ImprovedNowPlayingScreen> {
  // --- 核心改动：只删除与右侧ListView直接相关的状态 ---
  late ScrollController _scrollController;
  Timer? _timer;
  bool isHoveringLyrics = false;
  int lastCurrentIndex = -1;
  Map<int, double> lineHeights = {};
  double get placeholderHeight => 80;

  double _tempSliderValue = -1;
  // 拖动退出支持
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  bool _isDraggingForClose = false;
  // null = not determined, 'x' = horizontal, 'y' = vertical
  String? _dragAxis;

  @override
  void initState() {
    super.initState();
    // --- 核心改动：这些状态由 KaraokeLyricsView 内部管理，但为了不影响您左侧面板，我们暂时保留 ---
    // --- 如果您的旧代码不再需要它们，可以安全删除 ---
    _scrollController = ScrollController();
    _startLyricsTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // 保持您这个方法不变，即使右侧不再直接使用它
  void _startLyricsTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;
        final bool isPlaying = playerProvider.isPlaying;

        // final int currentLine = lyricsResult.currentLine; // 右侧不再需要
        // final List<String> lyrics = lyricsResult.lyrics; // 右侧不再需要

        return FocusScope(
          canRequestFocus: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 背景部分保持完全不变
                ClipRect(
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
                        child: Container(
                          color: Colors.black87.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = PlatformUtils.isMobileWidth(context);
                    if (isNarrow) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (details) {
                          // 仅当手势从上半部分（或自定义阈值）开始时才启用拖动退出，避免拦截底部控件
                          final startDy = details.globalPosition.dy;
                          final screenH = MediaQuery.of(context).size.height;
                          const topFraction = 0.7; // 触点需在顶部 70% 区域内才启用
                          _isDraggingForClose = startDy <= screenH * topFraction;
                          // reset axis lock for this gesture
                          _dragAxis = null;
                        },
                        onPanUpdate: (details) {
                          if (!_isDraggingForClose) return; // 非顶部起始不处理

                          // If axis is not yet decided, pick the dominant axis after a small threshold
                          if (_dragAxis == null) {
                            final dx = details.delta.dx.abs();
                            final dy = details.delta.dy.abs();
                            const axisLockThreshold = 4.0; // pixels
                            if (dx >= axisLockThreshold || dy >= axisLockThreshold) {
                              _dragAxis = dx > dy ? 'x' : 'y';
                            } else {
                              // not enough movement yet to decide
                              return;
                            }
                          }
                          setState(() {
                            if (_dragAxis == 'x') {
                              // horizontal drag: ignore vertical movement
                              _dragOffsetX = (_dragOffsetX + details.delta.dx)
                                  .clamp(-50.0, 500.0);
                            } else if (_dragAxis == 'y') {
                              // vertical drag: ignore horizontal movement
                              _dragOffsetY = (_dragOffsetY + details.delta.dy)
                                  .clamp(-50.0, 500.0);
                            }
                          });
                        },
                        onPanEnd: (details) {
                          if (!_isDraggingForClose) return;
                          _isDraggingForClose = false;
                          // reset axis lock
                          final axis = _dragAxis;
                          _dragAxis = null;

                          // 阈值：位移或速度达到则退出
                          const distanceThreshold = 140.0;
                          const velocityThreshold = 700.0;

                          final vx = details.velocity.pixelsPerSecond.dx;
                          final vy = details.velocity.pixelsPerSecond.dy;

                          bool shouldClose = false;
                          if (axis == 'x') {
                            final shouldCloseByRight =
                                _dragOffsetX > distanceThreshold ||
                                    (vx > velocityThreshold);
                            shouldClose = shouldCloseByRight;
                          } else if (axis == 'y') {
                            final shouldCloseByDown =
                                _dragOffsetY > distanceThreshold ||
                                    (vy > velocityThreshold);
                            shouldClose = shouldCloseByDown;
                          } else {
                            // fallback: if either exceeds threshold
                            shouldClose = _dragOffsetX > distanceThreshold ||
                                _dragOffsetY > distanceThreshold ||
                                vx > velocityThreshold ||
                                vy > velocityThreshold;
                          }

                          if (shouldClose) {
                            Navigator.maybePop(context);
                          } else {
                            // 回弹
                            setState(() {
                              _dragOffsetX = 0.0;
                              _dragOffsetY = 0.0;
                            });
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(_dragOffsetX > 0 ? _dragOffsetX : 0.0,
                              _dragOffsetY > 0 ? _dragOffsetY : 0.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 歌词作为背景层（放在最下方，但在我们之前的模糊背景之上）
                              Positioned.fill(
                                child: Center(
                                    child: Padding(
                                  padding: EdgeInsets.only(
                                      left: 0.0,
                                      right: 0.0,
                                      top: 130.0,
                                      bottom: 300.0),
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
                                    child: KaraokeLyricsView(
                                      key: ValueKey(currentSong!.id),
                                      lyricsContent: currentSong.lyrics,
                                      currentPosition: playerProvider
                                          .position, // 直接传递Duration
                                      onTapLine: (time) {
                                        playerProvider.seekTo(time);
                                      },
                                    ),
                                  ),
                                )),
                              ),

                              // 左侧面板放在前面（移动端：居中显示，并限制最大宽度以避免溢出）
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 0,
                                        bottom: 20),
                                    child: Column(
                                        // 顶部显示封面和标题，底部显示控制按钮
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              InkWell(
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Icon(
                                                  Icons.remove_rounded,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  
                                                  // 专辑封面
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxWidth: 60),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: currentSong
                                                                      ?.albumArtPath !=
                                                                  null &&
                                                              File(currentSong!
                                                                      .albumArtPath!)
                                                                  .existsSync()
                                                          ? Image.file(
                                                              File(currentSong
                                                                  .albumArtPath!),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Container(
                                                              color: Colors
                                                                  .grey[800],
                                                              child: const Icon(
                                                                Icons
                                                                    .music_note_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 40,
                                                              ),
                                                            ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 20),

                                                  // 歌曲信息
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          currentSong?.title ??
                                                              '未知歌曲',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          currentSong?.artist ??
                                                              '未知艺术家',
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.7),
                                                            fontSize: 16
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                        
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SongInfoPanel(
                                                  tempSliderValue:
                                                      _tempSliderValue,
                                                  onSliderChanged: (value) {
                                                    setState(() {
                                                      _tempSliderValue = value;
                                                    });
                                                  },
                                                  onSliderChangeEnd: (value) {
                                                    setState(() {
                                                      _tempSliderValue = -1;
                                                    });
                                                    playerProvider.seekTo(
                                                      Duration(
                                                          seconds:
                                                              value.toInt()),
                                                    );
                                                  },
                                                  playerProvider:
                                                      playerProvider,
                                                ),
                                                const SizedBox(height: 8),
                                                MusicControlButtons(
                                                  playerProvider:
                                                      playerProvider,
                                                  isPlaying: isPlaying,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 宽屏：保持原来的左右分栏布局
                    return Row(
                      children: [
                        // 左侧面板
                        Flexible(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 20,
                              left: 20,
                              right: 20
                            ),
                            child: Center(
                              child: SizedBox(
                                width: CommonUtils.select(MediaQuery.of(context).size.width>1300, t: 380, f: 320),
                                height: 700,
                                child: Column(
                                  // 顶部显示封面和标题，底部显示控制按钮
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        HoverIconButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: currentSong?.albumArtPath !=
                                                      null &&
                                                  File(currentSong!
                                                          .albumArtPath!)
                                                      .existsSync()
                                              ? Image.file(
                                                  File(currentSong
                                                      .albumArtPath!),
                                                  width: double.infinity,
                                                  height: 300,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: 260,
                                                  color: Colors.grey[800],
                                                  child: const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.white,
                                                    size: 48,
                                                  ),
                                                ),
                                        ),
                                        
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SongInfoPanel(
                                            tempSliderValue: _tempSliderValue,
                                            onSliderChanged: (value) {
                                              setState(() {
                                                _tempSliderValue = value;
                                              });
                                            },
                                            onSliderChangeEnd: (value) {
                                              setState(() {
                                                _tempSliderValue = -1;
                                              });
                                              playerProvider.seekTo(
                                                Duration(
                                                    seconds: value.toInt()),
                                              );
                                            },
                                            playerProvider: playerProvider,
                                          ),
                                          const SizedBox(height: 8),
                                          MusicControlButtons(
                                            playerProvider: playerProvider,
                                            isPlaying: isPlaying,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 右侧歌词
                        Flexible(
                          flex: 5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 60.0, bottom: 60.0),
                              child: SizedBox(
                                width: 480,
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
                                  child: KaraokeLyricsView(
                                    key: ValueKey(currentSong!.id),
                                    lyricsContent: currentSong.lyrics,
                                    currentPosition:
                                        playerProvider.position, // 直接传递Duration
                                    onTapLine: (time) {
                                      playerProvider.seekTo(time);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // formatDuration 保持不变，因为您的旧UI可能需要
  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

// MeasureSize 保持不变，因为您的旧UI可能需要
class MeasureSize extends StatefulWidget {
  final Widget child;
  final Function(Size) onChange;

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
