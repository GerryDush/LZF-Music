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

class RecentlyPlayedView extends StatefulWidget {
  const RecentlyPlayedView({super.key});

  @override
  State<RecentlyPlayedView> createState() => RecentlyPlayedViewState();
}

class RecentlyPlayedViewState extends State<RecentlyPlayedView>
    with ShowAwarePage {
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  late MusicDatabase database;
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
    database = Provider.of<MusicDatabase>(context, listen: false);
    importService = MusicImportService(database);

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
    try {
      List<Song> loadedSongs;
      loadedSongs = await database.smartSearch(null, isLastPlayed: true);
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
              PageHeader(
                showImport: false,
                showSearch: false,
                songs: songs,
                onSearch: (keyword) async {
                  searchKeyword = keyword;
                  await _loadSongs();
                },
                onImportDirectory: () async {
                  await importService.importFromDirectory();
                  await _loadSongs();
                },
                onImportFiles: () async {
                  // await importService.importFiles(
                  //   onProgress: (processed, total) {
                  //     print('Processed $processed of $total files');
                  //   },
                  // );
                  await _loadSongs();
                },
              ),
              const SizedBox(height: 24),
              MusicListHeader(
                songs: songs,
                allowReorder: false, // 最近播放页面不允许重排列
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MusicListView(
                  songs: songs,
                  scrollController: _scrollController,
                  playerProvider: playerProvider,
                  database: database,
                  showCheckbox: false, // 收藏页面不显示复选框
                  checkedIds: const [],
                  onSongDeleted: _loadSongs,
                  onSongUpdated: () {
                    setState(() {
                      // 重新加载歌曲列表
                      _loadSongs();
                    });
                  },
                  onSongPlay: (song, playlist, index) {
                    playerProvider.playSong(song, playlist: playlist, index: index);
                  },
                  onCheckboxChanged: (songId, isChecked) {
                    // 收藏页面不使用复选框
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