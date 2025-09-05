import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/slider_custom.dart';
import '../services/player_provider.dart';
import '../contants/app_contants.dart' show PlayMode;

// 播放器控制面板组件
class PlayerControlPanel extends StatefulWidget {
  final PlayerProvider playerProvider;
  final double tempSliderValue;
  final VoidCallback? onClosePressed;
  final ValueChanged<double>? onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;

  const PlayerControlPanel({
    Key? key,
    required this.playerProvider,
    required this.tempSliderValue,
    this.onClosePressed,
    this.onSliderChanged,
    this.onSliderChangeEnd,
  }) : super(key: key);

  @override
  State<PlayerControlPanel> createState() => _PlayerControlPanelState();
}

class _PlayerControlPanelState extends State<PlayerControlPanel> {
  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerProvider.currentSong;
    final bool isPlaying = widget.playerProvider.isPlaying;
    final double currentPosition = widget.playerProvider.position.inSeconds.toDouble();
    final double totalDuration = widget.playerProvider.duration.inSeconds.toDouble();
    
    // 获取屏幕尺寸用于响应式布局
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // 响应式计算各种尺寸和间距
    final isSmallScreen = screenHeight < 600;
    final isMediumScreen = screenHeight < 800;
    final isLargeScreen = screenHeight > 1000;
    
    // 动态计算间距 - 根据屏幕大小调整，并且随着屏幕高度增加而增大
    final baseSpacing = isSmallScreen 
        ? 6.0 
        : (isMediumScreen 
            ? 10.0 + (screenHeight - 600) * 0.01  // 中等屏幕间距随高度增长
            : (isLargeScreen 
                ? 20.0 + (screenHeight - 800) * 0.02  // 大屏幕间距随高度更快增长
                : 14.0 + (screenHeight - 800) * 0.015)); // 默认间距随高度增长
    
    final smallSpacing = baseSpacing * 0.5;
    final mediumSpacing = baseSpacing * 0.8;
    final largeSpacing = baseSpacing * 1.2; // 新增大间距
    
    // 动态计算专辑封面大小
    final maxAlbumSize = screenWidth * 0.6;
    final albumArtSize = (screenHeight * 0.45).clamp(150.0, maxAlbumSize);
    
    // 控制组件宽度，使其小于封面宽度
    final controlsWidth = albumArtSize;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 4.0 : 8.0,
          horizontal: 8.0,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关闭按钮
              HoverIconButton(
                onPressed: widget.onClosePressed ?? () => Navigator.pop(context),
              ),
              
              SizedBox(height: smallSpacing),
              
              // 专辑封面 - 使用响应式大小
              SizedBox(
                width: albumArtSize,
                height: albumArtSize,
                child: AlbumArtWidget(
                  albumArtPath: currentSong?.albumArtPath,
                ),
              ),
              
              SizedBox(height: mediumSpacing),
              
              // 歌曲信息
              SizedBox(
                width: controlsWidth,
                child: SongInfoWidget(
                  title: currentSong?.title ?? "未知歌曲",
                  artist: currentSong?.artist ?? "未知歌手",
                ),
              ),
              
              SizedBox(height: largeSpacing), // 使用更大间距
              
              // 进度条
              SizedBox(
                width: controlsWidth,
                child: ProgressSliderWidget(
                  value: widget.tempSliderValue >= 0 ? widget.tempSliderValue : currentPosition,
                  max: totalDuration,
                  onChanged: widget.onSliderChanged,
                  onChangeEnd: widget.onSliderChangeEnd,
                ),
              ),
              
              SizedBox(height: smallSpacing), // 使用更大间距
              
              // 时间信息和比特率
              SizedBox(
                width: controlsWidth,
                child: TimeInfoWidget(
                  currentPosition: currentPosition,
                  totalDuration: totalDuration,
                  bitrate: currentSong?.bitrate,
                ),
              ),
              
              SizedBox(height: largeSpacing), // 使用更大间距
              
              // 播放控制按钮
              SizedBox(
                width: controlsWidth,
                child: PlaybackControlWidget(
                  playerProvider: widget.playerProvider,
                  isPlaying: isPlaying,
                ),
              ),
              
