import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../../services/web_dav_manager.dart'; // 引入 Manager
import '../../widgets/lzf_toast.dart';
import '../../ui/lzf_button.dart';
import '../../router/router.dart';
// 引入你的参数定义位置，或者直接用上面的类
// import '../../model/web_dav_browser_arguments.dart'; 

class WebDavBrowserPage extends StatefulWidget {
  final WebDavBrowserArguments arguments;

  const WebDavBrowserPage({
    super.key,
    required this.arguments,
  });

  @override
  State<WebDavBrowserPage> createState() => _WebDavBrowserPageState();
}

class _WebDavBrowserPageState extends State<WebDavBrowserPage> {
  // Client 从 Manager 获取，无需 late 初始化
  late webdav.Client _client;
  
  late String _currentPath;
  
  // 浏览模式下的文件列表（网络数据）
  List<webdav.File> _files = [];
  
  // 选中的路径集合（核心数据）
  final Set<String> _selectedPaths = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // 1. 获取 Client (单例模式，速度极快)
    _client = WebDavManager().getClient(widget.arguments.config);

    // 2. 初始化路径
    String startPath = widget.arguments.initialPath ?? widget.arguments.config.path;
    if (startPath.isEmpty) startPath = '/';
    if (!startPath.startsWith('/')) startPath = '/$startPath';
    if (!startPath.endsWith('/')) startPath = '$startPath/';
    _currentPath = startPath;

    // 3. 回显数据 (初始选中项)
    if (widget.arguments.initialSelectedFiles != null) {
      _selectedPaths.addAll(widget.arguments.initialSelectedFiles!);
    }

