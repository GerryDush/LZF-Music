import 'package:flutter/material.dart';
import 'package:lzf_music/model/song_list_item.dart';
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
import '../widgets/music_import_dialog.dart';
import '../widgets/music_list_header.dart';
import '../widgets/music_list_view.dart';
import '../widgets/page_header.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends State<LibraryView> with ShowAwarePage {
  late MusicImportService importService;
  List<SongListItem> songs = [];
  Song? currentSong;
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
      ScrollUtils.scrollToCurrentSong(_scrollController, songs, currentSong);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadSongs() async {
    try {
      List<SongListItem> loadedSongs;
      final keyword = searchKeyword;
      loadedSongs = await MusicDatabase.database.smartSearch(
        keyword?.trim(),
        orderField: orderField,
        orderDirection: orderDirection,
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
                    CommonUtils.select(theme.isFloat, t: 20, f: 110),
                    4,
                    CommonUtils.select(theme.isFloat, t: 0, f: 90),
                  ),
                  child: MusicListView(
                    songs: songs,
                    scrollController: _scrollController,
                    playerProvider: playerProvider,
                    showCheckbox: _showCheckbox,
                    checkedIds: checkedIds,
                    onSongDeleted: _loadSongs,
                    onSongUpdated: (song, index) {
                      _loadSongs().then((_) {
                        if (playerProvider.currentSong?.id == song.id) {
                          playerProvider.playSong(
                            songs[index!].id,
                            playlist: songs.map((s) => s.id).toList(),
                            index: index,
                          );
                        }
                      });
                    },
                    onSongPlay: (song, playlist, index) {
                      playerProvider.playSong(
                        song.id,
                        playlist: songs.map((s) => s.id).toList(),
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
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16.0,
                          PlatformUtils.isMacOS ? 24 : 0,
                          16.0,
                          0,
                        ),
                        child: PageHeader(
                        title: '音乐库',
                        songs: songs,
                        onSearch: (keyword) async {
                          searchKeyword = keyword;
                          await _loadSongs();
                        },
                        onImportDirectory: () async {
                          MusicImporter.importFromDirectory(
                            context,
                            onCompleted: () {
                              _loadSongs();
                            },
                          );
                        },
                        onImportFiles: () async {
                          MusicImporter.importFiles(
                            context,
                            onCompleted: () {
                              _loadSongs();
                            },
                          );
                        },
                        children: [
                          const SizedBox(height: 4),
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
                                ScrollUtils.scrollToCurrentSong(
                                  _scrollController,
                                  songs,
                                  currentSong,
                                );
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
                            onSelectAllChanged: (selectAll) {
                              setState(() {
                                if (selectAll) {
                                  checkedIds
                                    ..clear()
                                    ..addAll(songs.map((s) => s.id));
                                } else {
                                  checkedIds.clear();
                                }
                              });
                            },
                            onBatchAction: (action) async {
                              if (action == 'delete') {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('确认删除'),
                                    content: const Text('确定要删除所选歌曲吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          '确定',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  if (checkedIds.isEmpty) {
                                    LZFToast.show(context, '请勾选你要删除的歌曲');
                                    return;
                                  }
                                  int len = checkedIds.length;
                                  for (var id in checkedIds) {
                                    MusicDatabase.database.deleteSong(id);
                                  }
                                  LZFToast.show(context, "已删除${len}首歌");
                                  _loadSongs();
                                  setState(() {
                                    checkedIds.clear();
                                    _showCheckbox = false;
                                  });
                                }
                              } else if (action == 'hide') {
                                setState(() {
                                  checkedIds.clear();
                                  _showCheckbox = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),                ),                ),
              ],
            );
          },
        );
      },
    );
  }
}
