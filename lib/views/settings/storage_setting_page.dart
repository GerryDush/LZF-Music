import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../router/route_observer.dart';
import '../../widgets/lzf_toast.dart';
import '../../widgets/lzf_dialog.dart';
import '../../ui/lzf_button.dart';
import '../../ui/lzf_select.dart';
import '../../ui/lzf_text_feild.dart';

// -------------------------------------------------------------------
// 存储配置模型 (无变化)
// -------------------------------------------------------------------

class StorageConfig {
  String id;
  String name;
  String type; // WebDAV, S3, etc.
  String protocol; // HTTP, HTTPS
  String server;
  String path;
  String username;
  String password;

  StorageConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.protocol,
    required this.server,
    required this.path,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'protocol': protocol,
      'server': server,
      'path': path,
      'username': username,
      'password': password,
    };
  }

  factory StorageConfig.fromJson(Map<String, dynamic> json) {
    return StorageConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'WebDAV',
      protocol: json['protocol'] ?? 'HTTPS',
      server: json['server'] ?? '',
      path: json['path'] ?? '/',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  String get fullUrl {
    return '${protocol.toLowerCase()}://$server$path';
  }
}

// -------------------------------------------------------------------
// 存储设置页面 (已修改)
// -------------------------------------------------------------------

class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  StorageSettingPageState createState() => StorageSettingPageState();
}