    // 4. 根据模式加载数据
    if (widget.arguments.isShowSelectedOnly) {
      // 如果是“仅查看选中”模式，不需要网络请求，直接显示
      _isLoading = false;
    } else {
      // 如果是“浏览”模式，延迟加载网络数据
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadFiles();
      });
    }
  }

  /// 加载 WebDAV 目录数据
  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _client.readDir(_currentPath);
      // 排序：文件夹在前，文件在后
      list.sort((a, b) {
        if (a.isDir == b.isDir) {
          return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
        }
        return (a.isDir ?? false) ? -1 : 1;
      });

      if (mounted) {
        setState(() {
          _files = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载失败: $e';
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // 进入下一级目录 (递归 + 状态传递)
  // -------------------------------------------------------------------------
  Future<void> _enterDirectory(String dirName) async {
    String nextPath = '$_currentPath$dirName/';
    nextPath = nextPath.replaceAll('//', '/');

    final result = await NestedNavigationHelper.pushNamed(
      context,
      '/webdav/browser',
      arguments: WebDavBrowserArguments(
        config: widget.arguments.config,
        onFilesSelected: widget.arguments.onFilesSelected,
        initialPath: nextPath,
        initialSelectedFiles: _selectedPaths.toList(),
        // 递归进入时，通常肯定是要浏览，所以强制为 false
        isShowSelectedOnly: false, 
      ),
    );

    // 处理返回结果
    if (mounted) {
      if (result == true) {
        Navigator.pop(context, true); // 级联关闭
      } else if (result is List<String>) {
        setState(() {
          _selectedPaths.clear();
          _selectedPaths.addAll(result);
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // 切换选中状态
  // -------------------------------------------------------------------------
  void _toggleSelection(String path) {
    // 确保 path 格式统一
    String fullPath = path.startsWith('/') ? path : '$_currentPath$path';
    fullPath = fullPath.replaceAll('//', '/');

    setState(() {
      if (_selectedPaths.contains(fullPath)) {
        _selectedPaths.remove(fullPath);
      } else {
        _selectedPaths.add(fullPath);
      }
    });
  }

  // -------------------------------------------------------------------------
  // 确认保存逻辑
  // -------------------------------------------------------------------------
  void _confirmSelection() {
    if (_selectedPaths.isEmpty) {
      LZFToast.show(context, '请先勾选文件或文件夹');
      return;
    }

    if (widget.arguments.onFilesSelected != null) {
      widget.arguments.onFilesSelected!(_selectedPaths.toList());
      Navigator.pop(context, true);
    } else {
      // 如果没有回调，默认行为是返回数据
      Navigator.pop(context, _selectedPaths.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    // 动态计算按钮文字
    String btnLabel = '请选择';
    if (_selectedPaths.isNotEmpty) {
      btnLabel = '保存(${_selectedPaths.length})';
    }

    // 根据模式决定标题
    String titleText = widget.arguments.isShowSelectedOnly
        ? '已选列表 (${_selectedPaths.length})'
        : (_currentPath == '/' ? widget.arguments.config.name : _getDirName(_currentPath));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _selectedPaths.toList());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titleText),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.pop(context, _selectedPaths.toList());
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check, size: 20),
              label: Text(btnLabel),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: widget.arguments.isShowSelectedOnly
              ? null // 预览模式不显示路径条
              : PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: ThemeUtils.select(context, light: Colors.white12, dark: Colors.black12),
                    child: Text(
                      _currentPath,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ),
        // 根据模式构建不同的 Body
        body: widget.arguments.isShowSelectedOnly 
            ? _buildSelectedList() 
            : _buildBrowserContent(),
      ),
    );
  }

  String _getDirName(String path) {
    final parts = path.split('/');
    final validParts = parts.where((s) => s.isNotEmpty).toList();
    return validParts.isNotEmpty ? validParts.last : path;
  }

  // -------------------------------------------------------------------------
  // 模式一：浏览网络文件列表
  // -------------------------------------------------------------------------
  Widget _buildBrowserContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            RadixButton(
                label: '重试',
                variant: RadixButtonVariant.outline,
                onPressed: _loadFiles)
          ],
        ),
      );
    }

    if (_files.isEmpty)
      return const Center(child: Text("空文件夹", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isDir = file.isDir ?? false;
        final fileName = file.name ?? 'Unknown';
        final fullPath = '$_currentPath$fileName'.replaceAll('//', '/');
        final isSelected = _selectedPaths.contains(fullPath);

        return ListTile(
          leading: Icon(
            isDir ? Icons.folder : Icons.description,
            color: isDir ? Theme.of(context).colorScheme.primary : Colors.grey,
            size: 32,
          ),
          title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: isDir ? null : Text(_formatSize(file.size), style: const TextStyle(fontSize: 12)),
          trailing: Checkbox(
            value: isSelected,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => _toggleSelection(fileName),
          ),
          onTap: () {
            if (isDir) {
              _enterDirectory(fileName);
            } else {
              _toggleSelection(fileName);
            }
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 模式二：仅显示选中的平铺列表 (本地数据)
  // -------------------------------------------------------------------------
  Widget _buildSelectedList() {
    if (_selectedPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.playlist_remove, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("未选择任何文件", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            RadixButton(
              label: '去添加',
              variant: RadixButtonVariant.solid,
              onPressed: () {
                // 跳转到浏览模式
                // 这里我们模拟“进入根目录”的效果，或者你可以 pop 回去让上层处理
                // 但更好的体验是：直接切换到浏览模式
                NestedNavigationHelper.pushNamed(
                  context,
                  '/webdav/browser',
                  arguments: WebDavBrowserArguments(
                    config: widget.arguments.config,
                    onFilesSelected: widget.arguments.onFilesSelected,
                    initialPath: widget.arguments.config.path, // 从配置的根目录开始
                    initialSelectedFiles: _selectedPaths.toList(),
                    isShowSelectedOnly: false, // 强制进入浏览模式
                  ),
                ).then((result) {
                  // 从浏览页面回来，更新当前的列表
                   if (result is List<String> && mounted) {
                    setState(() {
                      _selectedPaths.clear();
                      _selectedPaths.addAll(result);
                    });
                  } else if (result == true && mounted) {
                     // 级联保存
                     Navigator.pop(context, true);
                  }
                });
              },
            ),
          ],
        ),
      );
    }

    final list = _selectedPaths.toList();
    // 简单排序，让路径好看点
    list.sort(); 

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final path = list[index];
        final isDir = path.endsWith('/'); // WebDAV约定目录以/结尾，或者根据图标判断
        
        return ListTile(
          leading: Icon(
            // 这里因为只有路径字符串，我们简单通过后缀判断目录
            // 如果你的逻辑里选中目录没有/结尾，这里可能需要改一下
            path.endsWith('/') ? Icons.folder : Icons.description,
            color: Colors.grey,
          ),
          title: Text(path, style: const TextStyle(fontSize: 14)),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _toggleSelection(path), // 这里调用 toggle 会直接移除
          ),
        );
      },
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}