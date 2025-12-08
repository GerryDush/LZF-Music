import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/widgets/liquid_gradient_painter.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/lyric/lyrics_models.dart';
import '../widgets/lyric/lyrics_parser.dart';
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
  LyricsData? _cachedLyricsData;
  List<Color>? _extractedColors;
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
              _cachedLyricsData = null;
              LyricsParser.parse(currentSong.lyrics ?? "").then((data) {
                if (mounted && _currentSongId == currentSong.id) {
                  setState(() {
                    _cachedLyricsData = data;
                  });
                }
              });
              extractColorsFromImages(
                  playerProvider.currentSong?.albumArtPath != null
                      ? [File(playerProvider.currentSong!.albumArtPath!)]
                      : []).then((v){
                        setState((){
                          _extractedColors = v;
                          print(_extractedColors);
                        });
                      });
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [LiquidGeneratorPage(liquidColors: _extractedColors)],
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isNarrow = PlatformUtils.isMobileWidth(context);

                      final lyricsView = KaraokeLyricsView(
                        key: ValueKey(currentSong?.id ?? 'none'),
                        lyricsData: _cachedLyricsData,
                        currentPosition: playerProvider.position,
                        onTapLine: (time) => playerProvider.seekTo(time),
                      );

                      if (isNarrow) {
                        return DraggableCloseContainer(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: Center(
                                    child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 100.0, bottom: 210.0),
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
                                    child: lyricsView,
                                  ),
                                )),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 20),
                                    child: Column(
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
                                              child: const Icon(
                                                  Icons.remove_rounded,
                                                  color: Colors.white,
                                                  size: 50),
                                            ),
                                            if (currentSong != null)
                                              Row(
                                                children: [
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxWidth: 60),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: currentSong
                                                                      .albumArtPath !=
                                                                  null &&
                                                              File(currentSong
                                                                      .albumArtPath!)
                                                                  .existsSync()
                                                          ? Image.file(
                                                              File(currentSong
                                                                  .albumArtPath!),
                                                              fit: BoxFit.cover)
                                                          : Container(
                                                              color: Colors
                                                                  .grey[800],
                                                              child: const Icon(
                                                                  Icons.music_note_rounded,
                                                                  color: Colors.white,
                                                                  size: 40)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(currentSong.title,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                            currentSong
                                                                    .artist ??
                                                                '未知艺术家',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.7),
                                                                fontSize: 16),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis),
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
                                                compactLayout: true,
                                                tempSliderValue:
                                                    _tempSliderValue,
                                                onSliderChanged: (value) =>
                                                    setState(() =>
                                                        _tempSliderValue =
                                                            value),
                                                onSliderChangeEnd: (value) {
                                                  setState(() =>
                                                      _tempSliderValue = -1);
                                                  playerProvider.seekTo(
                                                      Duration(
                                                          seconds:
                                                              value.toInt()));
                                                },
                                                playerProvider: playerProvider,
                                              ),
                                              const SizedBox(height: 8),
                                              MusicControlButtons(
                                                  playerProvider:
                                                      playerProvider,
                                                  isPlaying: isPlaying),
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
                        );
                      }

                      return DraggableCloseContainer(
                        child: Row(
                          children: [
                            Flexible(
                              flex: 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: SizedBox(
                                    width: CommonUtils.select(
                                        MediaQuery.of(context).size.width >
                                            1300,
                                        t: 380,
                                        f: 336),
                                    height: 700,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            HoverIconButton(
                                                onPressed: () =>
                                                    Navigator.pop(context)),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: currentSong
                                                              ?.albumArtPath !=
                                                          null &&
                                                      File(currentSong!
                                                              .albumArtPath!)
                                                          .existsSync()
                                                  ? Image.file(
                                                      File(currentSong
                                                          .albumArtPath!),
                                                      width: double.infinity,
                                                      height: 300,
                                                      fit: BoxFit.cover)
                                                  : Container(
                                                      width: double.infinity,
                                                      height: 260,
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                          Icons
                                                              .music_note_rounded,
                                                          color: Colors.white,
                                                          size: 48)),
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
                                                onSliderChanged: (value) =>
                                                    setState(() =>
                                                        _tempSliderValue =
                                                            value),
                                                onSliderChangeEnd: (value) {
                                                  setState(() =>
                                                      _tempSliderValue = -1);
                                                  playerProvider.seekTo(
                                                      Duration(
                                                          seconds:
                                                              value.toInt()));
                                                },
                                                playerProvider: playerProvider,
                                              ),
                                              const SizedBox(height: 8),
                                              MusicControlButtons(
                                                  playerProvider:
                                                      playerProvider,
                                                  isPlaying: isPlaying),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 60.0),
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
                                            Colors.transparent
                                          ],
                                          stops: [0.0, 0.1, 0.9, 1.0],
                                        ).createShader(rect);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: lyricsView,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
