import 'package:flutter/material.dart';
import '../services/player_provider.dart';
import '../widgets/slider_custom.dart';
import '../contants/app_contants.dart' show PlayMode;

class SongInfoPanel extends StatelessWidget {
  final double tempSliderValue;
  final Function(double) onSliderChanged;
  final Function(double) onSliderChangeEnd;
  final PlayerProvider playerProvider;
  final bool compactLayout;

  const SongInfoPanel({
    super.key,
    required this.tempSliderValue,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.playerProvider,
    this.compactLayout = false,
  });

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compactLayout) ...[
          Text(
            playerProvider.currentSong?.title ?? "未知歌曲",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            playerProvider.currentSong?.artist ?? "未知歌手",
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ValueListenableBuilder<Duration>(
  valueListenable: playerProvider.position,
  builder: (context, position, child) {return 
        AnimatedTrackHeightSlider(
          value: tempSliderValue >= 0
              ? tempSliderValue
              : position.inSeconds.toDouble(),
          max: playerProvider.duration.inSeconds.toDouble(),
          min: 0,
          activeColor: Colors.white,
          inactiveColor: Colors.white30,
          onChanged: onSliderChanged,
          onChangeEnd: onSliderChangeEnd,
        );}),
        
        Row(
          children: [
            ValueListenableBuilder<Duration>(
              valueListenable: playerProvider.position,
              builder: (context, position, child) {
                return Text(
                  formatDuration(position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${playerProvider.currentSong?.bitrate != null ? (playerProvider.currentSong!.bitrate! / 1000).toStringAsFixed(0) : '未知'} kbps",
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
              formatDuration(playerProvider.duration),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class MusicControlButtons extends StatelessWidget {
  final PlayerProvider playerProvider;
  final bool isPlaying;
  final bool compactLayout;

  const MusicControlButtons({
    super.key,
    required this.playerProvider,
    required this.isPlaying,
    this.compactLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
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
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    color:
                        (playerProvider.hasPrevious ||
                            playerProvider.playMode == PlayMode.loop)
                        ? Colors.white
                        : Colors.white70,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => playerProvider.previous(),
                  ),
                  SizedBox(width: compactLayout ? 8 : 16),
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
                  SizedBox(width: compactLayout ? 8 : 16),
                  IconButton(
                    iconSize: 48,
                    color:
                        (playerProvider.hasNext ||
                            playerProvider.playMode == PlayMode.loop)
                        ? Colors.white
                        : Colors.white70,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => playerProvider.next(),
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 20,
              color: Colors.white70,
              icon: Icon(
                playerProvider.playMode == PlayMode.singleLoop
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color:
                    playerProvider.playMode == PlayMode.loop ||
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
        ),
        if (compactLayout) ...[
          const SizedBox(height: 4),
        ] else ...[
          const SizedBox(height: 10),
        ],
        Row(
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
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
              onPressed: () {
                playerProvider.setVolume(playerProvider.volume + 0.1);
              },
            ),
          ],
        ),
      ],
    );
  }
}

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
      borderRadius: BorderRadius.circular(4), // 圆角大小
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
