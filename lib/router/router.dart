import 'package:flutter/material.dart';
import '../contants/app_contants.dart';
import '../views/library_view.dart';
import '../views/favorites_view.dart';
import '../views/recently_played_view.dart';
import '../storage/player_state_storage.dart';
import '../widgets/show_aware_page.dart';
import '../widgets/sf_icon.dart';
import '../views/settings/settings_page.dart';
import '../views/settings/storage_setting_page.dart';
import '../views/settings/webdav_browser_page.dart';
import './my_cupertino_route.dart';
import '../model/storage_config.dart';
import '../i18n/i18n.dart';

class WebDavBrowserArguments {
  final StorageConfig config;
  final Function(String path)? onPathSelected;
  final Function(List<String> paths)? onFilesSelected;
  final String? initialPath;
  final List<String>? initialSelectedFiles;
  final bool isShowSelectedOnly;

  WebDavBrowserArguments(
      {required this.config,
      this.onPathSelected,
      this.onFilesSelected,
      this.initialPath,
      this.initialSelectedFiles,
      this.isShowSelectedOnly = false});
}

class MenuItem {
  final IconData icon;
  final double iconSize;
  final String languageKey;
  final PlayerPage key;
  final GlobalKey pageKey;
  final Widget Function(GlobalKey key) builder;

  const MenuItem({
    required this.icon,
    required this.iconSize,
    required this.languageKey,
    required this.key,
    required this.pageKey,
    required this.builder,
  });

  Widget buildPage() => builder(pageKey);
}

typedef PageBuilder = Widget Function(Object? arguments);

class MenuSubItem {
  final String routeName;
  final String title;
  final IconData? icon;

  final PageBuilder builder;

  final bool isVisible;

  const MenuSubItem({
    required this.routeName,
    required this.title,
    required this.builder,
    this.icon,
    this.isVisible = true,
  });

  Widget buildPage(Object? arguments) => builder(arguments);
}

class MenuManager {
  MenuManager._();

  static final MenuManager _instance = MenuManager._();

  factory MenuManager() => _instance;

  final ValueNotifier<PlayerPage> currentPage =
      ValueNotifier(PlayerPage.library);
  final ValueNotifier<int> hoverIndex = ValueNotifier(-1);
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final List<Widget> pages =
      items.map((item) => item.buildPage()).toList();

  late final List<MenuItem> items = [
    MenuItem(
      icon: SFIcons.sf_icon_musicpages,
      iconSize: 22.0,
      languageKey: AppLocale.library,
      key: PlayerPage.library,
      pageKey: GlobalKey<LibraryViewState>(),
      builder: (key) => LibraryView(key: key),
    ),
    MenuItem(
      icon: Icons.favorite_rounded,
      iconSize: 22.0,
      languageKey: AppLocale.favorite,
      key: PlayerPage.favorite,
      pageKey: GlobalKey<FavoritesViewState>(),
      builder: (key) => FavoritesView(key: key),
    ),
    MenuItem(
      icon: Icons.history_rounded,
      iconSize: 22.0,
      languageKey: AppLocale.recentlyPlayed,
      key: PlayerPage.recently,
      pageKey: GlobalKey<RecentlyPlayedViewState>(),
      builder: (key) => RecentlyPlayedView(key: key),
    ),
    MenuItem(
      icon: Icons.settings_rounded,
      iconSize: 22.0,
      languageKey: AppLocale.settings,
      key: PlayerPage.settings,
      pageKey: GlobalKey<NestedNavigatorWrapperState>(),
      builder: (key) => NestedNavigatorWrapper(
        key: key,
        navigatorKey: navigatorKey,
        initialRoute: '/',
        subItems: subItems,
      ),
    ),
  ];

  late final List<MenuSubItem> subItems = _getAllRoutes();

  List<MenuSubItem> get visibleSubItems =>
      subItems.where((i) => i.isVisible).toList();

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    List<MenuSubItem>? subMenuItems,
  }) async {
    final playerState = await PlayerStateStorage.getInstance();
    currentPage.value = playerState.currentPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyPageShow(items[currentPage.value.index].pageKey);
    });
  }

  List<MenuSubItem> _getAllRoutes() {
    return [
      MenuSubItem(
        routeName: '/',
        title: '设置首页',
        icon: Icons.settings,
        // 无需参数，忽略 args
        builder: (_) => SettingsPage(key: GlobalKey<SettingsPageState>()),
      ),
      MenuSubItem(
        routeName: '/settings/storage',
        title: '存储设置',
        icon: Icons.storage,
        builder: (_) => const StorageSettingPage(),
      ),
      MenuSubItem(
        routeName: '/webdav/browser',
        title: '文件浏览',
        isVisible: false,
        builder: (args) {
          if (args is WebDavBrowserArguments) {
            return WebDavBrowserPage(arguments: args);
          }
          return const Scaffold(
              resizeToAvoidBottomInset: false,
              body: Center(child: Text('参数错误: 缺少 WebDavBrowserArguments')));
        },
      ),
    ];
  }

  Widget? getPageByRoute(String routeName) {
    try {
      return subItems
          .firstWhere((item) => item.routeName == routeName)
          .buildPage(null);
    } catch (e) {
      return null;
    }
  }

  List<String> getAllRoutes() {
    return subItems.map((item) => item.routeName).toList();
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

class NestedNavigatorWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final List<MenuSubItem> subItems;

  const NestedNavigatorWrapper({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.subItems,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyFirstSubPageShow();
    });
  }

  void _notifyFirstSubPageShow() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      _findAndNotifyShowAwarePage(navigator.context);
    }
  }

  void _findAndNotifyShowAwarePage(BuildContext context) {
    void visitor(Element element) {
      final widget = element.widget;
      final state = element is StatefulElement ? element.state : null;
      if (state is ShowAwarePage) {
        state.onPageShow();
        return;
      }
      element.visitChildren(visitor);
    }

    try {
      context.visitChildElements(visitor);
    } catch (e) {
      print('查找ShowAwarePage时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        Widget page;

        try {
          final subItem = widget.subItems.firstWhere(
            (item) => item.routeName == settings.name,
          );

          page = subItem.buildPage(settings.arguments);
        } catch (e) {
          page = Scaffold(
              resizeToAvoidBottomInset: false,
              body: Center(child: Text('未知路由: ${settings.name}')));
        }

        return CupertinoPageRoute(
            settings: settings, builder: (context) => page);
      },
    );
  }
}

class NestedNavigationHelper {
  static void push(BuildContext context, String routeName) {
    Navigator.of(context, rootNavigator: false).pushNamed(routeName);
  }

  static Future<T?> pushNamed<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.of(context, rootNavigator: false)
        .pushNamed(routeName, arguments: arguments);
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context, rootNavigator: false).pop(result);
  }

  static void pushByMenuItem(BuildContext context, MenuSubItem menuItem) {
    Navigator.of(context, rootNavigator: false).pushNamed(menuItem.routeName);
  }
}
