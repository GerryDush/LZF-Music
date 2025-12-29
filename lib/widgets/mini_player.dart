import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lzf_music/database/database.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:provider/provider.dart';
import '../views/now_playing_screen.dart';
import '../services/player_provider.dart';
import './slider_custom.dart';
import '../contants/app_contants.dart' show PlayMode;
import '../utils/common_utils.dart' show CommonUtils;

class MiniPlayer extends StatefulWidget {
  final double containerWidth;
  final bool isMobile;

  const MiniPlayer({
    super.key,
    this.containerWidth = double.infinity,
    this.isMobile = false,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  Widget build(BuildContext context) {
    // 根据容器宽度决定显示哪些控件
    final showVolumeControl = widget.containerWidth > 778;
    final showProgressControl = widget.containerWidth > 660;
    double progressLength = (widget.containerWidth - 520).clamp(260, 330);
    if (!showProgressControl) {
      progressLength = widget.containerWidth - 268;
    }
    final activeColor = ThemeUtils.select(
      context,
      light: Colors.black87,
      dark: Colors.white,
    );
    final inactiveColor = ThemeUtils.select(
      context,
      light: Colors.black26,
      dark: Colors.white30,
    );

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;

        return Padding(
          padding: EdgeInsets.all(CommonUtils.select(PlatformUtils.isMobileWidth(context), t: 4, f: 6)),
          child: Row(
            children: [
              SizedBox(width: CommonUtils.select(PlatformUtils.isMobileWidth(context), t: 4, f: 3)),
              // 歌曲封面
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    pushToNowPlayingScreen(context, currentSong);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: CommonUtils.select(showProgressControl,
                            t: 54, f: 40),
                        height: CommonUtils.select(showProgressControl,
                            t: 52, f: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          image: currentSong?.albumArtPath != null
                              ? DecorationImage(
                                  image: FileImage(
                                    File(currentSong!.albumArtPath!),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: currentSong?.albumArtPath == null
                            ? const Icon(Icons.music_note_rounded, size: 24)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 歌曲信息
              SizedBox(
                width: progressLength, // 固定宽度
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if(!PlatformUtils.isMobileWidth(context)) SizedBox(height: 4,),
                    MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                            onTap: () {
                              pushToNowPlayingScreen(context, currentSong);
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                currentSong?.title ?? '未播放',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                  onTap: () {
                                    pushToNowPlayingScreen(
                                        context, currentSong);
                                  },
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      currentSong?.artist ?? '选择歌曲开始播放',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))),
                        ),
                        if (showProgressControl)
                          SizedBox(
                            width: 101,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ValueListenableBuilder<Duration>(
                                  valueListenable: playerProvider.position,
                                  builder: (context, position, child) {
                                    return Text(
                                      "${CommonUtils.formatDuration(position)}/${CommonUtils.formatDuration(playerProvider.duration)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 30),
                      ],
                    ),
                    if (showProgressControl) ...[
                      Row(
                        children: [
                          // 进度条
                          Expanded(
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: playerProvider.position,
                              builder: (context, position, child) {
                                double sliderValue = (_tempSliderValue >= 0
                                        ? _tempSliderValue
                                        : (playerProvider
                                                    .duration.inMilliseconds >
                                                0
                                            ? position.inMilliseconds /
                                                playerProvider
                                                    .duration.inMilliseconds
                                            : 0.0))
                                    .clamp(0.0, 1.0);

                                return AnimatedTrackHeightSlider(
                                  trackHeight: 4,
                                  value: sliderValue,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: currentSong != null
                                      ? (value) {
                                          setState(() {
                                            _tempSliderValue = value; // 拖动时暂存
                                          });
                                        }
                                      : null,
                                  onChangeEnd: currentSong != null
                                      ? (value) async {
                                          final newPosition = Duration(
                                            milliseconds: (value *
                                                    playerProvider.duration
                                                        .inMilliseconds)
                                                .round(),
                                          );
                                          await playerProvider.seekTo(
                                            newPosition,
                                          );
                                          setState(() {
                                            _tempSliderValue = -1; // 复位
                                          });
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 30),
                        ],
                      ),
                    ] else
                      ...[],
                  ],
                ),
              ),

              Spacer(), // 右侧弹性空白
              // 音量控制
              if (showVolumeControl) ...[
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        playerProvider.volume <= 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        size: 20,
                      ),
                      onPressed: currentSong != null
                          ? () {
                              if (playerProvider.volume > 0) {
                                playerProvider.setVolume(0);
                              } else {
                                playerProvider.setVolume(1);
                              }
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 100,
                      child: AnimatedTrackHeightSlider(
                        trackHeight: 4,
                        value: playerProvider.volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: currentSong != null
                            ? (value) {
                                playerProvider.setVolume(value);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
              // 播放模式按钮 - 只在显示进度条时显示
              if (showProgressControl) ...[
                IconButton(
                  iconSize: 20,
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: playerProvider.playMode == PlayMode.shuffle
                        ? activeColor
                        : inactiveColor,
                  ),
                  onPressed: () {
                    if (playerProvider.playMode == PlayMode.shuffle) {
                      playerProvider.setPlayMode(PlayMode.sequence);
                      return;
                    }
                    playerProvider.setPlayMode(PlayMode.shuffle);
                  },
                ),
                IconButton(
                  iconSize: 20,
                  icon: Icon(
                    playerProvider.playMode == PlayMode.singleLoop
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: playerProvider.playMode == PlayMode.loop ||
                            playerProvider.playMode == PlayMode.singleLoop
                        ? activeColor
                        : inactiveColor,
                  ),
                  onPressed: () {
                    if (playerProvider.playMode == PlayMode.singleLoop) {
                      playerProvider.setPlayMode(PlayMode.sequence);
                      return;
                    }
                    playerProvider.setPlayMode(
                      playerProvider.playMode == PlayMode.loop
                          ? PlayMode.singleLoop
                          : PlayMode.loop,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],

              // 控制按钮
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 上一首按钮
                  IconButton(
                    color: activeColor,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size:
                          CommonUtils.select(showProgressControl, t: 40, f: 32),
                    ),
                    onPressed: (playerProvider.playMode == PlayMode.sequence &&
                            !playerProvider.hasPrevious)
                        ? null
                        : () async {
                            try {
                              await playerProvider.previous();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('播放失败: $e')),
                                );
                              }
                            }
                          },
                  ),
                  // 播放/暂停按钮
                  IconButton(
                    color: activeColor,
                    icon: Icon(
                      playerProvider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size:
                          CommonUtils.select(showProgressControl, t: 40, f: 32),
                    ),
                    onPressed: currentSong != null
                        ? () async {
                            try {
                              await playerProvider.togglePlay();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('操作失败: $e')),
                                );
                              }
                            }
                          }
                        : null,
                  ),
                  // 下一首按钮
                  IconButton(
                    color: activeColor,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size:
                          CommonUtils.select(showProgressControl, t: 40, f: 32),
                    ),
                    onPressed: (playerProvider.playMode == PlayMode.sequence &&
                            !playerProvider.hasNext)
                        ? null
                        : () async {
                            try {
                              await playerProvider.next();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('播放失败: $e')),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

void pushToNowPlayingScreen(BuildContext context, Song? currentSong) {
  if (currentSong == null) return;
  Navigator.push(
    context,
    PageRouteBuilder(
      settings: const RouteSettings(name: 'NowPlayingScreen'),
      transitionDuration: const Duration(
        milliseconds: 300,
      ), // 动画时长
      pageBuilder: (context, animation, secondaryAnimation) {
        return ImprovedNowPlayingScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    ),
  );
}

void _showPlaylist(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "关闭",
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 300,
          decoration: BoxDecoration(color: Colors.white),
          child: const Center(child: Text("开发中敬请期待..")),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final curvedAnim = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3), // 从下方 30% 的位置开始
          end: Offset.zero,
        ).animate(curvedAnim),
        child: FadeTransition(opacity: curvedAnim, child: child),
      );
    },
  );
}
