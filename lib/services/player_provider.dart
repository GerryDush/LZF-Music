import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import 'dart:math' as math;
import '../database/database.dart';
import 'audio_player_service.dart';
import '../storage/player_state_storage.dart';
import '../contants/app_contants.dart' show PlayMode;

class PlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  late final PlayerStateStorage playerState;
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  double _volume = 1.0;

   final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);

  Duration _duration = Duration.zero;

  PlayMode _playMode = PlayMode.loop;

  List<Song> _playlist = [];
  List<Song> _originalPlaylist = []; // 保存原始顺序的播放列表
  List<Song> _shuffledPlaylist = []; // 打乱的播放列表
  int _currentIndex = -1;

  final math.Random _random = math.Random();

  // 流订阅
  StreamSubscription? _playingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completedSub;

  // 防重复调用标志
  bool _isHandlingComplete = false;
  Timer? _completeDebounceTimer;

  // Getters
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ValueNotifier<Duration> get position => _position;
  Duration get duration => _duration;
  PlayMode get playMode => _playMode;
  List<Song> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  Player get player => _audioService.player;
  double get volume => _volume;

  bool get hasPrevious =>
      playMode == PlayMode.shuffle ? true : _currentIndex > 0;
  bool get hasNext => playMode == PlayMode.shuffle
      ? true
      : _currentIndex < _playlist.length - 1;

  
  static void Function()? onSongChange;

  PlayerProvider() {
    _initializeListeners();
    _setupAudioServiceCallbacks();
  }

  void _initializeListeners() {
    // 播放状态
    _playingSub = player.stream.playing.listen((playing) {
      _isPlaying = playing;
      _isLoading = false;

      // 更新 AudioService 状态
      _audioService.updatePlaybackState(playing: playing, position: _position.value);

      notifyListeners();
    });

    Duration _lastNotify = Duration.zero;
    const Duration notifyInterval = Duration(milliseconds: 200); 
    _positionSub = player.stream.position.listen((pos) {
      _position.value = pos;
      // 降低 notifyListeners 频率
      if ((pos - _lastNotify) > notifyInterval) {
        _lastNotify = pos;
        _audioService.updatePlaybackState(playing: _isPlaying, position: pos);
      }
    });

    // 总时长
    _durationSub = player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    // 播放完成 - 使用防抖机制
    _completedSub = player.stream.completed.listen((completed) {
      if (completed) {
        _handleSongCompleteWithDebounce();
      }
    });

    PlayerStateStorage.getInstance().then((state) {
      playerState = state;
      _currentSong = state.currentSong;
      _playlist = state.playlist;
      _originalPlaylist = state.playlist;
      _shuffledPlaylist = state.playlist;
      _volume = state.volume;
      _playMode = state.playMode;
      _position.value = state.position;
      _isPlaying = state.isPlaying;
      playSong(
        _currentSong!,
        playlist: _playlist,
        index: _playlist.indexWhere((s) => s.id == _currentSong!.id),
        shuffle: false,
        playNow: false,
      );
      setVolume(_volume);
      notifyListeners();
    });
  }

  void _setupAudioServiceCallbacks() {
    _audioService.setCallbacks(
      onPlay: () => togglePlay(),
      onPause: () => togglePlay(),
      onStop: () => stop(),
      onNext: () => next(),
      onPrevious: () => previous(),
      onSeek: (position) => seekTo(position),
    );
  }

  void _handleSongCompleteWithDebounce() {
    // 取消之前的定时器
    _completeDebounceTimer?.cancel();

    // 设置新的定时器，延迟执行
    _completeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isHandlingComplete) {
        _onSongComplete();
      }
    });
  }

  // 创建打乱的播放列表
  void _createShuffledPlaylist() {
    if (_originalPlaylist.isEmpty) return;

    _shuffledPlaylist = List.from(_originalPlaylist);

    // 如果当前有正在播放的歌曲，确保它在打乱列表的第一位
    if (_currentSong != null) {
      _shuffledPlaylist.removeWhere((song) => song.id == _currentSong!.id);
      _shuffledPlaylist.insert(0, _currentSong!);
    }

    // 打乱除第一首歌以外的其他歌曲
    if (_shuffledPlaylist.length > 1) {
      final songsToShuffle = _shuffledPlaylist.sublist(1);
      songsToShuffle.shuffle(_random);
      _shuffledPlaylist = [_shuffledPlaylist.first, ...songsToShuffle];
    }
  }

  // 获取当前歌曲在原始列表中的索引
  int _getCurrentSongIndexInOriginal() {
    if (_currentSong == null) return -1;
    return _originalPlaylist.indexWhere((song) => song.id == _currentSong!.id);
  }

  Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? index,
    bool shuffle = true,
    bool playNow = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _isHandlingComplete = false; // 重置完成处理标志
      notifyListeners();

      if (playlist != null) {
        _originalPlaylist = List.from(playlist);

        if (_playMode == PlayMode.shuffle && shuffle) {
          // 只有在shuffle标志为true时才重新打乱
          _currentSong = song;
          _createShuffledPlaylist();
          _playlist = _shuffledPlaylist;
          _currentIndex = _shuffledPlaylist.indexWhere((s) => s.id == song.id);
        } else if (_playMode == PlayMode.shuffle && !shuffle) {
          // 随机模式但不重新打乱，使用现有的打乱列表
          _playlist = _shuffledPlaylist.isNotEmpty
              ? _shuffledPlaylist
              : _originalPlaylist;
          _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
          if (_currentIndex == -1) {
            // 如果在打乱列表中找不到，回退到原始列表
            _playlist = _originalPlaylist;
            _currentIndex = index ?? 0;
          }
        } else {
          // 非随机模式
          _playlist = List.from(playlist);
          _currentIndex = index ?? 0;
        }
      } else if (_originalPlaylist.isEmpty ||
          !_originalPlaylist.any((s) => s.id == song.id)) {
        _originalPlaylist = [song];
        _shuffledPlaylist = [song];
        _playlist = [song];
        _currentIndex = 0;
      } else {
        // 在现有播放列表中播放，不重新打乱
        if (_playMode == PlayMode.shuffle) {
          _currentIndex = _shuffledPlaylist.indexWhere((s) => s.id == song.id);
          _playlist = _shuffledPlaylist;
        } else {
          _currentIndex = _originalPlaylist.indexWhere((s) => s.id == song.id);
          _playlist = _originalPlaylist;
        }
      }

      _currentSong = song;

      // 更新 AudioService 媒体项
      _audioService.updateCurrentMediaItem(song);

      await _audioService.playSong(song, playNow: playNow);
      playerState.setCurrentSong(song);
      playerState.setPlaylist(_playlist);
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      _errorMessage = '播放失败: ${e.toString()}';

      // 更新 AudioService 错误状态
      _audioService.updatePlaybackState(
        playing: false,
        processingState: AudioProcessingState.error,
      );

      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_currentSong == null) return;

    try {
      if (_isPlaying) {
        await _audioService.pausePlayer();
      } else {
        await _audioService.resume();
      }
    } catch (e) {
      _errorMessage = '操作失败: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      _isHandlingComplete = true; // 防止stop时触发complete回调
      await _audioService.stopPlayer();
      _currentSong = null;
      _isPlaying = false;
      _position.value = Duration.zero;
      _errorMessage = null;

      // 更新 AudioService 状态
      _audioService.updatePlaybackState(
        playing: false,
        processingState: AudioProcessingState.idle,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = '停止失败: ${e.toString()}';
      notifyListeners();
    } finally {
      Timer(const Duration(milliseconds: 200), () {
        _isHandlingComplete = false;
      });
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    if (_playMode == PlayMode.shuffle) {
      // 在随机模式下，从打乱的列表中选择上一首
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _playlist.length - 1;
      }
      await playSong(_playlist[_currentIndex]);
      onSongChange?.call();
      return;
    }

    if (!hasPrevious &&
        _playMode != PlayMode.loop &&
        _playMode != PlayMode.singleLoop)
      return;
    if ((_playMode == PlayMode.loop || _playMode == PlayMode.singleLoop) &&
        !hasPrevious) {
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex--;
    }
    await playSong(_playlist[_currentIndex]);
    onSongChange?.call();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_playMode == PlayMode.shuffle) {
      // 在随机模式下，从打乱的列表中选择下一首
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      await playSong(_playlist[_currentIndex]);
      onSongChange?.call();
      return;
    }

    if (!hasNext &&
        _playMode != PlayMode.loop &&
        _playMode != PlayMode.singleLoop)
      return;
    if ((_playMode == PlayMode.loop || _playMode == PlayMode.singleLoop) &&
        !hasNext) {
      _currentIndex = 0;
    } else {
      _currentIndex++;
    }
    await playSong(_playlist[_currentIndex]);
    onSongChange?.call();
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioService.seekPlayer(position);
    } catch (e) {
      _errorMessage = '跳转失败: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await player.setVolume(_volume * 100);
      playerState.setVolume(volume);
      notifyListeners();
    } catch (e) {
      _errorMessage = '设置音量失败: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleMute() async {
    if (_volume > 0) {
      await setVolume(0);
    } else {
      await setVolume(1.0);
    }
  }

  void setPlayMode(PlayMode mode) {
    if (_playMode == mode) return;

    final previousMode = _playMode;
    _playMode = mode;

    // 处理播放模式切换
    _handlePlayModeChange(previousMode, mode);

    notifyListeners();
    playerState.setPlayMode(mode);
  }

  List<Song> currentPlaylists() {
    return _playlist;
  }

  void _handlePlayModeChange(PlayMode previousMode, PlayMode newMode) {
    // 如果从随机模式切换到非随机模式
    if (previousMode == PlayMode.shuffle && newMode != PlayMode.shuffle) {
      _restoreOriginalPlaylist();
    }
    // 如果从非随机模式切换到随机模式
    else if (previousMode != PlayMode.shuffle && newMode == PlayMode.shuffle) {
      _switchToShuffleMode();
    }
  }

  void _restoreOriginalPlaylist() {
    if (_originalPlaylist.isEmpty) return;

    // 恢复到原始播放列表
    _playlist = List.from(_originalPlaylist);

    // 更新当前索引为原始列表中的位置
    if (_currentSong != null) {
      _currentIndex = _getCurrentSongIndexInOriginal();
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  void _switchToShuffleMode() {
    if (_originalPlaylist.isEmpty) return;

    // 创建打乱的播放列表
    _createShuffledPlaylist();
    _playlist = _shuffledPlaylist;

    // 更新当前索引为打乱列表中的位置
    if (_currentSong != null) {
      _currentIndex = _shuffledPlaylist.indexWhere(
        (s) => s.id == _currentSong!.id,
      );
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  void setPlaylist(List<Song> songs, {int currentIndex = 0}) {
    _originalPlaylist = List.from(songs);
    _currentIndex = currentIndex.clamp(0, songs.length - 1);

    if (_playMode == PlayMode.shuffle) {
      // 如果当前是随机模式，创建打乱的列表
      if (songs.isNotEmpty) {
        _currentSong = songs[_currentIndex];
        _createShuffledPlaylist();
        _playlist = _shuffledPlaylist;
        _currentIndex = _shuffledPlaylist.indexWhere(
          (s) => s.id == _currentSong!.id,
        );
      }
    } else {
      // 非随机模式使用原始列表
      _playlist = List.from(songs);
    }

    if (songs.isNotEmpty) {
      _currentSong = songs[currentIndex.clamp(0, songs.length - 1)];
    }
    notifyListeners();
  }

  void addToPlaylist(Song song) {
    _originalPlaylist.add(song);

    if (_playMode == PlayMode.shuffle) {
      // 随机模式下添加到打乱列表的随机位置
      if (_shuffledPlaylist.isEmpty) {
        _shuffledPlaylist.add(song);
      } else {
        final randomIndex = _random.nextInt(_shuffledPlaylist.length + 1);
        _shuffledPlaylist.insert(randomIndex, song);
      }
      _playlist = _shuffledPlaylist;
    } else {
      _playlist.add(song);
    }

    notifyListeners();
  }

  void removeFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;

    final removedSong = _playlist[index];

    // 从当前播放列表中移除
    _playlist.removeAt(index);

    // 从原始列表中移除
    _originalPlaylist.removeWhere((song) => song.id == removedSong.id);

    // 如果是随机模式，也从打乱列表中移除
    if (_playMode == PlayMode.shuffle) {
      _shuffledPlaylist.removeWhere((song) => song.id == removedSong.id);
    }

    // 更新当前索引
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _playlist.length) {
        _currentIndex = _playlist.length - 1;
      }
      if (_playlist.isEmpty) {
        stop();
      } else {
        _currentSong = _playlist[_currentIndex];
      }
    }
    notifyListeners();
  }

  // 重新洗牌当前播放列表（保持当前歌曲在第一位）
  void reshufflePlaylist() {
    if (_playMode != PlayMode.shuffle || _originalPlaylist.isEmpty) return;

    _createShuffledPlaylist();
    _playlist = _shuffledPlaylist;

    // 更新当前索引
    if (_currentSong != null) {
      _currentIndex = _shuffledPlaylist.indexWhere(
        (s) => s.id == _currentSong!.id,
      );
      if (_currentIndex == -1) _currentIndex = 0;
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _onSongComplete() {
    // 防止重复处理
    if (_isHandlingComplete) return;
    _isHandlingComplete = true;

    try {
      switch (_playMode) {
        case PlayMode.single:
          _isPlaying = false;
          _position.value = Duration.zero;
          break;
        case PlayMode.singleLoop:
          if (_currentSong != null) {
            Future.microtask(
              () => {seekTo(Duration.zero), _audioService.resume()},
            );
          }
          break;
        case PlayMode.sequence:
          if (hasNext) {
            Future.microtask(() => next());
          } else {
            _isPlaying = false;
            _position.value = Duration.zero;
          }
          break;
        case PlayMode.loop:
          Future.microtask(() => next());
          break;
        case PlayMode.shuffle:
          // 随机模式下播放下一首（已经在打乱的列表中）
          Future.microtask(() => next());
          break;
      }
      notifyListeners();
    } finally {
      // 延迟重置标志
      Timer(const Duration(milliseconds: 500), () {
        _isHandlingComplete = false;
      });
    }
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completedSub?.cancel();
    _completeDebounceTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
