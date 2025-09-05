import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/lyrics_widget.dart';
import '../widgets/player_control_panel.dart';
import '../services/player_provider.dart';

// 改进的NowPlayingScreen
class ImprovedNowPlayingScreen extends StatefulWidget {
  const ImprovedNowPlayingScreen({super.key});
  @override
  State<ImprovedNowPlayingScreen> createState() =>
      _ImprovedNowPlayingScreenState();
}

class _ImprovedNowPlayingScreenState extends State<ImprovedNowPlayingScreen> {
  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;

        return Scaffold(
          body: Stack(
            children: [
              // 背景部分
              if (currentSong?.albumArtPath != null &&
                  File(currentSong!.albumArtPath!).existsSync())
                Positioned.fill(
                  child: Image.file(
                    File(currentSong.albumArtPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              // 背景滤镜
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // 主要内容
              SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 最左侧空白区域
                    const Spacer(flex: 2),
                    // 左侧播放控制面板
                    Flexible(
                      flex: 24,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PlayerControlPanel(
                          playerProvider: playerProvider,
                          tempSliderValue: _tempSliderValue,
                          onClosePressed: () => Navigator.of(context).pop(),
                          onSliderChanged: (value) {
                            setState(() {
                              _tempSliderValue = value;
                            });
                          },
                          onSliderChangeEnd: (value) {
                            // 跳转到指定位置
                            playerProvider.seekTo(Duration(seconds: value.toInt()));
                            setState(() {
                              _tempSliderValue = -1;
                            });
                          },
                        ),
                      ),
                    ),
                    // 间距
                    const Spacer(flex: 8),
                    // 右侧歌词
                    Flexible(
                      flex: 28,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: LyricsDisplayWidget(
                          playerProvider: playerProvider,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
