import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:lzf_music/widgets/frosted_container.dart';
import 'package:lzf_music/widgets/themed_background.dart';
import '../widgets/mini_player.dart';
import '../contants/app_contants.dart' show PlayerPage;
import '../router/router.dart';
import '../utils/native_tab_bar_utils.dart';
import '../i18n/i18n.dart';

class HomePageDesktop extends StatefulWidget {
  const HomePageDesktop({super.key});

  @override
  State<HomePageDesktop> createState() => _HomePageDesktopState();
}

class _HomePageDesktopState extends State<HomePageDesktop> {
  final menuManager = MenuManager();

  @override
  void initState() {
    super.initState();
    menuManager.init(navigatorKey: GlobalKey<NavigatorState>());
  }

  void _onTabChanged(int newIndex) {
    menuManager.setPage(PlayerPage.values[newIndex]);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ThemedBackground(
      builder: (context, theme) {
        // 设置原生标签栏事件处理（用于iPad）
        NativeTabBarController.setEventHandler(onTabSelected: (index) {
          _onTabChanged(index);
        });
        
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Row(
            children: [
              // iPad隐藏侧边栏，使用原生标签栏
              if (!PlatformUtils.isIOS)
              AnimatedContainer(
                color: theme.sidebarBg,
                duration: const Duration(milliseconds: 200),
                width:
                    CommonUtils.select(theme.sidebarIsExtended, t: 202, f: 90),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 0, 8),
                  child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 40.0,
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocale.linx.getString(context),
                                          style: TextStyle(
                                            height: 2,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          transitionBuilder: (Widget child,
                                              Animation<double> anim) {
                                            return FadeTransition(
                                              opacity: anim,
                                              child: SizeTransition(
                                                axis: Axis.horizontal,
                                                sizeFactor: anim,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: CommonUtils.select(
                                            theme.sidebarIsExtended,
                                            t: Text(
                                              AppLocale.music.getString(context),
                                              style: TextStyle(
                                                height: 2,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            f: const SizedBox(
                                                key: ValueKey('empty')),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ValueListenableBuilder<PlayerPage>(
                                      valueListenable: menuManager.currentPage,
                                      builder: (context, currentPage, _) {
                                        return ListView.builder(
                                          itemCount: menuManager.items.length,
                                          itemBuilder: (context, index) {
                                            final item =
                                                menuManager.items[index];
                                            final isSelected =
                                                index == currentPage.index;
                                            final isHovered = index ==
                                                menuManager.hoverIndex.value;

                                            Color bgColor;
                                            Color textColor;

                                            if (isSelected) {
                                              bgColor =
                                                  theme.primaryColor.withValues(
                                                alpha: 0.2,
                                              );
                                              textColor = theme.primaryColor;
                                            } else if (isHovered) {
                                              bgColor = Colors.grey.withValues(
                                                alpha: 0.2,
                                              );
                                              textColor = ThemeUtils.select(
                                                context,
                                                light: Colors.black,
                                                dark: Colors.white,
                                              );
                                            } else {
                                              bgColor = Colors.transparent;
                                              textColor = ThemeUtils.select(
                                                context,
                                                light: Colors.black,
                                                dark: Colors.white,
                                              );
                                            }

                                            return MouseRegion(
                                              onEnter: (_) => menuManager
                                                  .hoverIndex.value = index,
                                              onExit: (_) => menuManager
                                                  .hoverIndex.value = -1,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () =>
                                                      _onTabChanged(index),
                                                  child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      child: AnimatedAlign(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    500),
                                                        curve: Curves.easeOut,
                                                        alignment: theme
                                                                .sidebarIsExtended
                                                            ? Alignment
                                                                .centerLeft
                                                            : Alignment.center,
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              item.icon,
                                                              color: textColor,
                                                              size:
                                                                  item.iconSize,
                                                            ),
                                                            Flexible(
                                                              child:
                                                                  AnimatedContainer(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            200),
                                                                curve: Curves
                                                                    .easeIn,
                                                                width: theme
                                                                        .sidebarIsExtended
                                                                    ? 200
                                                                    : 0,
                                                                child:
                                                                    AnimatedSwitcher(
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          200),
                                                                  switchInCurve:
                                                                      Curves
                                                                          .ease,
                                                                  switchOutCurve:
                                                                      Curves
                                                                          .ease,
                                                                  transitionBuilder:
                                                                      (child, animation) =>
                                                                          FadeTransition(
                                                                    opacity:
                                                                        animation,
                                                                    child:
                                                                        SizeTransition(
                                                                      sizeFactor:
                                                                          animation,
                                                                      axis: Axis
                                                                          .horizontal,
                                                                      child:
                                                                          child,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      CommonUtils
                                                                          .select(
                                                                    theme
                                                                        .sidebarIsExtended,
                                                                    t: Padding(
                                                                      key: const ValueKey(
                                                                          'text'),
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              12),
                                                                      child:
                                                                          Align(
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child:
                                                                            Text(
                                                                          item.languageKey.getString(context),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                textColor,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    f: const SizedBox(
                                                                      width: 0,
                                                                      key: ValueKey(
                                                                          'empty'),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: IconButton(
                                      icon: Icon(
                                        CommonUtils.select(
                                          theme.sidebarIsExtended,
                                          t: Icons.arrow_back_rounded,
                                          f: Icons.menu_rounded,
                                        ),
                                      ),
                                      onPressed: () {
                                        theme.themeProvider.toggleExtended();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // 主内容区域
                    Container(
                      color: theme.bodyBg,
                      child: ValueListenableBuilder<PlayerPage>(
                        valueListenable: menuManager.currentPage,
                        builder: (context, currentPage, _) {
                          return IndexedStack(
                            index: currentPage.index,
                            children: menuManager.pages,
                          );
                        },
                      ),
                    ),

                    // 逻辑分辨率显示
                    // Positioned(
                    //   top: 8,
                    //   right: 8,
                    //   child: ResolutionDisplay(
                    //     isMinimized: true,
                    //   ),
                    // ),

                    // MiniPlayer
                    Positioned(
                      left: CommonUtils.select(theme.isFloat, t: 16, f: 16),
                      right: CommonUtils.select(theme.isFloat, t: 16, f: 16),
                      bottom: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(66),
                          border: Border.all(
                            color: CommonUtils.select(
                                ThemeUtils.isDark(context),
                                t: const Color.fromRGBO(255, 255, 255, 0.05),
                                f: const Color.fromRGBO(0, 0, 0, 0.05)),
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(65.5),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return FrostedContainer(
                                enabled: theme.isFloat,
                                child: MiniPlayer(
                                  containerWidth: constraints.maxWidth,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
