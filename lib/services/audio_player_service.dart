import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import '../database/database.dart';

class AudioPlayerService extends BaseAudioHandler {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  final Player player = Player();
  static late MusicDatabase _database;
  static MusicDatabase get database => _database;

  // PlayerProvider 回调
  Function()? onPlay;
  Function()? onPause;
  Function()? onStop;
  Function()? onNext;
  Function()? onPrevious;
  Function(Duration)? onSeek;

  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // 初始化 AudioService
  static Future<AudioPlayerService> init(MusicDatabase database) async {
    _database = database;
    await AudioService.init(
      builder: () => AudioPlayerService(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.app.channel.audio',
        androidNotificationChannelName: 'Audio Service',
        androidNotificationOngoing: true,
        androidNotificationClickStartsActivity: true,
        androidShowNotificationBadge: true,
      ),
    );
    return _instance;
  }

  // 设置 PlayerProvider 的回调
  void setCallbacks({
    Function()? onPlay,
    Function()? onPause,
    Function()? onStop,
    Function()? onNext,
    Function()? onPrevious,
    Function(Duration)? onSeek,
  }) {
    this.onPlay = onPlay;
    this.onPause = onPause;
    this.onStop = onStop;
    this.onNext = onNext;
    this.onPrevious = onPrevious;
    this.onSeek = onSeek;
  }

  // 更新媒体项 - 由 PlayerProvider 调用
  void updateCurrentMediaItem(Song song) {
    mediaItem.add(
      MediaItem(
        id: song.id.toString(),
        album: song.album ?? 'Unknown Album',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        duration: song.duration != null
            ? Duration(milliseconds: song.duration! * 1000)
            : null,
        artUri: song.albumArtPath != null ? Uri.file(song.albumArtPath!) : null,
      ),
    );
  }

  // 更新播放状态 - 由 PlayerProvider 调用
  void updatePlaybackState({
    required bool playing,
    Duration? position,
    AudioProcessingState? processingState,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState ?? AudioProcessingState.ready,
        playing: playing,
        updatePosition: position ?? Duration.zero,
      ),
    );
  }

  // 原有的播放方法，使用 media_kit 播放
  Future<void> playSong(Song song, {bool playNow = true}) async {
    try {
      print('Playing song: ${song.filePath}');
      await _database.updateSong(
        song.copyWith(
          lastPlayedTime: DateTime.now(),
          playedCount: song.playedCount + 1,
        ),
      );

      await player.open(Media(song.filePath), play: playNow);
    } catch (e) {
      print('Error playing song: $e');
      updatePlaybackState(
        playing: false,
        processingState: AudioProcessingState.error,
      );
    }
  }

  // BaseAudioHandler 覆盖方法 - 这些会被系统通知栏调用
  // 但实际播放控制仍然通过 PlayerProvider
  @override
  Future<void> play() async {
    onPlay?.call(); // 调用 PlayerProvider 的 togglePlay
  }

  @override
  Future<void> pause() async {
    onPause?.call(); // 调用 PlayerProvider 的 togglePlay
  }

  @override
  Future<void> stop() async {
    onStop?.call(); // 调用 PlayerProvider 的 stop
  }

  @override
  Future<void> skipToNext() async {
    onNext?.call(); // 调用 PlayerProvider 的 next
  }

  @override
  Future<void> skipToPrevious() async {
    onPrevious?.call(); // 调用 PlayerProvider 的 previous
  }

  @override
  Future<void> seek(Duration position) async {
    onSeek?.call(position); // 调用 PlayerProvider 的 seekTo
  }

  // 保留原有的 media_kit 控制方法，供 PlayerProvider 调用
  Future<void> pausePlayer() async => await player.pause();
  Future<void> resume() async => await player.play();
  Future<void> stopPlayer() async => await player.stop();
  Future<void> seekPlayer(Duration position) async =>
      await player.seek(position);

  // 保留原有的流
  Stream<Duration> get positionStream => player.stream.position;
  Stream<Duration> get durationStream => player.stream.duration;

  @override
  Future<void> onTaskRemoved() async {
    await stopPlayer();
    await super.onTaskRemoved();
  }

  void dispose() {
    player.dispose();
    super.stop();
  }
}
