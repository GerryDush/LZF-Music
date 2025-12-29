import 'package:flutter/material.dart';
import '../services/player_provider.dart';
import '../contants/app_contants.dart' show PlayMode;

/// 播放模式按钮（随机/循环/单曲循环）
class PlayModeButton extends StatelessWidget {
  final PlayerProvider playerProvider;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;

  const PlayModeButton({
    super.key,
    required this.playerProvider,
    this.iconSize = 20,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 随机播放按钮
        IconButton(
          iconSize: iconSize,
          padding: padding,
          constraints: constraints,
          color: inactiveColor ?? Colors.white70,
          icon: Icon(
            Icons.shuffle_rounded,
            color: playerProvider.playMode == PlayMode.shuffle
                ? (activeColor ?? Colors.white)
                : null,
          ),
          onPressed: () {
            if (playerProvider.playMode == PlayMode.shuffle) {
              playerProvider.setPlayMode(PlayMode.sequence);
            } else {
              playerProvider.setPlayMode(PlayMode.shuffle);
            }
          },
        ),
        // 循环播放按钮
        IconButton(
          iconSize: iconSize,
          padding: padding,
          constraints: constraints,
          color: inactiveColor ?? Colors.white70,
          icon: Icon(
            playerProvider.playMode == PlayMode.singleLoop
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: playerProvider.playMode == PlayMode.loop ||
                    playerProvider.playMode == PlayMode.singleLoop
                ? (activeColor ?? Colors.white)
                : null,
          ),
          onPressed: () {
            if (playerProvider.playMode == PlayMode.singleLoop) {
              playerProvider.setPlayMode(PlayMode.sequence);
            } else {
              playerProvider.setPlayMode(
                playerProvider.playMode == PlayMode.loop
                    ? PlayMode.singleLoop
                    : PlayMode.loop,
              );
            }
          },
        ),
      ],
    );
  }
}

/// 音量控制组件
class VolumeControl extends StatelessWidget {
  final PlayerProvider playerProvider;
  final double iconSize;
  final double sliderWidth;
  final double trackHeight;
  final Color? iconColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final Widget Function(double value, Function(double) onChanged)? sliderBuilder;

  const VolumeControl({
    super.key,
    required this.playerProvider,
    this.iconSize = 20,
    this.sliderWidth = 100,
    this.trackHeight = 4,
    this.iconColor,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.constraints,
    this.sliderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: padding,
          constraints: constraints,
          icon: Icon(
            Icons.volume_down_rounded,
            color: iconColor ?? Colors.white70,
            size: iconSize,
          ),
          onPressed: () {
            playerProvider.setVolume((playerProvider.volume - 0.1).clamp(0.0, 1.0));
          },
        ),
        SizedBox(
          width: sliderWidth,
          child: sliderBuilder != null
              ? sliderBuilder!(playerProvider.volume, (value) {
                  playerProvider.setVolume(value);
                })
              : Slider(
                  value: playerProvider.volume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: activeColor ?? Colors.white,
                  inactiveColor: inactiveColor ?? Colors.white30,
                  onChanged: (value) {
                    playerProvider.setVolume(value);
                  },
                ),
        ),
        IconButton(
          padding: padding,
          constraints: constraints,
          icon: Icon(
            Icons.volume_up_rounded,
            color: iconColor ?? Colors.white70,
            size: iconSize,
          ),
          onPressed: () {
            playerProvider.setVolume((playerProvider.volume + 0.1).clamp(0.0, 1.0));
          },
        ),
      ],
    );
  }
}

/// 播放控制按钮组（上一首/播放/下一首）
class PlaybackControls extends StatelessWidget {
  final PlayerProvider playerProvider;
  final bool isPlaying;
  final double playButtonSize;
  final double skipButtonSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final double spacing;

  const PlaybackControls({
    super.key,
    required this.playerProvider,
    required this.isPlaying,
    this.playButtonSize = 64,
    this.skipButtonSize = 48,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.constraints,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一首
        IconButton(
          iconSize: skipButtonSize,
          padding: padding,
          constraints: constraints,
          color: (playerProvider.hasPrevious ||
                  playerProvider.playMode == PlayMode.loop)
              ? (activeColor ?? Colors.white)
              : (inactiveColor ?? Colors.white70),
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () => playerProvider.previous(),
        ),
        SizedBox(width: spacing),
        // 播放/暂停
        IconButton(
          iconSize: playButtonSize,
          padding: padding,
          constraints: constraints,
          color: activeColor ?? Colors.white,
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          onPressed: () => playerProvider.togglePlay(),
        ),
        SizedBox(width: spacing),
        // 下一首
        IconButton(
          iconSize: skipButtonSize,
          padding: padding,
          constraints: constraints,
          color: (playerProvider.hasNext ||
                  playerProvider.playMode == PlayMode.loop)
              ? (activeColor ?? Colors.white)
              : (inactiveColor ?? Colors.white70),
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () => playerProvider.next(),
        ),
      ],
    );
  }
}
