import 'package:flutter/material.dart';
import 'package:lzf_music/services/audio_player_service.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/utils/scroll_utils.dart';
import 'package:lzf_music/widgets/frosted_container.dart';
import 'package:lzf_music/widgets/themed_background.dart';
import 'dart:async';
import '../database/database.dart';
import '../services/music_import_service.dart';
import '../services/player_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/show_aware_page.dart';
import '../widgets/lzf_toast.dart';
import '../widgets/music_list_header.dart';
import '../widgets/music_list_view.dart';
import '../widgets/page_header.dart';

class RecentlyPlayedView extends StatefulWidget {
  const RecentlyPlayedView({super.key});

  @override
  State<RecentlyPlayedView> createState() => RecentlyPlayedViewState();
}

class RecentlyPlayedViewState extends State<RecentlyPlayedView> with ShowAwarePage {
  late MusicImportService importService;
  List<Song> songs = [];
  Song? currentSong = null;
  String? orderField;
  String? orderDirection;
  String? searchKeyword;
  bool _showCheckbox = false;
  List<int> checkedIds = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void onPageShow() {
    _loadSongs().then((_) {
      ScrollUtils.scrollToCurrentSong(_scrollController, songs, currentSong);
    });
    PlayerProvider.onSongChange = (() {
      print(111);
      ScrollUtils.scrollToCurrentSong(_scrollController, songs, currentSong);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadSongs() async {
    try {
      List<Song> loadedSongs;
      final keyword = searchKeyword;
      loadedSongs = await MusicDatabase.database.smartSearch(
        keyword?.trim(),
        orderField: orderField,
        orderDirection: orderDirection,
        isLastPlayed: true
      );
      setState(() {
        songs = loadedSongs;
      });

      print('加载了 ${loadedSongs.length} 首歌曲');
    } catch (e) {
      print('加载歌曲失败: $e');
      setState(() {
        songs = [];
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        currentSong = playerProvider.currentSong;
        return ThemedBackground(
          builder: (context, theme) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    CommonUtils.select(theme.isFloat, t: 20, f: 136),
                    4,
                    CommonUtils.select(theme.isFloat, t: 0, f: 80),
                  ),
                  child: MusicListView(
                    songs: songs,
                    scrollController: _scrollController,
                    playerProvider: playerProvider,
                    showCheckbox: _showCheckbox,
                    checkedIds: checkedIds,
                    onSongPlay: (song, playlist, index) {
                      playerProvider.playSong(
                        song,
                        playlist: playlist,
                        index: index,
                      );
                    },
                    onCheckboxChanged: (songId, isChecked) {
                      setState(() {
                        if (isChecked) {
                          checkedIds.add(songId);
                        } else {
                          checkedIds.remove(songId);
                        }
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FrostedContainer(
                    enabled: theme.isFloat,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16.0,
                        PlatformUtils.select(desktop: 20.0, mobile: 66.0),
                        16.0,
                        0,
                      ),
                      child: PageHeader(
                        showImport: false,
                        title: '最近播放',
                        songs: songs,
                        onSearch: (keyword) async {
                          searchKeyword = keyword;
                          await _loadSongs();
                        },
                        children: [
                          const SizedBox(height: 20),
                          MusicListHeader(
                            songs: songs,
                            orderField: orderField,
                            orderDirection: orderDirection,
                            showCheckbox: _showCheckbox,
                            checkedIds: checkedIds,
                            allowReorder: true, // 库视图允许重排列
                            onShowCheckboxToggle: () {
                              setState(() {
                                _showCheckbox = true;
                              });
                            },
                            onScrollToCurrent: () {
                              if (currentSong != null) {
                                ScrollUtils.scrollToCurrentSong(_scrollController, songs, currentSong);
                              } else {
                                LZFToast.show(context, '当前没有播放歌曲');
                              }
                            },
                            onOrderChanged: (field, direction) {
                              setState(() {
                                orderField = field;
                                orderDirection = direction;
                              });
                              _loadSongs();
                            },
                            
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