              SizedBox(height: mediumSpacing), // 播放控制和音量之间使用中等间距
              
              // 音量控制
              SizedBox(
                width: controlsWidth,
                child: VolumeControlWidget(
                  playerProvider: widget.playerProvider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 专辑封面组件
class AlbumArtWidget extends StatelessWidget {
  final String? albumArtPath;

  const AlbumArtWidget({
    Key? key,
    this.albumArtPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: albumArtPath != null && File(albumArtPath!).existsSync()
          ? Image.file(
              File(albumArtPath!),
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
    );
  }
}

// 歌曲信息组件
class SongInfoWidget extends StatelessWidget {
  final String title;
  final String artist;

  const SongInfoWidget({
    Key? key,
    required this.title,
    required this.artist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
            artist,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 进度条组件
class ProgressSliderWidget extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const ProgressSliderWidget({
    Key? key,
    required this.value,
    required this.max,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedTrackHeightSlider(
      value: value,
      max: max,
      min: 0,
      activeColor: Colors.white,
      inactiveColor: Colors.white30,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
    );
  }
}

// 时间信息组件
class TimeInfoWidget extends StatelessWidget {
  final double currentPosition;
  final double totalDuration;
  final int? bitrate;

  const TimeInfoWidget({
    Key? key,
    required this.currentPosition,
    required this.totalDuration,
    this.bitrate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _formatDuration(Duration(seconds: currentPosition.toInt())),
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
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "${bitrate != null ? (bitrate! / 1000).toStringAsFixed(0) : '未知'} kbps",
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
          _formatDuration(Duration(seconds: totalDuration.toInt())),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

// 播放控制组件
class PlaybackControlWidget extends StatelessWidget {
  final PlayerProvider playerProvider;
  final bool isPlaying;

  const PlaybackControlWidget({
    Key? key,
    required this.playerProvider,
    required this.isPlaying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 随机播放按钮
        IconButton(
          iconSize: 20,
          color: Colors.white70,
          icon: Icon(
            Icons.shuffle_rounded,
            color: playerProvider.playMode == PlayMode.shuffle
                ? Colors.white
                : null,
          ),
          onPressed: () {
            if (playerProvider.playMode == PlayMode.shuffle) {
              playerProvider.setPlayMode(PlayMode.sequence);
              return;
            }
            playerProvider.setPlayMode(PlayMode.shuffle);
          },
        ),
        
        // 播放控制按钮组
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上一曲
              IconButton(
                iconSize: 48,
                color: (playerProvider.hasPrevious || 
                       playerProvider.playMode == PlayMode.loop)
                    ? Colors.white
                    : Colors.white70,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () => playerProvider.previous(),
              ),
              const SizedBox(width: 16),
              
              // 播放/暂停
              IconButton(
                iconSize: 64,
                color: Colors.white,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: () => playerProvider.togglePlay(),
              ),
              const SizedBox(width: 16),
              
              // 下一曲
              IconButton(
                iconSize: 48,
                color: (playerProvider.hasNext || 
                       playerProvider.playMode == PlayMode.loop)
                    ? Colors.white
                    : Colors.white70,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () => playerProvider.next(),
              ),
            ],
          ),
        ),
        
        // 循环播放按钮
        IconButton(
          iconSize: 20,
          color: Colors.white70,
          icon: Icon(
            playerProvider.playMode == PlayMode.singleLoop
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
              color: playerProvider.playMode == PlayMode.loop ||
                     playerProvider.playMode == PlayMode.singleLoop
                  ? Colors.white
                  : null,
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
      ],
    );
  }
}

// 音量控制组件
class VolumeControlWidget extends StatelessWidget {
  final PlayerProvider playerProvider;

  const VolumeControlWidget({
    Key? key,
    required this.playerProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.volume_down_rounded,
            color: Colors.white70,
          ),
          onPressed: () {
            playerProvider.setVolume(playerProvider.volume - 0.1);
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
            playerProvider.setVolume(playerProvider.volume + 0.1);
          },
        ),
      ],
    );
  }
}

// 悬停图标按钮
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
      borderRadius: BorderRadius.circular(4),
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
