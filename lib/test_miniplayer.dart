import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'widgets/mini_player.dart';
import 'widgets/music_list_view.dart';
import 'widgets/music_list_header.dart';
import 'services/player_provider.dart';
import 'services/theme_provider.dart';
import 'database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 MediaKit
  MediaKit.ensureInitialized();
  
  final themeProvider = AppThemeProvider();
  await themeProvider.init();
  
  runApp(TestMiniPlayerApp(themeProvider: themeProvider));
}

class TestMiniPlayerApp extends StatelessWidget {
  final AppThemeProvider themeProvider;
  
  const TestMiniPlayerApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MiniPlayer Test',
            theme: themeProvider.buildLightTheme().copyWith(
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: themeProvider.buildDarkTheme().copyWith(
              scaffoldBackgroundColor: Colors.white,
            ),
            themeMode: ThemeMode.light, // 强制使用浅色主题
            home: const TestMiniPlayerScreen(),
          );
        },
      ),
    );
  }
}

class TestMiniPlayerScreen extends StatefulWidget {
  const TestMiniPlayerScreen({super.key});

  @override
  State<TestMiniPlayerScreen> createState() => _TestMiniPlayerScreenState();
}

class _TestMiniPlayerScreenState extends State<TestMiniPlayerScreen> {
  double _containerWidth = 900;
  int _selectedTabIndex = 0;
  final List<Song> _mockSongs = [
    Song(
      id: 1,
      title: "Test Song 1",
      artist: "Test Artist 1",
      album: "Test Album 1",
      filePath: "/path/to/song1.mp3",
      duration: 240,
      bitrate: 320000,
      sampleRate: 44100,
      isFavorite: false,
      dateAdded: DateTime.now(),
      lastPlayedTime: DateTime.now(),
      playedCount: 5,
    ),
    Song(
      id: 2,
      title: "Test Song 2",
      artist: "Test Artist 2",
      album: "Test Album 2",
      filePath: "/path/to/song2.mp3",
      duration: 180,
      bitrate: 256000,
      sampleRate: 48000,
      isFavorite: true,
      dateAdded: DateTime.now(),
      lastPlayedTime: DateTime.now(),
      playedCount: 3,
    ),
    Song(
      id: 3,
      title: "Long Song Title That Should Be Truncated",
      artist: "Very Long Artist Name That Should Also Be Truncated",
      album: "Super Long Album Name That Will Definitely Be Truncated",
      filePath: "/path/to/song3.mp3",
      duration: 320,
      bitrate: 128000,
      sampleRate: 44100,
      isFavorite: false,
      dateAdded: DateTime.now(),
      lastPlayedTime: DateTime.now(),
      playedCount: 1,
    ),
  ];

  String? _orderField;
  String? _orderDirection;
  bool _showCheckbox = false;
  List<int> _checkedIds = [];

