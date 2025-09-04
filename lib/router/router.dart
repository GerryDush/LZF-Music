import 'package:flutter/material.dart';
// 假设这些文件存在于你的项目中
import '../contants/app_contants.dart';
import '../views/library_view.dart';
import '../views/playlists_view.dart';
import '../views/favorites_view.dart';
import '../views/recently_played_view.dart';
import '../storage/player_state_storage.dart';
import '../widgets/show_aware_page.dart';
import '../views/settings/settings_page.dart';
import '../views/settings/storage_setting_page.dart';

// 你项目中的其他 import...

/// 单个菜单项
class MenuItem {
  final IconData icon;
  final double iconSize;
  final String label;
  final PlayerPage key;
  final GlobalKey pageKey;
  // builder 函数保持不变
  final Widget Function(GlobalKey key) builder;

  const MenuItem({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.key,
    required this.pageKey,
    required this.builder,
  });

  Widget buildPage() => builder(pageKey);
}

// REMOVED: 不再需要 MenuSubItem 类，因为它导致了 Widget 实例的预先创建，是问题的根源。
// class MenuSubItem { ... }

/// 菜单和页面统一管理器
class MenuManager {
  MenuManager._();

  static final MenuManager _instance = MenuManager._();

  factory MenuManager() => _instance;

  /// 当前页面
  final ValueNotifier<PlayerPage> currentPage = ValueNotifier(
    PlayerPage.library,
  );

  /// 菜单是否展开
  final ValueNotifier<bool> isExtended = ValueNotifier(true);

  /// 当前 hover 的菜单项
  final ValueNotifier<int> hoverIndex = ValueNotifier(-1);

  /// 页面实例缓存
  late final List<Widget> pages;

  /// 导航器 Key（供需要嵌套导航的页面使用）
  late final GlobalKey<NavigatorState> navigatorKey;

  /// 所有菜单项
  late final List<MenuItem> items;

  // REMOVED: 不再需要 subItems 列表
  // late final List<MenuSubItem> subItems;

  /// 初始化（必须调用一次）
  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    this.navigatorKey = navigatorKey;

    // REMOVED: subItems 的初始化代码已被移除

    items = [
      MenuItem(
        icon: Icons.library_music_rounded,
        iconSize: 22.0,
        label: '库',
        key: PlayerPage.library,
        pageKey: GlobalKey<LibraryViewState>(),
        builder: (key) => LibraryView(key: key),
      ),
      MenuItem(
        icon: Icons.favorite_rounded,
        iconSize: 22.0,
        label: '喜欢',
        key: PlayerPage.favorite,
        pageKey: GlobalKey<FavoritesViewState>(),
        builder: (key) => FavoritesView(key: key),
      ),
      MenuItem(
        icon: Icons.playlist_play_rounded,
        iconSize: 22.0,
        label: '播放列表',
        key: PlayerPage.playlist,
        pageKey: GlobalKey<PlaylistsViewState>(),
        builder: (key) => PlaylistsView(key: key),
      ),
      MenuItem(
        icon: Icons.history_rounded,
        iconSize: 22.0,
        label: '最近播放',
        key: PlayerPage.recently,
        pageKey: GlobalKey<RecentlyPlayedViewState>(),
        builder: (key) => RecentlyPlayedView(key: key),
      ),
      // CHANGED: 修改了设置页面的 MenuItem
      MenuItem(
        icon: Icons.settings_rounded,
        iconSize: 22.0,
        label: '系统设置',
        key: PlayerPage.settings,
        pageKey: GlobalKey<NestedNavigatorWrapperState>(),
        builder: (key) => NestedNavigatorWrapper(
          key: key,
          navigatorKey: navigatorKey,
          initialRoute: '/', // 定义初始路由
          // 不再传递预先创建好的 pages 列表
        ),
      ),
    ];

    pages = items.map((item) => item.buildPage()).toList();

    final playerState = await PlayerStateStorage.getInstance();
    currentPage.value = playerState.currentPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyPageShow(items[currentPage.value.index].pageKey);
    });
  }

  void setPage(PlayerPage page) {
    if (page == currentPage.value) return;
    final oldPage = currentPage.value;
    currentPage.value = page;

    PlayerStateStorage.getInstance().then((s) => s.setCurrentPage(page));

    final oldItem = items[oldPage.index];
    if (oldItem.pageKey.currentState is NestedNavigatorWrapperState) {
      (oldItem.pageKey.currentState as NestedNavigatorWrapperState)
          .navigatorKey
          .currentState
          ?.popUntil((r) => r.isFirst);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyPageShow(items[page.index].pageKey);
    });
  }

  void _notifyPageShow(GlobalKey key) {
    final state = key.currentState;
    if (state == null) return;
    if (state is ShowAwarePage) {
      state.onPageShow();
    }
  }
}

// =======================================================================
// CHANGED: NestedNavigatorWrapper 的改动
// =======================================================================

class NestedNavigatorWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  // REMOVED: 不再需要 pages 列表
  // final List<Widget> pages;

  const NestedNavigatorWrapper({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    // required this.pages, // 移除
  });

  @override
  NestedNavigatorWrapperState createState() => NestedNavigatorWrapperState();
}

class NestedNavigatorWrapperState extends State<NestedNavigatorWrapper>
    with ShowAwarePage {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;

  @override
  void onPageShow() {
    print('NestedNavigatorWrapper onPageShow');
    // 你可以在这里执行页面显示时的逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      initialRoute: widget.initialRoute,
      // CHANGED: 使用 onGenerateRoute 动态构建页面，这是解决问题的关键
      onGenerateRoute: (settings) {
        Widget page;

        // 根据路由名称 (settings.name) 来决定创建哪个页面
        switch (settings.name) {
          case '/':
            // 每次需要时都创建一个新的 SettingsPage 实例
            // 这样就不会有 GlobalKey 冲突
            page = SettingsPage(key: GlobalKey<SettingsPageState>());
            break;
          case '/settings/storage':
            // 示例：如果你有其他子页面，可以在这里添加
            page = const StorageSettingPage(); // 假设这个页面不需要 GlobalKey
            break;
          default:
            // 处理未知路由，避免崩溃
            page = Scaffold(
              body: Center(
                child: Text('未知路由: ${settings.name}'),
              ),
            );
        }

        // 返回一个 MaterialPageRoute 来承载新创建的页面
        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings, // 将路由设置传递给新页面
        );
      },
    );
  }
}

/// 辅助类，用于在子页面中进行导航
class NestedNavigationHelper {
  /// 跳转到嵌套路由中的新页面
  static void push(BuildContext context, String routeName) {
    // 使用 rootNavigator: false 来确保在嵌套的 Navigator 中跳转
    Navigator.of(context, rootNavigator: false).pushNamed(routeName);
  }

  /// 从嵌套路由中返回
  static void pop(BuildContext context) {
    // 使用 rootNavigator: false 来确保在嵌套的 Navigator 中返回
    Navigator.of(context, rootNavigator: false).pop();
  }
}