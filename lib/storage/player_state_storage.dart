import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../contants/app_contants.dart' show PlayerPage, PlayMode, SortState;

class PlayerStateStorage {
  static PlayerStateStorage? _instance;

  static Future<PlayerStateStorage> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = await _load();
    return _instance!;
  }

  PlayerStateStorage._();

  static const String _isPlayingKey = 'is_playing';
  static const String _positionKey = 'playback_position';
  static const String _songKey = 'current_song';
  static const String _playModeKey = 'play_mode';
  static const String _volumeKey = 'volume';
  static const String _pageKey = 'current_page';
  static const String _sortKey = 'sort_state';
  static const String _playlistKey = 'playlist';

  // 私有成员
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  int? _currentSong;
  PlayMode _playMode = PlayMode.shuffle;
  double _volume = 1.0;
  PlayerPage _currentPage = PlayerPage.library;
  Map<String, SortState> _pageSortStates = {};
  List<int> _playlist = [];

  /// 对外只读属性
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  int? get currentSong => _currentSong;
  PlayMode get playMode => _playMode;
  double get volume => _volume;
  PlayerPage get currentPage => _currentPage;
  Map<String, SortState> get pageSortStates =>
      Map.unmodifiable(_pageSortStates);
  List<int> get playlist => List.unmodifiable(_playlist);

  /// 启动时初始化，从本地读取
  static Future<PlayerStateStorage> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = PlayerStateStorage._();

    state._isPlaying = prefs.getBool(_isPlayingKey) ?? false;
    state._position = Duration(seconds: prefs.getInt(_positionKey) ?? 0);

    if (prefs.get(_songKey).runtimeType == String){
      prefs.remove(_songKey);
    }
    state._currentSong  = prefs.getInt(_songKey);


    final modeIndex = prefs.getInt(_playModeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < PlayMode.values.length) {
      state._playMode = PlayMode.values[modeIndex];
    }

    state._volume = prefs.getDouble(_volumeKey) ?? 1.0;

    final pageIndex = prefs.getInt(_pageKey);
    if (pageIndex != null &&
        pageIndex >= 0 &&
        pageIndex < PlayerPage.values.length) {
      state._currentPage = PlayerPage.values[pageIndex];
    }

    final sortJsonStr = prefs.getString(_sortKey);
    if (sortJsonStr != null) {
      final Map<String, dynamic> sortJson = jsonDecode(sortJsonStr);
      sortJson.forEach((page, value) {
        state._pageSortStates[page] = SortState.fromJson(value);
      });
    }

    String? playlistStr = prefs.getString(_playlistKey);
    if(playlistStr != null){
      if(playlistStr.contains('{')){
        prefs.remove(_playlistKey);
        playlistStr = null;
      }
    }
    if (playlistStr != null) {
      final List<dynamic> listJson = jsonDecode(playlistStr);
      state._playlist = listJson.map((e) => e as int).toList();
    }

    return state;
  }

  /// 内部保存方法
  Future<void> _savePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPlayingKey, _isPlaying);
    await prefs.setInt(_positionKey, _position.inSeconds);
    await prefs.setInt(_songKey, currentSong!);
  }

  Future<void> _savePlayMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playModeKey, _playMode.index);
  }

  Future<void> _saveVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
  }

  Future<void> _saveCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey, _currentPage.index);
  }

  Future<void> _saveSortState() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};
    _pageSortStates.forEach((page, sortState) {
      jsonMap[page] = sortState.toJson();
    });
    await prefs.setString(_sortKey, jsonEncode(jsonMap));
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = _playlist.map((s) => s).toList();
    await prefs.setString(_playlistKey, jsonEncode(listJson));
  }
}

/// 对外操作扩展
extension PlayerStateSetters on PlayerStateStorage {
  Future<void> setCurrentSong(Song? song) async {
    _currentSong = song!.id;
    await _savePlaybackState();
  }

  Future<void> setPlaylist(List<int> songs) async {
    _playlist = songs;
    await _savePlaylist();
  }

  Future<void> addToPlaylist(Song song) async {
    _playlist.add(song.id);
    await _savePlaylist();
  }

  Future<void> removeFromPlaylist(Song song) async {
    _playlist.removeWhere((s) => s == song.id);
    await _savePlaylist();
  }

  Future<void> setPlayingState(bool playing, {Duration? pos}) async {
    _isPlaying = playing;
    if (pos != null) _position = pos;
    await _savePlaybackState();
  }

  Future<void> setPlayMode(PlayMode mode) async {
    _playMode = mode;
    await _savePlayMode();
  }

  Future<void> setVolume(double vol) async {
    _volume = vol;
    await _saveVolume();
  }

  Future<void> setCurrentPage(PlayerPage page) async {
    _currentPage = page;
    await _saveCurrentPage();
  }

  Future<void> setPageSort(
    String page,
    String? field,
    String? direction,
  ) async {
    _pageSortStates[page] = SortState(field: field, direction: direction);
    await _saveSortState();
  }

  SortState getPageSort(String page) => _pageSortStates[page] ?? SortState();
}
