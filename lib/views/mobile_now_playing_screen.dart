import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';
import 'package:lzf_music/widgets/lyrics_view.dart';
import 'package:lzf_music/widgets/music_control_panel.dart';

/// 移动端正在播放页面
class MobileNowPlayingScreen extends StatefulWidget {
  const MobileNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<MobileNowPlayingScreen> createState() => _MobileNowPlayingScreenState();
}

class _MobileNowPlayingScreenState extends State<MobileNowPlayingScreen> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool isHoveringLyrics = false;

  // 歌词相关属性
  List<LyricLine> parsedLyrics = [];
  int lastCurrentIndex = -1;
  Map<int, double> lineHeights = {};
  double get placeholderHeight => 60;

  // 拖动相关属性
  double _dragOffset = 0.0; // 拖动偏移量
  bool _isDragging = false; // 是否正在拖动
  
  // 进度条控制
  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startLyricsTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startLyricsTimer() {
    _timer?.cancel();
    _timer = LyricsTimerManager.startLyricsTimer(
      () => mounted,
      () => Provider.of<PlayerProvider>(context, listen: false),
      parsedLyrics,
      () => lastCurrentIndex,
      (value) => lastCurrentIndex = value,
      () => setState(() {}),
      _scrollController,
      lineHeights,
      placeholderHeight,
      () => isHoveringLyrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final currentSong = playerProvider.currentSong;
          final bool isPlaying = playerProvider.isPlaying;
          final double currentPosition = playerProvider.position.value.inSeconds.toDouble();
          final double totalDuration = playerProvider.duration.inSeconds.toDouble();

          // 处理歌词数据
          final lyricsResult = LyricsDataProcessor.processLyricsData(
            lyricsContent: currentSong?.lyrics,
            totalDuration: playerProvider.duration,
            currentPosition: playerProvider.position.value,
            parsedLyrics: parsedLyrics,
          );
          
          final int currentLine = lyricsResult.currentLine;
          final List<String> lyrics = lyricsResult.lyrics;

          return GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                // 累加拖动距离，只允许向下拖动
                if (details.delta.dy > 0) {
                  _dragOffset += details.delta.dy;
                } else if (_dragOffset > 0) {
                  // 向上拖动时减少偏移量，但不能小于0
                  _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
                }
              });
            },
            onPanEnd: (details) {
              final double screenHeight = MediaQuery.of(context).size.height;
              final double velocity = details.velocity.pixelsPerSecond.dy;
              
              // 如果拖动距离超过屏幕1/4或者向下拖动速度很快，关闭页面
              if (_dragOffset > screenHeight / 4 || velocity > 600) {
                Navigator.of(context).pop();
              } else {
                // 否则弹回原位置
                setState(() {
                  _dragOffset = 0.0;
                  _isDragging = false;
                });
              }
            },
            child: AnimatedContainer(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _dragOffset, 0),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图片和高斯模糊
                  _buildBackground(currentSong),
                  
                  // 主要内容
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final topSpaceHeight = 18.0; // 4%
                        final songInfoHeight = 75.0; // 13%
                        final lyricsHeight = constraints.maxHeight - 213 - 12 - 75;
                        final controlPanelHeight = 67.0; // 18%
                        final controlButtonsHeight = 140.0; // 17%

                        return Column(
                          children: [
                            // 顶部把手图标区域 + 歌曲信息区域
                            Container(
                              height: topSpaceHeight + songInfoHeight,
                              child: Column(
                                children: [
                                  // 顶部把手图标
                                  SizedBox(
                                    height: topSpaceHeight,
                                    child: Center(
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        width: 30,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 中间20%显示歌曲信息
                                  SizedBox(
                                    height: songInfoHeight,
                                    child: _buildSongInfoSection(
                                      currentSong,
                                      currentPosition,
                                      totalDuration,
                                      playerProvider,
                                      isPlaying,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 剩余63%显示歌词
                            SizedBox(
                              height: lyricsHeight,
                              child: _buildLyricsSection(
                                lyrics,
                                currentLine,
                                playerProvider,
                              ),
                            ),

                            // 底部20%显示控制面板
                            SizedBox(
                              height: controlPanelHeight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: SongInfoPanel(
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
                                      Duration(seconds: (value * totalDuration).round()),
                                    );
                                  },
                                  playerProvider: playerProvider,
                                  compactLayout: true,
                                ),
                              ),
                            ),

                            // 底部17%显示控制按钮
                            SizedBox(
                              height: controlButtonsHeight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: MusicControlButtons(
                                  playerProvider: playerProvider,
                                  isPlaying: isPlaying,
                                  compactLayout: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }

  /// 构建背景
  Widget _buildBackground(currentSong) {
    return ClipRect(
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
    );
  }

  /// 构建歌曲信息部分
  Widget _buildSongInfoSection(
    currentSong,
    double currentPosition,
    double totalDuration,
    PlayerProvider playerProvider,
    bool isPlaying,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 专辑封面
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const SizedBox(width: 14),
                // 专辑封面
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: currentSong?.albumArtPath != null &&
                              File(currentSong!.albumArtPath!).existsSync()
                          ? Image.file(
                              File(currentSong.albumArtPath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSong?.title ?? '未知歌曲',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PingFang SC',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong?.artist ?? '未知艺术家',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: 'PingFang SC',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  /// 构建歌词部分
  Widget _buildLyricsSection(
    List<String> lyrics,
    int currentLine,
    PlayerProvider playerProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          
          // 歌词列表
          Expanded(
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
                  stops: [0.0, 0.15, 0.85, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ScrollConfiguration(
                behavior: NoGlowScrollBehavior(),
                child: lyrics.isEmpty
                    ? Center(
                        child: Text(
                          '暂无歌词',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: 1 + lyrics.length + 2,
                        itemBuilder: (context, index) {
                          return LyricsListItemBuilder.buildItem(
                            context: context,
                            index: index,
                            lyrics: lyrics,
                            currentLine: currentLine,
                            placeholderHeight: placeholderHeight,
                            lineHeights: lineHeights,
                            parsedLyrics: parsedLyrics,
                            getLastCurrentIndex: () => lastCurrentIndex,
                            setLastCurrentIndex: (value) => lastCurrentIndex = value,
                            setState: () => setState(() {}),
                            setHoveringState: (hover) => setState(() {
                              isHoveringLyrics = hover;
                            }),
                            scrollController: _scrollController,
                            isHoveringLyrics: isHoveringLyrics,
                            playerProvider: playerProvider,
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

/// 无滚动发光效果的行为
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
