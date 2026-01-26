import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';
import '../database/database.dart';
import 'file_access_manager.dart';
import '../widgets/lyric/lyrics_models.dart';

class AudioPlayerService extends BaseAudioHandler with SeekHandler {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _setupPlaybackStatePipe();
  }

  Future<void> Function()? onSkipToNextCallback;
  Future<void> Function()? onSkipToPreviousCallback;

  /* ------------------------- Player ------------------------- */

  final Player player = Player(
    configuration: const PlayerConfiguration(
      title: 'Linx Music',
    ),
  );

  MediaItem? _currentMediaItem;
  LyricsData? _currentLyrics;
  int _currentLyricIndex = -1;
  // final bool hasLyrics = song.lyricsBlob != null && song.lyricsBlob!.lines.isNotEmpty;

  bool get hasLyrics {
    return _currentLyrics != null && _currentLyrics!.lines.isNotEmpty;
  }

  Song? _currentSongData;
  StreamSubscription? _playbackStateSubscription;

  bool _wasPlayingBeforeInterruption = false;

  /* ---------------- PlaybackState Pipeline ------------------ */

  void _setupPlaybackStatePipe() {
    final triggerStream = Rx.combineLatest3<bool, Duration, bool, void>(
      player.stream.playing,
      player.stream.duration,
      player.stream.buffering,
      (playing, duration, buffering) => null,
    );

    _playbackStateSubscription = triggerStream
        .debounceTime(const Duration(milliseconds: 20)) // 防抖
        .listen((_) {
      _broadcastState();
    });
    player.stream.position.listen((position) {
      _checkAndUpdateLyric(position);
      _broadcastState();
    });
  }

  void _checkAndUpdateLyric(Duration position) {
    if (_currentLyrics == null || _currentSongData == null) return;

    // 计算当前行 (包含 400ms 偏移补偿，与 UI 保持一致)
    final newIndex = _currentLyrics!.lines.lastIndexWhere(
      (line) =>
          (position + const Duration(milliseconds: 400)) >= line.startTime,
    );

    // 只有当行数改变，且有效时才更新
    if (hasLyrics && newIndex != -1 && newIndex != _currentLyricIndex) {
      _currentLyricIndex = newIndex;
      final currentLineText = _currentLyrics!.lines[newIndex].getLineText();
      updateCurrentMediaItem(_currentSongData!,
          lyric: currentLineText, hasLyrics: hasLyrics);
    }
  }

  void _broadcastState() {
    final playing = player.state.playing;
    final position = player.state.position;
    final buffering = player.state.buffering;

    playbackState.add(createPlaybackState(
      playing: playing,
      position: position,
      buffering: buffering,
    ));
  }

  PlaybackState createPlaybackState({
    required bool playing,
    required Duration position,
    required bool buffering,
  }) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.setRating,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: buffering
          ? AudioProcessingState.buffering
          : (_currentMediaItem != null
              ? AudioProcessingState.ready
              : AudioProcessingState.idle),
      playing: playing,
      updatePosition: position,
      bufferedPosition: player.state.buffer, 
      speed: playing ? 1.0 : 0.0,
      queueIndex: 0,
      updateTime: DateTime.now(),
    );
  }

  /* -------------------- AudioService Init ------------------- */

  static Future<AudioPlayerService> init() async {
    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions:
          AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    final service = _instance;

    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            service.player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            service._wasPlayingBeforeInterruption =
                service.player.state.playing;
            if (service._wasPlayingBeforeInterruption) {
              await service.player.pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            service.player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (service._wasPlayingBeforeInterruption) {
              try {
                await session.setActive(true);
                await Future.delayed(const Duration(milliseconds: 100));
                await service.player.play();
              } catch (e) {
                print("Failed to resume playback: $e");
              }
            }
            service._wasPlayingBeforeInterruption = false;
            break;
        }
      }
    });

    await AudioService.init(
      builder: () => service,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'org.tttx.lzf_music.channel.audio',
        androidNotificationChannelName: 'Linx Music',
        androidNotificationOngoing: true,
        androidNotificationClickStartsActivity: true,
      ),
    );

    return service;
  }

  /* -------------------- Media Control ----------------------- */

  Future<void> playSong(Song song, {bool playNow = true}) async {
    try {
      _currentSongData = song;
      _currentLyrics = song.lyricsBlob;
      _currentLyricIndex = -1;
      String? initialLyric;
      if (hasLyrics) {
        initialLyric = song.lyricsBlob!.lines.first.getLineText();
      }
      updateCurrentMediaItem(song, lyric: initialLyric, hasLyrics: hasLyrics);

      if ((Platform.isIOS || Platform.isMacOS) &&
          !song.filePath.startsWith('/')) {
        final resolved = await FileAccessManager.startAccessing(song.filePath);
        if (resolved != null) {
          await player.open(Media(resolved), play: playNow);
        }
      } else {
        await player.open(Media(song.filePath), play: playNow);
      }
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  void updateCurrentMediaItem(Song song,
      {String? lyric, bool hasLyrics = false}) {
    String displayTitle;
    String displayArtist;

    final String originalArtist = song.artist ?? 'Unknown Artist';

    if (hasLyrics) {
      displayArtist = '${song.title} • $originalArtist';
      if (lyric != null && lyric.isNotEmpty) {
        displayTitle = lyric;
      } else {
        displayTitle = song.title;
      }
    } else {
      displayTitle = song.title;
      displayArtist = originalArtist;
    }

    _currentMediaItem = MediaItem(
      id: song.id.toString(),
      album: song.album ?? 'Unknown Album',
      title: displayTitle,
      artist: displayArtist,
      duration: song.duration != null
          ? Duration(milliseconds: song.duration! * 1000)
          : null,
      artUri: song.albumArtPath != null ? Uri.file(song.albumArtPath!) : null,
      rating: Rating.newHeartRating(song.isFavorite),
      extras: {'isFavorite': song.isFavorite},
    );
    mediaItem.add(_currentMediaItem);
  }

  /* ----------------- AudioHandler Overrides ---------------- */

  Future<void> _toggleFavorite(bool isLiked) async {
    final item = _currentMediaItem;
    if (item == null) return;
    try {
      final songId = int.tryParse(item.id);
      if (songId != null) {
        await MusicDatabase.database.updateSongFavorite(songId, isLiked);
        final newItem = item.copyWith(
          rating: Rating.newHeartRating(isLiked),
          extras: {...?item.extras, 'isFavorite': isLiked},
        );
        _currentSongData = _currentSongData!.copyWith(
          isFavorite: isLiked
        );
        _currentMediaItem = newItem;
        mediaItem.add(newItem);
        _broadcastState();
      }
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    if (rating.getRatingStyle() == RatingStyle.heart) {
      final bool targetStatus = rating.hasHeart();
      await _toggleFavorite(targetStatus);
    }
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    await session.setActive(true);
    await player.play();
  }

  @override
  Future<void> pause() async {
    await player.pause();
  }

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipToNextCallback != null) {
      await onSkipToNextCallback!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPreviousCallback != null) {
      await onSkipToPreviousCallback!();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  void dispose() {
    _playbackStateSubscription?.cancel();
    player.dispose();
  }
}