class StorageSettingPageState extends State<StorageSettingPage>
    with RouteAware {
  List<StorageConfig> _storageList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageList();
  }

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
  void didPush() {
    debugPrint("StorageSettingPage: didPush (页面被打开)");
  }

  @override
  void didPop() {
    debugPrint("StorageSettingPage: didPop (页面被关闭)");
  }

  @override
  void didPopNext() {
    debugPrint("StorageSettingPage: didPopNext (别的页面返回到我)");
    _loadStorageList(); // 重新加载数据
  }

  @override
  void didPushNext() {
    debugPrint("StorageSettingPage: didPushNext (我被盖住了)");
  }

  // 加载存储列表
  Future<void> _loadStorageList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageListJson = prefs.getString('storage_list') ?? '[]';
      final List<dynamic> decoded = jsonDecode(storageListJson);

      setState(() {
        _storageList =
            decoded.map((item) => StorageConfig.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载存储列表失败: $e');
      setState(() {
        _storageList = [];
        _isLoading = false;
      });
    }
  }

  // 保存存储列表
  Future<void> _saveStorageList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageListJson =
          jsonEncode(_storageList.map((e) => e.toJson()).toList());
      await prefs.setString('storage_list', storageListJson);
    } catch (e) {
      debugPrint('保存存储列表失败: $e');
      LZFToast.show(context, '保存失败: $e');
    }
  }

  // 添加存储 (已修改)
  void _showAddStorageDialog() {
    final formKey = GlobalKey<_StorageFormState>();
    LZFDialog.show(
      context,
      titleText: '添加存储',
      width: 600,
      content: _StorageForm(key: formKey),
      confirmText: '保存',
      onConfirm: () async {
        final newConfig = formKey.currentState?.saveAndGetConfig();
        if (newConfig != null) {
          setState(() {
            _storageList.add(newConfig);
          });
          await _saveStorageList();
          LZFDialog.close(context); // 确认成功后关闭弹窗
          LZFToast.show(context, '添加成功');
        }
      },
      cancelText: '取消',
    );
  }

  // 编辑存储 (已修改)
  void _showEditStorageDialog(StorageConfig config) {
    final formKey = GlobalKey<_StorageFormState>();
    LZFDialog.show(
      context,
      titleText: '编辑存储',
      width: 600,
      content: _StorageForm(key: formKey, config: config),
      confirmText: '保存',
      onConfirm: () async {
        final updatedConfig = formKey.currentState?.saveAndGetConfig();
        if (updatedConfig != null) {
          setState(() {
            final index = _storageList.indexWhere((e) => e.id == config.id);
            if (index != -1) {
              _storageList[index] = updatedConfig;
            }
          });
          await _saveStorageList();
          LZFDialog.close(context); // 确认成功后关闭弹窗
          LZFToast.show(context, '保存成功');
        }
      },
      cancelText: '取消',
    );
  }

  // 删除存储 (已修改)
  void _deleteStorage(StorageConfig config) {
    LZFDialog.show(
      context,
      titleText: '确认删除',
      content: Text('确定要删除存储 "${config.name}" 吗?'),
      danger: true,
      confirmText: '删除',
      onConfirm: () async {
        setState(() {
          _storageList.removeWhere((e) => e.id == config.id);
        });
        await _saveStorageList();
        LZFDialog.close(context); // 确认成功后关闭弹窗
        LZFToast.show(context, '删除成功');
      },
      cancelText: '取消',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 400,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _storageList.length,
                    itemBuilder: (context, index) {
                      final storage = _storageList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.cloud,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            storage.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                storage.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storage.fullUrl,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditStorageDialog(storage);
                              } else if (value == 'delete') {
                                _deleteStorage(storage);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('编辑'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('删除',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                FilledButton.icon(
                        onPressed: _showAddStorageDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('添加存储'),
                      ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------------
// 新的私有表单组件
// -------------------------------------------------------------------

class _StorageForm extends StatefulWidget {
  final StorageConfig? config;

  const _StorageForm({
    super.key,
    this.config,
  });

  @override
  State<_StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends State<_StorageForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _serverController;
  late TextEditingController _pathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  String _selectedType = 'WebDAV';
  String _selectedProtocol = 'HTTPS';
  bool _obscurePassword = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _serverController =
        TextEditingController(text: widget.config?.server ?? '');
    _pathController = TextEditingController(text: widget.config?.path ?? '/');
    _usernameController =
        TextEditingController(text: widget.config?.username ?? '');
    _passwordController =
        TextEditingController(text: widget.config?.password ?? '');

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

  // 测试连接
  Future<void> _testConnection() async {
    if (_serverController.text.isEmpty) {
      LZFToast.show(context, '请输入服务器地址');
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final client = newClient(
        '${_selectedProtocol.toLowerCase()}://${_serverController.text}',
        user: _usernameController.text,
        password: _passwordController.text,
      );

      client.setConnectTimeout(8000);
      client.setSendTimeout(8000);
      client.setReceiveTimeout(8000);

      await client.ping();

      if (mounted) {
        LZFToast.show(context, '连接成功!');
      }
    } catch (e) {
      if (mounted) {
        LZFToast.show(context, '连接失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  // 保存配置并返回配置对象，如果验证失败则返回 null
  StorageConfig? saveAndGetConfig() {
    // 简单验证
    if (_nameController.text.isEmpty) {
      LZFToast.show(context, '请输入存储名称');
      return null;
    }
    if (_serverController.text.isEmpty) {
      LZFToast.show(context, '请输入服务器地址');
      return null;
    }
    if (_pathController.text.isEmpty) {
      LZFToast.show(context, '请输入路径');
      return null;
    }

    return StorageConfig(
      id: widget.config?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _selectedType,
      protocol: _selectedProtocol,
      server: _serverController.text,
      path: _pathController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  // 构建表单行(label在左侧)
  Widget _buildFormRow(String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('存储类型'),
          RadixSelect(
            value: _selectedType,
            items: const ['WebDAV'],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
            size: RadixButtonSize.medium,
          ),
          const SizedBox(height: 8),
          Text('存储名称'),

          RadixTextField(
            controller: _nameController,
            placeholder: '例如: 我的云盘',
            size: RadixFieldSize.small,
          ),

          const SizedBox(height: 8),
          Text('服务器地址'),
          Row(
            children: [
              SizedBox(
                width: 102,
                child: RadixSelect(
                  value: _selectedProtocol,
                  items: const ['HTTPS', 'HTTP'],
                  onChanged: (value) {
                    setState(() {
                      _selectedProtocol = value;
                    });
                  },
                  size: RadixButtonSize.medium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RadixTextField(
                  controller: _serverController,
                  placeholder: 'example.com:8080',
                  size: RadixFieldSize.small,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('路径'),
          RadixTextField(
            controller: _pathController,
            placeholder: '/',
            size: RadixFieldSize.small,
          ),

          const SizedBox(height: 8),
          Text('用户名'),
          RadixTextField(
            controller: _usernameController,
            size: RadixFieldSize.small,
          ),

          const SizedBox(height: 8),
          Text('密码'),
          RadixTextField(
            controller: _passwordController,
            size: RadixFieldSize.small,
            trailing: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 24),

          // 测试连接按钮
          SizedBox(
            width: double.infinity,
            child: RadixButton(
              label: _isTesting ? '测试中...' : '测试连接',
              icon: _isTesting ? null : Icons.link,
              variant: RadixButtonVariant.outline,
              size: RadixButtonSize.medium,
              disabled: _isTesting,
              onPressed: _testConnection,
            ),
          ),
        ],
      ),
    );
  }
}