  // Mock数据库类
  final MockMusicDatabase _mockDatabase = MockMusicDatabase();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _selectedTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MiniPlayer & ListView Test'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'MiniPlayer'),
              Tab(text: 'ListView'),
              Tab(text: 'Header'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.light_mode),
              onPressed: () {
                final themeProvider = Provider.of<AppThemeProvider>(context, listen: false);
                themeProvider.setThemeMode(
                  themeProvider.themeMode == ThemeMode.light 
                    ? ThemeMode.dark 
                    : ThemeMode.light
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // MiniPlayer测试页面
            _buildMiniPlayerTest(),
            // ListView测试页面
            _buildListViewTest(),
            // Header测试页面
            _buildHeaderTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerTest() {
    return Column(
      children: [
        // 宽度控制滑块
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Container Width: ${_containerWidth.toInt()}px'),
              Slider(
                value: _containerWidth,
                min: 400,
                max: 1200,
                divisions: 80,
                onChanged: (value) {
                  setState(() {
                    _containerWidth = value;
                  });
                },
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // MiniPlayer 测试区域
        Container(
          width: _containerWidth,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MiniPlayer(containerWidth: _containerWidth),
        ),
        
        const Spacer(),
        
        // 信息显示
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<PlayerProvider>(
            builder: (context, playerProvider, child) {
              return Column(
                children: [
                  Text('Current Song: ${playerProvider.currentSong?.title ?? "None"}'),
                  Text('Is Playing: ${playerProvider.isPlaying}'),
                  Text('Volume: ${(playerProvider.volume * 100).toInt()}%'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListViewTest() {
    return Column(
      children: [
        // 控制面板
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Container Width: ${_containerWidth.toInt()}px'),
              Slider(
                value: _containerWidth,
                min: 400,
                max: 1200,
                divisions: 80,
                onChanged: (value) {
                  setState(() {
                    _containerWidth = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Show Checkbox: '),
                  Switch(
                    value: _showCheckbox,
                    onChanged: (value) {
                      setState(() {
                        _showCheckbox = value;
                        if (!value) _checkedIds.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _mockSongs.add(Song(
                          id: _mockSongs.length + 1,
                          title: "Dynamic Song ${_mockSongs.length + 1}",
                          artist: "Dynamic Artist ${_mockSongs.length + 1}",
                          album: "Dynamic Album",
                          filePath: "/path/to/dynamic${_mockSongs.length + 1}.mp3",
                          duration: 200 + (_mockSongs.length * 10),
                          bitrate: 320000,
                          sampleRate: 44100,
                          isFavorite: false,
                          dateAdded: DateTime.now(),
                          lastPlayedTime: DateTime.now(),
                          playedCount: 0,
                        ));
                      });
                    },
                    child: const Text('Add Song'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // ListView测试区域
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                return MusicListView(
                  songs: _mockSongs,
                  playerProvider: playerProvider,
                  
                  showCheckbox: _showCheckbox,
                  checkedIds: _checkedIds,
                  onSongDeleted: () {
                    setState(() {
                      // 刷新界面
                    });
                  },
                  onSongUpdated: () {
                    setState(() {
                      // 刷新界面
                    });
                  },
                  onCheckboxChanged: (id, checked) {
                    setState(() {
                      if (checked) {
                        if (!_checkedIds.contains(id)) {
                          _checkedIds.add(id);
                        }
                      } else {
                        _checkedIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTest() {
    return Column(
      children: [
        // 控制面板
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Container Width: ${_containerWidth.toInt()}px'),
              Slider(
                value: _containerWidth,
                min: 400,
                max: 1200,
                divisions: 80,
                onChanged: (value) {
                  setState(() {
                    _containerWidth = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Show Checkbox: '),
                  Switch(
                    value: _showCheckbox,
                    onChanged: (value) {
                      setState(() {
                        _showCheckbox = value;
                        if (!value) _checkedIds.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  Text('Order: ${_orderField ?? "None"} ${_orderDirection ?? ""}'),
                ],
              ),
            ],
          ),
        ),
        
        // Header测试区域
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MusicListHeader(
            songs: _mockSongs,
            orderField: _orderField,
            orderDirection: _orderDirection,
            showCheckbox: _showCheckbox,
            checkedIds: _checkedIds,
            allowReorder: true,
            onShowCheckboxToggle: () {
              setState(() {
                _showCheckbox = !_showCheckbox;
                if (!_showCheckbox) _checkedIds.clear();
              });
            },
            onOrderChanged: (field, direction) {
              setState(() {
                _orderField = field;
                _orderDirection = direction;
              });
            },
            onSelectAllChanged: (selectAll) {
              setState(() {
                if (selectAll) {
                  _checkedIds = _mockSongs.map((song) => song.id).toList();
                } else {
                  _checkedIds.clear();
                }
              });
            },
            onBatchAction: (action) {
              // Handle batch actions
              print('Batch action: $action for ${_checkedIds.length} items');
            },
          ),
        ),
        
        // 信息显示
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Songs: ${_mockSongs.length}'),
              Text('Checked Songs: ${_checkedIds.length}'),
              Text('Order Field: ${_orderField ?? "None"}'),
              Text('Order Direction: ${_orderDirection ?? "None"}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _checkedIds.clear();
                      });
                    },
                    child: const Text('Clear Selection'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _checkedIds = _mockSongs.map((song) => song.id).toList();
                      });
                    },
                    child: const Text('Select All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Mock数据库类用于测试
class MockMusicDatabase {
  Future<List<Song>> getAllSongs() async {
    return [];
  }
  
  Future<bool> updateSong(Song song) async {
    return true;
  }
  
  Future<int> deleteSong(int id) async {
    return 1;
  }
}
