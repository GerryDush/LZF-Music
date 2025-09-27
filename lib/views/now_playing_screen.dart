import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';

// --- 核心改动：导入新的歌词视图，并移除旧的 ---
import 'package:lzf_music/widgets/karaoke_lyrics_view.dart';
import 'package:lzf_music/widgets/lyrics_view.dart'; // <-- 保留您这个文件的导入，因为您的旧代码需要它

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
                  child: Row(
                    children: [
                      // ======================================================
                      // --- 左侧面板：保持您提供的代码一模一样，一个字不改 ---
                      // ======================================================
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 50,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 380,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HoverIconButton(
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child:
                                        currentSong?.albumArtPath != null &&
                                            File(
                                              currentSong!.albumArtPath!,
                                            ).existsSync()
                                        ? Image.file(
                                            File(currentSong.albumArtPath!),
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
                                  const SizedBox(height: 24),
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
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                    playerProvider: playerProvider,
                                  ),
                                  const SizedBox(height: 24),
                                  MusicControlButtons(
                                    playerProvider: playerProvider,
                                    isPlaying: isPlaying,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ======================================================
                      // --- 右侧歌词区域：进行唯一的替换 ---
                      // ======================================================
                      Flexible(
                        flex: 6,
                        child: Center(
                          child: SizedBox(
                            height: 660,
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
                    ],
                  ),
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
