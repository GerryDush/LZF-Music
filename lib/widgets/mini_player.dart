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
import 'album_cover.dart';
import 'song_info_text.dart';
import 'playback_controls.dart';

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
                  child: RoundAlbumCover(
                    coverPath: currentSong?.albumArtPath,
                    size: CommonUtils.select(showProgressControl, t: 54, f: 40),
                    iconSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 歌曲信息
              SizedBox(
                width: progressLength, // 固定宽度
                child: SongTitleAndArtist(
                  title: currentSong?.title ?? '未播放',
                  artist: currentSong?.artist ?? '选择歌曲开始播放',
                  scrollable: true,
                  onTap: () => pushToNowPlayingScreen(context, currentSong),
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  artistStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
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
                VolumeControl(
                  playerProvider: playerProvider,
                  iconSize: 20,
                  sliderWidth: 100,
                  trackHeight: 4,
                  sliderBuilder: (value, onChanged) => AnimatedTrackHeightSlider(
                    trackHeight: 4,
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: currentSong != null ? (v) => onChanged(v) : null,
                  ),
                ),
                const SizedBox(width: 20),
              ],
              // 播放模式按钮 - 只在显示进度条时显示
              if (showProgressControl) ...[
                PlayModeButton(
                  playerProvider: playerProvider,
                  iconSize: 20,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
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
