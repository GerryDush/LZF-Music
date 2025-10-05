import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import '../database/database.dart';

class AudioPlayerService extends BaseAudioHandler with SeekHandler {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  final Player player = Player(
    configuration: PlayerConfiguration(title: "LZF Music"),
  );

  Function()? onPlay;
  Function()? onPause;
  Function()? onStop;
  Function()? onNext;
  Function()? onPrevious;
  Function(Duration)? onSeek;

  MediaItem? _currentMediaItem;
  StreamSubscription? _playbackStateSubscription;

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _setupPlaybackStatePipe();
  }

  void _setupPlaybackStatePipe() {
    // 组合多个流，但保存订阅以便控制
    final stateStream = Rx.combineLatest4<bool, Duration, Duration, bool, PlaybackState>(
      player.stream.playing,
      player.stream.position,
      player.stream.duration,
      player.stream.buffering,
      (playing, position, duration, buffering) {
        return _createPlaybackState(
          playing: playing,
          position: position,
          buffering: buffering,
        );
      },
    );

    // 不要直接 pipe，而是监听并手动更新
    // 这样可以确保状态不会被意外清除
    _playbackStateSubscription = stateStream.listen((state) {
      playbackState.add(state);
    });
  }

  PlaybackState _createPlaybackState({
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
      bufferedPosition: position,
      speed: playing ? 1.0 : 0.0,
      queueIndex: 0,
    );
  }

  static Future<AudioPlayerService> init() async {
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

  void updateCurrentMediaItem(Song song) {
    _currentMediaItem = MediaItem(
      id: song.id.toString(),
      album: song.album ?? 'Unknown Album',
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      duration: song.duration != null
          ? Duration(milliseconds: song.duration! * 1000)
          : null,
      artUri: song.albumArtPath != null 
          ? Uri.file(song.albumArtPath!) 
          : null,
    );
    
    // 关键：先设置 mediaItem
    mediaItem.add(_currentMediaItem);
    
    // 然后立即更新 playbackState，确保控制中心有内容
    playbackState.add(_createPlaybackState(
      playing: player.state.playing,
      position: player.state.position,
      buffering: player.state.buffering,
    ));
    
    print('MediaItem updated: ${song.title}');
  }

  Future<void> playSong(Song song, {bool playNow = true}) async {
    try {
      updateCurrentMediaItem(song);
      await player.open(Media(song.filePath), play: playNow);
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  @override
  Future<void> play() async {
    onPlay?.call();
  }

  @override
  Future<void> pause() async {
    onPause?.call();
  }

  @override
  Future<void> stop() async {
    onStop?.call();
  }

  @override
  Future<void> skipToNext() async {
    onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onPrevious?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    onSeek?.call(position);
  }

  Future<void> pausePlayer() async => await player.pause();
  Future<void> resume() async => await player.play();
  Future<void> stopPlayer() async {
    await player.stop();
    _currentMediaItem = null;
  }
  Future<void> seekPlayer(Duration position) async => await player.seek(position);

  Stream<Duration> get positionStream => player.stream.position;
  Stream<Duration> get durationStream => player.stream.duration;

  @override
  Future<void> onTaskRemoved() async {
    await stopPlayer();
    await super.onTaskRemoved();
  }

  void dispose() {
    _playbackStateSubscription?.cancel();
    player.dispose();
    super.stop();
  }
}