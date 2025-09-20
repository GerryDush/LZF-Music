import 'package:flutter/material.dart';
import 'package:lzf_music/widgets/page_header.dart';
import 'dart:async';
import '../database/database.dart';
import '../services/music_import_service.dart';
import '../services/player_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/show_aware_page.dart';
import '../widgets/music_list_header.dart';
import '../widgets/music_list_view.dart';
import '../services/audio_player_service.dart';

class PlaylistsView extends StatefulWidget {
  const PlaylistsView({super.key});

  @override
  State<PlaylistsView> createState() => PlaylistsViewState();
}

class PlaylistsViewState extends State<PlaylistsView> with ShowAwarePage {
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  late MusicDatabase database = AudioPlayerService.database;
  late MusicImportService importService;
  List<Song> songs = [];
  String? orderField = null;
  String? orderDirection = null;
  String? searchKeyword = null;

  void onPageShow() {
    _loadSongs();
  }

  @override
  void initState() {
    super.initState();
    

    _scrollController.addListener(() {
      if (!_isScrolling &&
          _scrollController.position.pixels !=
              _scrollController.position.minScrollExtent) {
        setState(() {
          _isScrolling = true;
        });
      }

      // 重置之前的定时器
      _scrollTimer?.cancel();

      // 设置新的定时器
      _scrollTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    });
  }

  // 在你的 StatefulWidget 中更新这个方法
  Future<void> _loadSongs() async {
    final playerProvider = context.read<PlayerProvider>();
    try {
      List<Song> loadedSongs;
      loadedSongs = playerProvider.currentPlaylists();
      setState(() {
        songs = loadedSongs;
      });
      print('加载了 ${loadedSongs.length} 首歌曲');
    } catch (e) {
      print('加载歌曲失败: $e');
      // 可以显示错误信息给用户
      setState(() {
        songs = [];
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // 左上右16，底部0
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: '', songs: songs,showImport: false,showSearch: false,),
              const SizedBox(height: 24),
              MusicListHeader(
                songs: songs,
                allowReorder: false, // 播放列表页面不允许重排列
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MusicListView(
                  songs: songs,
                  scrollController: _scrollController,
                  playerProvider: playerProvider,
                  showCheckbox: false, // 播放列表页面不显示复选框
                  checkedIds: const [],
                  onSongDeleted: _loadSongs,
                  onSongUpdated: (_,_,_) {
                    setState(() {
                      // 重新加载歌曲列表
                      _loadSongs();
                    });
                  },
                  onSongPlay: (song, playlist, index) {
                    playerProvider.playSong(song, playlist: playlist, index: index);
                  },
                  onCheckboxChanged: (songId, isChecked) {
                    // 不使用复选框
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LibraryHeader extends StatefulWidget {
  final List<Song> songs;

  const LibraryHeader({super.key, required this.songs});

  @override
  State<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends State<LibraryHeader> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '播放列表',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Text('共${widget.songs.length}首音乐在播放列表'),
        const Spacer(),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
