import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:async';
import 'dart:math' as math;
import '../database/database.dart';
import 'audio_player_service.dart';
import '../storage/player_state_storage.dart';
import '../contants/app_contants.dart' show PlayMode;

class PlayerProvider with ChangeNotifier, WidgetsBindingObserver {
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
  List<Song> _originalPlaylist = [];
  List<Song> _shuffledPlaylist = [];
  int _currentIndex = -1;

  final math.Random _random = math.Random();

  StreamSubscription? _playingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completedSub;

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
  static const MethodChannel _audioSessionChannel =
      MethodChannel('com.lzf.music/audio_session');

  PlayerProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initializeListeners();
    _setupAudioServiceCallbacks();
  }

  void _initializeListeners() {
    // 播放状态
    _playingSub = player.stream.playing.listen((playing) {
      _isPlaying = playing;
      _isLoading = false;
      notifyListeners();
    });

    // 位置更新
    _positionSub = player.stream.position.listen((pos) {
      _position.value = pos;
    });

    // 总时长
    _durationSub = player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    // 播放完成
    _completedSub = player.stream.completed.listen((completed) {
      if (completed) {
        _handleSongCompleteWithDebounce();
      }
    });

    // 初始化状态
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
      if (_currentSong != null) {
        playSong(
          _currentSong!,
          playlist: _playlist,
          index: _playlist.indexWhere((s) => s.id == _currentSong!.id),
          shuffle: false,
          playNow: false,
        );
      }
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

  Future<void> _restoreAudioSessionIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _audioSessionChannel.invokeMethod('activateSession');
    } catch (e) {
      debugPrint('Failed to activate audio session: $e');
    }

    await _audioService.refreshNowPlaying();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreAudioSessionIfNeeded());
    }
  }

  void _handleSongCompleteWithDebounce() {
    _completeDebounceTimer?.cancel();
    _completeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isHandlingComplete) {
        _onSongComplete();
      }
    });
  }

  void _createShuffledPlaylist() {
    if (_originalPlaylist.isEmpty) return;

    _shuffledPlaylist = List.from(_originalPlaylist);

    if (_currentSong != null) {
      _shuffledPlaylist.removeWhere((song) => song.id == _currentSong!.id);
      _shuffledPlaylist.insert(0, _currentSong!);
    }

    if (_shuffledPlaylist.length > 1) {
      final songsToShuffle = _shuffledPlaylist.sublist(1);
      songsToShuffle.shuffle(_random);
      _shuffledPlaylist = [_shuffledPlaylist.first, ...songsToShuffle];
    }
  }

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
      _isHandlingComplete = false;
      notifyListeners();

      if (playlist != null) {
        _originalPlaylist = List.from(playlist);

        if (_playMode == PlayMode.shuffle && shuffle) {
          _currentSong = song;
          _createShuffledPlaylist();
          _playlist = _shuffledPlaylist;
          _currentIndex = _shuffledPlaylist.indexWhere((s) => s.id == song.id);
        } else if (_playMode == PlayMode.shuffle && !shuffle) {
          _playlist = _shuffledPlaylist.isNotEmpty
              ? _shuffledPlaylist
              : _originalPlaylist;
          _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
          if (_currentIndex == -1) {
            _playlist = _originalPlaylist;
            _currentIndex = index ?? 0;
          }
        } else {
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

      print('Playing song: ${song.filePath}');

      await MusicDatabase.database.updateSong(
        song.copyWith(
          lastPlayedTime: DateTime.now(),
          playedCount: song.playedCount + 1,
        ),
      );

      playerState.setCurrentSong(song);
      playerState.setPlaylist(_playlist);
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      _errorMessage = '播放失败: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_currentSong == null) return;

    try {
      if (_isPlaying) {
        await _audioService.pausePlayer();
        // playerState.setIsPlaying(false);
      } else {
        await _audioService.resume();
        // playerState.setIsPlaying(true);
      }
    } catch (e) {
      _errorMessage = '操作失败: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      _isHandlingComplete = true;
      await _audioService.stopPlayer();
      _currentSong = null;
      _isPlaying = false;
      _position.value = Duration.zero;
      _errorMessage = null;
      // playerState.setIsPlaying(false);
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
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _playlist.length - 1;
      }
      await playSong(_playlist[_currentIndex], shuffle: false);
      onSongChange?.call();
      return;
    }

    if (!hasPrevious &&
        _playMode != PlayMode.loop &&
        _playMode != PlayMode.singleLoop) return;

    if ((_playMode == PlayMode.loop || _playMode == PlayMode.singleLoop) &&
        !hasPrevious) {
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex--;
    }
    await playSong(_playlist[_currentIndex], shuffle: false);
    onSongChange?.call();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_playMode == PlayMode.shuffle) {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      await playSong(_playlist[_currentIndex], shuffle: false);
      onSongChange?.call();
      return;
    }

    if (!hasNext &&
        _playMode != PlayMode.loop &&
        _playMode != PlayMode.singleLoop) return;

    if ((_playMode == PlayMode.loop || _playMode == PlayMode.singleLoop) &&
        !hasNext) {
      _currentIndex = 0;
    } else {
      _currentIndex++;
    }
    await playSong(_playlist[_currentIndex], shuffle: false);
    onSongChange?.call();
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioService.seekPlayer(position);
      // playerState.setPosition(position);
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
    _handlePlayModeChange(previousMode, mode);
    notifyListeners();
    playerState.setPlayMode(mode);
  }

  List<Song> currentPlaylists() {
    return _playlist;
  }

  void _handlePlayModeChange(PlayMode previousMode, PlayMode newMode) {
    if (previousMode == PlayMode.shuffle && newMode != PlayMode.shuffle) {
      _restoreOriginalPlaylist();
    } else if (previousMode != PlayMode.shuffle &&
        newMode == PlayMode.shuffle) {
      _switchToShuffleMode();
    }
  }

  void _restoreOriginalPlaylist() {
    if (_originalPlaylist.isEmpty) return;
    _playlist = List.from(_originalPlaylist);
    if (_currentSong != null) {
      _currentIndex = _getCurrentSongIndexInOriginal();
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  void _switchToShuffleMode() {
    if (_originalPlaylist.isEmpty) return;
    _createShuffledPlaylist();
    _playlist = _shuffledPlaylist;
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
      if (songs.isNotEmpty) {
        _currentSong = songs[_currentIndex];
        _createShuffledPlaylist();
        _playlist = _shuffledPlaylist;
        _currentIndex = _shuffledPlaylist.indexWhere(
          (s) => s.id == _currentSong!.id,
        );
      }
    } else {
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
    _playlist.removeAt(index);
    _originalPlaylist.removeWhere((song) => song.id == removedSong.id);

    if (_playMode == PlayMode.shuffle) {
      _shuffledPlaylist.removeWhere((song) => song.id == removedSong.id);
    }

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

  void reshufflePlaylist() {
    if (_playMode != PlayMode.shuffle || _originalPlaylist.isEmpty) return;

    _createShuffledPlaylist();
    _playlist = _shuffledPlaylist;

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
            Future.microtask(() {
              seekTo(Duration.zero);
              _audioService.resume();
            });
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
        case PlayMode.shuffle:
          Future.microtask(() => next());
          break;
      }
      notifyListeners();
    } finally {
      Timer(const Duration(milliseconds: 500), () {
        _isHandlingComplete = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completedSub?.cancel();
    _completeDebounceTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}