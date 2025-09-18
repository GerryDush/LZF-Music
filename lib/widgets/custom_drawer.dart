import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lzf_music/services/audio_player_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late AudioPlayerService importService;
  bool _isDrawerOpen = false;
  final double _drawerWidth = 250.0;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 主内容区
          Scaffold(
            appBar: AppBar(
              title: const Text("右侧模糊抽屉"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _toggleDrawer,
                ),
              ],
            ),
            body: const Center(child: Text("主页面内容")),
          ),

          /// 抽屉（毛玻璃 + 半透明）
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: _isDrawerOpen ? 0 : -_drawerWidth,
            top: 0,
            bottom: 0,
            width: _drawerWidth,
            child: ClipRRect(
              // 防止模糊超出边界
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 模糊强度
                child: Container(
                  color: Colors.white.withOpacity(0.3), // 半透明颜色
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "个人中心",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => debugPrint("点击个人中心"),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "设置",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => debugPrint("点击设置"),
                        ),
                        const Spacer(),
                        ListTile(
                          leading: const Icon(Icons.close, color: Colors.white),
                          title: const Text(
                            "关闭",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: _toggleDrawer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 点击关闭遮罩层
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: CustomDrawer()));
}
