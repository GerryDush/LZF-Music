import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lzf_music/model/song_list_item.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import '../utils/theme_utils.dart';
import '../database/database.dart';
import 'dart:ui';

class PageHeader extends StatefulWidget {
  final Future<void> Function(String? keyword)? onSearch;
  final Future<void> Function()? onImportDirectory;
  final Future<void> Function()? onImportFiles;
  final List<SongListItem>? songs;
  final List<Widget>? children;
  final String title;

  /// 是否显示搜索按钮
  final bool showSearch;

  /// 是否显示导入按钮
  final bool showImport;

  const PageHeader({
    super.key,
    required this.title,
    this.onSearch,
    this.onImportDirectory,
    this.onImportFiles,
    this.songs,
    this.showSearch = true,
    this.showImport = true,
    this.children = const <Widget>[],
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  bool _showSearchField = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    // update UI for clear button visibility
    setState(() {});
  }

  void _onSubmitted(String? value) {
    widget.onSearch?.call(value);
    setState(() {
      // _showSearchField = false;
    });
    // _searchController.clear();
  }

  void _openSearchDialog(BuildContext context) {
    // Platform specific full-screen / popup search
    if (PlatformUtils.isDesktop) {
      // Desktop: top-centered floating panel with blur and Esc to close (macOS/Windows/Linux)
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '搜索',
        barrierColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.black26,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, anim1, anim2) {
          return SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Center(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 138),
                    child: Shortcuts(
                      shortcuts: {
                        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
                      },
                      child: Actions(
                        actions: {
                          ActivateIntent: CallbackAction<Intent>(onInvoke: (intent) {
                            Navigator.of(ctx).pop();
                            return null;
                          }),
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: MediaQuery.of(ctx).size.width > 560 ? 560 : MediaQuery.of(ctx).size.width - 64,
                              decoration: BoxDecoration(
                                color: ThemeUtils.select(context, light: Color(0xffFFFFFF).withOpacity(0.7),dark: Color(0xFF333333).withOpacity(0.75)),
                                border: Border.all(
                                  color: ThemeUtils.select(context, light: Colors.white.withOpacity(0.06), dark: Colors.grey.withOpacity(0.08)),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: SizedBox(
                                width: double.infinity,
                                child: CupertinoTextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  autofocus: true,
                                  placeholder: '搜索歌曲或艺术家',
                                  decoration: BoxDecoration(color: Colors.transparent),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  clearButtonMode: OverlayVisibilityMode.editing,
                                  onChanged: (v) {
                                    if (v.isEmpty) {
                                      widget.onSearch?.call(null);
                                      _searchFocusNode.requestFocus();
                                    }
                                  },
                                  onSubmitted: (v) {
                                    _onSubmitted(v);
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (ctx, anim, secAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
              child: child,
            ),
          );
        },
      ).then((_) {
        _searchFocusNode.unfocus();
      });

      Future.delayed(const Duration(milliseconds: 150), () => _searchFocusNode.requestFocus());
      return;
    }

    else {
      // Mobile: simple floating CupertinoTextField above keyboard (iOS + Android)
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          final mq = MediaQuery.of(ctx);
          final maxWidth = mq.size.width > 560 ? 560.0 : mq.size.width - 24; // leave side margins
          return Padding(
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom + 12, left: 12, right: 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: maxWidth,
                child: GestureDetector(
                  onTap: () => _searchFocusNode.requestFocus(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: ThemeUtils.select(context, light: Color(0xffFFFFFF).withOpacity(0.7),dark: Color(0xFF666666).withOpacity(0.25)),
                                border: Border.all(
                                  color: ThemeUtils.select(context, light: Colors.white.withOpacity(0.06), dark: Colors.grey.withOpacity(0.08)),
                                  width: 1,
                                ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoTextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            placeholder: '搜索歌曲或艺术家',
                            autocorrect: false,
                            autofocus: true,
                            decoration: BoxDecoration(color: Colors.transparent),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            onChanged: (v) {
                              if (v.isEmpty) {
                                widget.onSearch?.call(null);
                                _searchFocusNode.requestFocus();
                              }
                            },
                            onSubmitted: (v) {
                              _onSubmitted(v);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        _searchFocusNode.unfocus();
      });

      Future.delayed(const Duration(milliseconds: 100), () => _searchFocusNode.requestFocus());
    }



  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 560;

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                if (widget.songs != null) Text('共${widget.songs!.length}首音乐'),
                const Spacer(),

                /// 搜索（Spotlight 风格覆盖）
                if (widget.showSearch)
                  IconButton(
                    icon: Icon(CupertinoIcons.search, color: Theme.of(context).iconTheme.color),
                    tooltip: '搜索',
                    onPressed: () {
                      _openSearchDialog(context);
                    },
                  ),

                /// 导入按钮（文件夹 + 文件）
                if (widget.showImport)
                  Row(
                    children: [
                      if (PlatformUtils.isDesktop) ...[
                        if (isWide)
                          TextButton.icon(
                            icon: const Icon(CupertinoIcons.folder_open),
                            label: const Text('选择文件夹'),
                            onPressed: () async {
                              await widget.onImportDirectory?.call();
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.folder_open_rounded, size: 24),
                            color: ThemeUtils.primaryColor(context),
                            tooltip: '选择文件夹',
                            onPressed: () async {
                              await widget.onImportDirectory?.call();
                            },
                          ),
                        const SizedBox(width: 8)
                      ],
                      if (isWide)
                        TextButton.icon(
                          icon: const Icon(CupertinoIcons.music_note),
                          label: const Text('选择音乐文件'),
                          onPressed: () async {
                            await widget.onImportFiles?.call();
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.library_music_rounded),
                          color: ThemeUtils.primaryColor(context),
                          tooltip: '选择音乐文件',
                          onPressed: () async {
                            await widget.onImportFiles?.call();
                          },
                        ),
                    ],
                  ),
              ],
            ),
            if (widget.children != null) ...widget.children!,
          ],
        ),

      ],
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
