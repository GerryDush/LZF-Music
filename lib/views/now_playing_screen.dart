import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/widgets/liquid_gradient_painter.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';
import 'package:flutter/services.dart';
import 'package:lzf_music/widgets/karaoke_lyrics_view.dart';
import 'package:lzf_music/widgets/music_control_panel.dart';

class ImprovedNowPlayingScreen extends StatefulWidget {
  const ImprovedNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedNowPlayingScreen> createState() =>
      _ImprovedNowPlayingScreenState();
}

class _ImprovedNowPlayingScreenState extends State<ImprovedNowPlayingScreen> {
  late ScrollController _scrollController;
  bool isHoveringLyrics = false;
  int lastCurrentIndex = -1;
  Map<int, double> lineHeights = {};
  double get placeholderHeight => 80;

  double _tempSliderValue = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final FocusNode _focusNode = FocusNode();
  int? _currentSongId;
  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Consumer<PlayerProvider>(
          builder: (context, playerProvider, child) {
            final currentSong = playerProvider.currentSong;
            final bool isPlaying = playerProvider.isPlaying;
            if (currentSong != null && currentSong.id != _currentSongId) {
              _currentSongId = currentSong.id;
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LiquidGeneratorPage(
                          liquidColors: currentSong!.palette,
                          isPlaying: isPlaying,
                        )
                      ],
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isNarrow = PlatformUtils.isMobileWidth(context);

                      if (isNarrow) {
                        return MobileLayout(
                          currentSong: currentSong,
                          playerProvider: playerProvider,
                          isPlaying: isPlaying,
                          tempSliderValue: _tempSliderValue,
                          onSliderChanged: (value) => setState(() => _tempSliderValue = value),
                          onSliderChangeEnd: (value) {
                            setState(() => _tempSliderValue = -1);
                            playerProvider.seekTo(Duration(seconds: value.toInt()));
                          },
                        );
                      }

                      return DesktopLayout(
                        currentSong: currentSong,
                        playerProvider: playerProvider,
                        isPlaying: isPlaying,
                        tempSliderValue: _tempSliderValue,
                        onSliderChanged: (value) => setState(() => _tempSliderValue = value),
                        onSliderChangeEnd: (value) {
                          setState(() => _tempSliderValue = -1);
                          playerProvider.seekTo(Duration(seconds: value.toInt()));
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ));
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

// 移动端顶部歌曲信息栏
class MobileSongHeader extends StatelessWidget {
  final dynamic currentSong;
  final VoidCallback onClose;

  const MobileSongHeader({
    Key? key,
    required this.currentSong,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 26,
          child: InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(4),
            child: const Icon(Icons.remove_rounded, color: Colors.white, size: 50),
          ),
        ),
        Row(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: currentSong.albumArtPath != null &&
                        File(currentSong.albumArtPath!).existsSync()
                    ? Image.file(File(currentSong.albumArtPath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentSong.artist ?? '未知艺术家',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 带渐变遮罩的歌词视图
class LyricsViewWithGradient extends StatelessWidget {
  final Widget lyricsView;
  final EdgeInsets padding;

  const LyricsViewWithGradient({
    Key? key,
    required this.lyricsView,
    this.padding = const EdgeInsets.only(top: 100.0, bottom: 210.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, 0.1, 0.9, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: lyricsView,
        ),
      ),
    );
  }
}

// 移动端布局
class MobileLayout extends StatefulWidget {
  final dynamic currentSong;
  final PlayerProvider playerProvider;
  final bool isPlaying;
  final double tempSliderValue;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;

  const MobileLayout({
    Key? key,
    required this.currentSong,
    required this.playerProvider,
    required this.isPlaying,
    required this.tempSliderValue,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
  }) : super(key: key);

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  bool _showControlPanel = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _showControlPanel = false);
      }
    });
  }

  void _showControls() {
    if (!_showControlPanel) {
      setState(() => _showControlPanel = true);
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsView = KaraokeLyricsView(
      key: ValueKey('mobile_${widget.currentSong.id}'),
      lyricsData: widget.currentSong.lyricsBlob,
      currentPosition: widget.playerProvider.position,
      onTapLine: (time) {
        widget.playerProvider.seekTo(time);
        _showControls();
      },
    );

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // 检测向下滑动
        if (details.delta.dy > 0) {
          _showControls();
        }
      },
      onTap: () => _showControls(),
      child: DraggableCloseContainer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.only(
                  top: 100.0,
                  bottom: _showControlPanel ? 184.0 : 8.0,
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                        stops: [0.0, 0.1, 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: lyricsView,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MobileSongHeader(
                        currentSong: widget.currentSong,
                        onClose: () => Navigator.pop(context),
                      ),
                      AnimatedOpacity(
                        opacity: _showControlPanel ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedSlide(
                          offset: _showControlPanel ? Offset.zero : const Offset(0, 0.5),
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showControlPanel,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SongInfoPanel(
                                    compactLayout: true,
                                    tempSliderValue: widget.tempSliderValue,
                                    onSliderChanged: (value) {
                                      widget.onSliderChanged(value);
                                      _showControls();
                                    },
                                    onSliderChangeEnd: (value) {
                                      widget.onSliderChangeEnd(value);
                                      _showControls();
                                    },
                                    playerProvider: widget.playerProvider,
                                  ),
                                  const SizedBox(height: 4),
                                  MusicControlButtons(
                                    playerProvider: widget.playerProvider,
                                    isPlaying: widget.isPlaying,
                                    compactLayout: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
}

// 桌面端布局
class DesktopLayout extends StatelessWidget {
  final dynamic currentSong;
  final PlayerProvider playerProvider;
  final bool isPlaying;
  final double tempSliderValue;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;

  const DesktopLayout({
    Key? key,
    required this.currentSong,
    required this.playerProvider,
    required this.isPlaying,
    required this.tempSliderValue,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lyricsView = KaraokeLyricsView(
      key: ValueKey('desktop_${currentSong.id}'),
      lyricsData: currentSong.lyricsBlob,
      currentPosition: playerProvider.position,
      onTapLine: (time) => playerProvider.seekTo(time),
    );

    return DraggableCloseContainer(
      child: Row(
        children: [
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: CommonUtils.select(
                    MediaQuery.of(context).size.width > 1300,
                    t: 380,
                    f: 336,
                  ),
                  height: 700,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          HoverIconButton(onPressed: () => Navigator.pop(context)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: currentSong.albumArtPath != null &&
                                    File(currentSong.albumArtPath!).existsSync()
                                ? Image.file(
                                    File(currentSong.albumArtPath!),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 300,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 48),
                                  ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SongInfoPanel(
                              tempSliderValue: tempSliderValue,
                              onSliderChanged: onSliderChanged,
                              onSliderChangeEnd: onSliderChangeEnd,
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
          Flexible(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: SizedBox(
                  width: 480,
                  child: LyricsViewWithGradient(
                    lyricsView: lyricsView,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        ],
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

class DraggableCloseContainer extends StatefulWidget {
  final Widget child;
  final double topFraction;
  final double distanceThreshold;
  final double velocityThreshold;

  const DraggableCloseContainer({
    Key? key,
    required this.child,
    this.topFraction = 0.7,
    this.distanceThreshold = 140.0,
    this.velocityThreshold = 700.0,
  }) : super(key: key);

  @override
  _DraggableCloseContainerState createState() =>
      _DraggableCloseContainerState();
}

class _DraggableCloseContainerState extends State<DraggableCloseContainer> {
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  bool _isDraggingForClose = false;
  String? _dragAxis;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        final startDy = details.globalPosition.dy;
        final screenH = MediaQuery.of(context).size.height;
        _isDraggingForClose = startDy <= screenH * widget.topFraction;
        _dragAxis = null; // reset axis lock
      },
      onPanUpdate: (details) {
        if (!_isDraggingForClose) return;

        if (_dragAxis == null) {
          final dx = details.delta.dx.abs();
          final dy = details.delta.dy.abs();
          const axisLockThreshold = 4.0;
          if (dx >= axisLockThreshold || dy >= axisLockThreshold) {
            _dragAxis = dx > dy ? 'x' : 'y';
          } else {
            return;
          }
        }

        setState(() {
          if (_dragAxis == 'x') {
            _dragOffsetX =
                (_dragOffsetX + details.delta.dx).clamp(-50.0, 500.0);
          } else if (_dragAxis == 'y') {
            _dragOffsetY =
                (_dragOffsetY + details.delta.dy).clamp(-50.0, 500.0);
          }
        });
      },
      onPanEnd: (details) {
        if (!_isDraggingForClose) return;
        _isDraggingForClose = false;

        final axis = _dragAxis;
        _dragAxis = null;

        final vx = details.velocity.pixelsPerSecond.dx;
        final vy = details.velocity.pixelsPerSecond.dy;

        bool shouldClose = false;
        if (axis == 'x') {
          shouldClose = _dragOffsetX > widget.distanceThreshold ||
              vx > widget.velocityThreshold;
        } else if (axis == 'y') {
          shouldClose = _dragOffsetY > widget.distanceThreshold ||
              vy > widget.velocityThreshold;
        } else {
          shouldClose = _dragOffsetX > widget.distanceThreshold ||
              _dragOffsetY > widget.distanceThreshold ||
              vx > widget.velocityThreshold ||
              vy > widget.velocityThreshold;
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
        child: widget.child,
      ),
    );
  }
}
