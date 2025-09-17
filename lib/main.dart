import 'package:flutter/material.dart';
import 'package:lzf_music/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'views/home_page_mobile.dart';
import 'views/home_page_desktop.dart';
import 'services/player_provider.dart';
import 'database/database.dart';
import './services/theme_provider.dart';
import 'platform/desktop_manager.dart';
import 'platform/mobile_manager.dart';
import 'widgets/keyboard_handler.dart';
import './utils/platform_utils.dart';
import './router/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (PlatformUtils.isDesktop) {
      await DesktopManager.initialize();
    } else if (PlatformUtils.isMobile) {
      await MobileManager.initialize();
    }

    MediaKit.ensureInitialized();

    final themeProvider = AppThemeProvider();
    await themeProvider.init();

    final musicDatabase = MusicDatabase();

    await AudioPlayerService.init(MusicDatabase());

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
          Provider<MusicDatabase>.value(value: musicDatabase),
        ],
        child: const MainApp(),
      ),
    );

    if (PlatformUtils.isDesktop) {
      await DesktopManager.postInitialize();
    }
  } catch (e) {
    debugPrint('应用初始化失败: $e');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with DesktopWindowMixin {
  @override
  void initState() {
    super.initState();
    if (PlatformUtils.isDesktop) {
      DesktopManager.initializeListeners(this);
    }
  }

  @override
  void dispose() {
    if (PlatformUtils.isDesktop) {
      DesktopManager.disposeListeners();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return MyKeyboardHandler(
          child: MaterialApp(
            color: Colors.transparent,
            title: 'LZF Music',
            theme: themeProvider.buildLightTheme(),
            darkTheme: themeProvider.buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: HomePageWrapper(),
            navigatorObservers: [routeObserver],
            builder: (context, child) {
              if (PlatformUtils.isDesktopNotMac) {
                return DesktopManager.buildWithTitleBar(child);
              }
              return child ?? const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  
}
class HomePageWrapper extends StatelessWidget {
  const HomePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    if (PlatformUtils.isMobileWidth(context)) {
      // 小屏幕（手机）
      return const HomePageMobile();
    } else {
      // 大屏幕（平板/桌面）
      return const HomePageDesktop();
    }
  }
}
