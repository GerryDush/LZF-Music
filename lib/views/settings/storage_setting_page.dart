import 'package:flutter/material.dart';
import 'package:lzf_music/utils/platform_utils.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import '../../services/web_dav_manager.dart'; 
import '../../widgets/lzf_toast.dart';
import '../../widgets/lzf_dialog.dart';
import '../../ui/lzf_button.dart';
import '../../ui/lzf_select.dart';
import '../../ui/lzf_text_feild.dart';
import '../../router/router.dart';
import '../../model/storage_config.dart';
import '../../router/route_observer.dart'; // 保持引用

class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  StorageSettingPageState createState() => StorageSettingPageState();
}

class StorageSettingPageState extends State<StorageSettingPage> with RouteAware {
  // 数据源直接从 Manager 获取，或者在 build 中获取
  List<StorageConfig> get _storageList => WebDavManager().configs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 页面返回时刷新 UI (数据在 Manager 中已经是最新的了)
    setState(() {}); 
  }

  // 打开文件浏览器
  void _openBrowser(StorageConfig config) {
    NestedNavigationHelper.pushNamed(
      context,
      '/webdav/browser',
      arguments: WebDavBrowserArguments(
        config: config,
        // UI上可能没有及时刷新，确保传递最新的 path (如果需要的话)
        initialPath: config.path, 
        initialSelectedFiles: config.selectedFiles,
        onFilesSelected: (List<String> selectedFiles) async {
          debugPrint("保存回调触发，文件数: ${selectedFiles.length}");
          
          // 调用 Manager 更新数据并持久化
          await WebDavManager().updateSelectedFiles(config.id, selectedFiles);
          
          setState(() {}); // 刷新当前列表显示
          if (mounted) {
            LZFToast.show(context, '已保存 ${selectedFiles.length} 个项目');
          }
        },
      ),
    );
  }

  // 显示添加对话框
  void _showAddStorageDialog() {
    LZFDialog.show(
      context,
      titleText: '添加存储',
      width: 400,
      content: _StorageForm(
        onSubmit: (config) async {
          // Manager 负责保存和更新列表
          await WebDavManager().saveConfig(config);
          setState(() {}); // 刷新 UI
          return true;
        },
      ),
    );
  }

  // 显示编辑对话框
  void _showEditStorageDialog(StorageConfig config) {
    LZFDialog.show(
      context,
      titleText: '编辑存储',
      width: 400,
      content: _StorageForm(
        config: config,
        onSubmit: (newConfig) async {
          await WebDavManager().saveConfig(newConfig);
          setState(() {});
          return true;
        },
      ),
    );
  }

  // 删除逻辑
  void _deleteStorage(StorageConfig config) {
    LZFDialog.show(
      context,
      titleText: '确认删除',
      content: Text('确定要删除存储 "${config.name}" 吗?'),
      danger: true,
      confirmText: '删除',
      onConfirm: () async {
        // 调用 Manager 删除
        await WebDavManager().deleteConfig(config.id);
        
        setState(() {}); // 刷新 UI
        LZFDialog.close(context);
        LZFToast.show(context, '删除成功');
      },
      cancelText: '取消',
    );
  }

  @override
  Widget build(BuildContext context) {
    // _storageList 是 getter，直接获取最新数据
    final list = _storageList;

    return Scaffold(
      backgroundColor: PlatformUtils.isMobile?ThemeUtils.backgroundColor(context):null,
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length + 1,
        itemBuilder: (context, index) {
          if (index == list.length) {
            return Center(
              child: Column(
                children: [
                  if (list.isEmpty) ...[
                    Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("暂无存储", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 20),
                  RadixButton(
                    label: '添加存储',
                    variant: RadixButtonVariant.outline,
                    size: RadixButtonSize.large,
                    onPressed: _showAddStorageDialog,
                  )
                ],
              ),
            );
          }

          final storage = list[index];
          // UI 部分保持不变
          return GestureDetector(
            onTap: () => _openBrowser(storage),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeUtils.select(context, light: Colors.white, dark: Colors.black12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storage.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                            '${storage.protocol}://${storage.server}${storage.path}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  RadixSelect(
                      icon: Icons.edit_rounded,
                      borderRadius: 120,
                      menuWidth: 100,
                      items: const ['编辑', '删除'],
                      itemBuilder: (label) {
                        if (label == '编辑') return Text(label);
                        return const Text('删除', style: TextStyle(color: Colors.red));
                      },
                      onChanged: (v) {
                        if (v == '编辑') _showEditStorageDialog(storage);
                        if (v == '删除') _deleteStorage(storage);
                      })
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 表单部分 ---

typedef StorageSubmitCallback = Future<bool> Function(StorageConfig config);

class _StorageForm extends StatefulWidget {
  final StorageConfig? config;
  final StorageSubmitCallback onSubmit;

  const _StorageForm({super.key, this.config, required this.onSubmit});

  @override
  State<_StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends State<_StorageForm> {
  final _formKey = GlobalKey<FormState>();
  // 控制器保持不变...
  late TextEditingController _nameController;
  late TextEditingController _serverController;
  late TextEditingController _pathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  String _selectedType = 'WebDAV';
  String _selectedProtocol = 'https';
  bool _obscurePassword = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _serverController = TextEditingController(text: widget.config?.server ?? '');
    _pathController = TextEditingController(text: widget.config?.path ?? '/');
    _usernameController = TextEditingController(text: widget.config?.username ?? '');
    _passwordController = TextEditingController(text: widget.config?.password ?? '');

    if (widget.config != null) {
      _selectedType = widget.config!.type;
      _selectedProtocol = widget.config!.protocol;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _pathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  StorageConfig? saveAndGetConfig() {
    if (_nameController.text.isEmpty) {
      LZFToast.show(context, '请输入存储名称');
      return null;
    }
    if (_serverController.text.isEmpty) {
      LZFToast.show(context, '请输入服务器地址');
      return null;
    }
    
    // 如果是编辑模式，保留原有的 selectedFiles
    List<String> currentSelectedFiles = widget.config?.selectedFiles ?? [];

    return StorageConfig(
      id: widget.config?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _selectedType,
      protocol: _selectedProtocol,
      server: _serverController.text,
      path: _pathController.text.isEmpty ? '/' : _pathController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      selectedFiles: currentSelectedFiles, // 保持选中状态
    );
  }

  // 验证连接并保存
  Future<void> _checkConnectionAndSave() async {
    final config = saveAndGetConfig();
    if (config == null) return;

    setState(() => _isTesting = true);

    try {
      // 1. 【关键修改】使用 Manager 进行测试
      // 这会自动创建 Client，尝试 readDir，成功后缓存 Client
      await WebDavManager().testConnection(config);
      
      // 2. 测试通过，调用回调保存到列表
      await widget.onSubmit(config);

      if (mounted) {
        LZFDialog.close(context);
        LZFToast.show(context, '连接成功并已保存');
      }
    } catch (e) {
      debugPrint("WebDAV连接错误: $e");
      if (mounted) {
        // 这里可以解析 e 显示更友好的错误，比如 401 密码错误
        String msg = '连接失败';
        if (e.toString().contains('401')) msg += ': 账号或密码错误';
        else if (e.toString().contains('404')) msg += ': 路径不存在';
        else msg += ': 请检查服务器地址';
        
        LZFToast.show(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 构建逻辑保持不变...
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('存储名称'),
          RadixTextField(controller: _nameController, placeholder: '例如: 我的云盘', size: RadixFieldSize.small),
          const SizedBox(height: 8),
          
          const Text('服务器地址'),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: RadixSelect(
                  menuWidth: 120,
                  value: _selectedProtocol,
                  items: const ['https', 'http'],
                  onChanged: (v) => setState(() => _selectedProtocol = v),
                  size: RadixButtonSize.medium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RadixTextField(
                    controller: _serverController, 
                    placeholder: 'example.com:5005', 
                    size: RadixFieldSize.small
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          const Text('默认路径'),
          RadixTextField(controller: _pathController, placeholder: '/', size: RadixFieldSize.small),
          const SizedBox(height: 8),
          
          const Text('用户名'),
          RadixTextField(controller: _usernameController, size: RadixFieldSize.small),
          const SizedBox(height: 8),
          
          const Text('密码'),
          RadixTextField(
            controller: _passwordController,
            size: RadixFieldSize.small,
            trailing: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: RadixButton(
              label: _isTesting ? '正在连接...' : '保存并连接',
              variant: RadixButtonVariant.solid,
              size: RadixButtonSize.medium,
              disabled: _isTesting,
              onPressed: _checkConnectionAndSave,
            ),
          ),
        ],
      ),
    );
  }
}