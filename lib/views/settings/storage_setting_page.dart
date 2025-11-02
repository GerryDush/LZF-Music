import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:webdav_client/webdav_client.dart';
import '../../router/route_observer.dart';
// 假设您的 LZFDialog 和 LZFToast 在以下路径
import '../../widgets/lzf_dialog.dart';
import '../../widgets/lzf_toast.dart';

class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  StorageSettingPageState createState() => StorageSettingPageState();
}

class StorageSettingPageState extends State<StorageSettingPage>
    with RouteAware {
  List<StorageConfig> _storageList = [];

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
  }

  @override
  void didPushNext() {
    debugPrint("StorageSettingPage: didPushNext (我被盖住了)");
  }

  Future<void> _loadStorageList() async {
    // TODO: 从持久化存储加载配置列表
    setState(() {
      _storageList = [];
    });
  }

  Future<void> _saveStorageList() async {
    // TODO: 保存到持久化存储
  }

  void _showAddStorageDialog({StorageConfig? editConfig, int? editIndex}) {
    LZFDialog.show(
      context,
      width: 600,
      titleText: editConfig == null ? '添加存储' : '编辑存储',
      content: StorageConfigDialogContent(
        config: editConfig,
        onSave: (config) {
          setState(() {
            if (editIndex != null) {
              _storageList[editIndex] = config;
            } else {
              _storageList.add(config);
            }
          });
          _saveStorageList();
          LZFDialog.close(context); // 保存后关闭弹窗
        },
      ),
      // LZFDialog 默认的按钮逻辑在 content 内部处理，所以这里可以不传
      // 如果需要在外部控制按钮，则需要修改 LZFDialog 的实现
      // 这里我们在 StorageConfigDialogContent 内部实现按钮逻辑
    );
  }

  void _deleteStorage(int index) {
    LZFDialog.show(
      context,
      titleText: '确认删除',
      content: Text('确定要删除存储「${_storageList[index].name}」吗？此操作无法撤销。'),
      confirmText: '删除',
      danger: true,
      onConfirm: () {
        setState(() {
          _storageList.removeAt(index);
        });
        _saveStorageList();
        LZFToast.show(context, '已删除存储配置');
      },
      cancelText: '取消',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _storageList.isEmpty ? _buildEmptyState() : _buildStorageList(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddStorageDialog(),
          icon: const Icon(Icons.add),
          label: const Text('添加存储'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有添加存储',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加 WebDAV 或其他云存储开始同步数据',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _storageList.length,
      itemBuilder: (context, index) {
        final storage = _storageList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                _showAddStorageDialog(editConfig: storage, editIndex: index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStorageIcon(storage.type),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                storage.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                storage.type == StorageType.webdav
                                    ? 'WebDAV'
                                    : '阿里云',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              storage.protocol == 'https'
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${storage.protocol}://${storage.host}${storage.path}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (storage.username.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                storage.username,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 菜单按钮
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddStorageDialog(
                            editConfig: storage, editIndex: index);
                      } else if (value == 'delete') {
                        _deleteStorage(index);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('编辑'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('删除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getStorageIcon(StorageType type) {
    switch (type) {
      case StorageType.webdav:
        return Icons.cloud_outlined;
      case StorageType.aliyun:
        return Icons.cloud_upload_outlined;
    }
  }
}

// 将原来的 StorageConfigDialog 的内容提取出来，作为 LZFDialog 的 content
class StorageConfigDialogContent extends StatefulWidget {
  final StorageConfig? config;
  final Function(StorageConfig) onSave;

  const StorageConfigDialogContent({
    super.key,
    this.config,
    required this.onSave,
  });

  @override
  State<StorageConfigDialogContent> createState() =>
      _StorageConfigDialogContentState();
}

class _StorageConfigDialogContentState
    extends State<StorageConfigDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _pathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  StorageType _selectedType = StorageType.webdav;
  String _selectedProtocol = 'https';
  bool _isPasswordVisible = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _hostController = TextEditingController(text: widget.config?.host ?? '');
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
    _hostController.dispose();
    _pathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isTesting = true);
    try {
      final url =
          '$_selectedProtocol://${_hostController.text}${_pathController.text}';
      final client = newClient(
        url,
        user: _usernameController.text,
        password: _passwordController.text,
      );
      client.setConnectTimeout(8000);
      client.setReceiveTimeout(8000);
      client.setSendTimeout(8000);
      await client.ping();
      if (mounted) {
        LZFToast.show(context, '✓ 连接成功');

            var list = await client.readDir('/');
    list.forEach((f) {
        print('${f.name} ${f.path}');
      });
      
      }
    } catch (e) {
      if (mounted) {
        LZFToast.show(context, '连接失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final config = StorageConfig(
      name: _nameController.text,
      type: _selectedType,
      protocol: _selectedProtocol,
      host: _hostController.text,
      path: _pathController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    widget.onSave(config);
  }

  // 1. 统一的输入框样式函数 (关键)
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    final focusedBorderColor = theme.colorScheme.primary;

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: fillColor,
      isDense: true,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: focusedBorderColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // 2. 创建一个可复用的表单行布局 (关键)
  Widget _buildFormRow({required String label, required Widget inputField}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80, // 统一标签宽度，确保对齐
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: inputField),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormRow(
              label: '存储类型',
              inputField: ElegantDropdown<StorageType>(
                value: _selectedType,
                hintText: '选择类型',
                items: const [
                  ElegantDropdownItem(
                      value: StorageType.webdav, text: 'WebDAV'),
                  ElegantDropdownItem(
                      value: StorageType.aliyun,
                      text: '阿里云 OSS (即将支持)',
                      disabled: true),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
            ),
            _buildFormRow(
              label: '存储名称',
              inputField: TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(hintText: '例如: 我的云盘'),
                validator: (v) => v == null || v.isEmpty ? '请输入存储名称' : null,
              ),
            ),
            _buildFormRow(
              label: '服务器',
              inputField: Row(
                children: [
                  ElegantDropdown<String>(
                    width: 110, // 可以指定固定宽度
                    value: _selectedProtocol,
                    items: const [
                      ElegantDropdownItem(value: 'https', text: 'HTTPS'),
                      ElegantDropdownItem(value: 'http', text: 'HTTP'),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedProtocol = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _hostController,
                      decoration: _buildInputDecoration(
                          hintText: 'example.com:8080'), // 复用之前的输入框样式
                      validator: (v) =>
                          v == null || v.isEmpty ? '请输入主机地址' : null,
                    ),
                  ),
                ],
              ),
            ),
            _buildFormRow(
              label: '路径',
              inputField: TextFormField(
                controller: _pathController,
                decoration: _buildInputDecoration(hintText: '/webdav'),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入路径';
                  if (!v.startsWith('/')) return '路径必须以 / 开头';
                  return null;
                },
              ),
            ),
            _buildFormRow(
              label: '用户名',
              inputField: TextFormField(
                controller: _usernameController,
                decoration: _buildInputDecoration(hintText: '选填'),
              ),
            ),
            _buildFormRow(
              label: '密码',
              inputField: TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _buildInputDecoration(
                  hintText: '选填',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 底部按钮区域
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_find),
                label: Text(_isTesting ? '测试中...' : '测试连接'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => LZFDialog.close(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 存储配置模型 (保持不变)
class StorageConfig {
  final String name;
  final StorageType type;
  final String protocol;
  final String host;
  final String path;
  final String username;
  final String password;

  StorageConfig({
    required this.name,
    required this.type,
    required this.protocol,
    required this.host,
    required this.path,
    this.username = '',
    this.password = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'protocol': protocol,
      'host': host,
      'path': path,
      'username': username,
      'password': password,
    };
  }

  factory StorageConfig.fromJson(Map<String, dynamic> json) {
    return StorageConfig(
      name: json['name'],
      type: StorageType.values.firstWhere((e) => e.name == json['type']),
      protocol: json['protocol'],
      host: json['host'],
      path: json['path'],
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }
}

enum StorageType {
  webdav,
  aliyun,
}

class ElegantDropdownItem<T> {
  final T value;
  final String text;
  final bool disabled;

  const ElegantDropdownItem(
      {required this.value, required this.text, this.disabled = false});
}

class ElegantDropdown<T> extends StatefulWidget {
  final T? value;
  final List<ElegantDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final double width;

  const ElegantDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hintText = '',
    this.width = double.infinity,
  });

  @override
  State<ElegantDropdown<T>> createState() => _ElegantDropdownState<T>();
}

class _ElegantDropdownState<T> extends State<ElegantDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool get _isMenuOpen =>
      _animationController.status == AnimationStatus.completed ||
      _animationController.status == AnimationStatus.forward;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
  final overlay = Overlay.of(context);
  final renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
  final size = renderBox.size;

  // 1. 创建屏障层 (Barrier)
  _barrierEntry = OverlayEntry(
    builder: (context) => Positioned.fill(
      // 使用 Flutter 内置的 ModalBarrier，它能很好地处理点击事件
      child: GestureDetector(
        onTap: _hideMenu, // 点击屏障时关闭菜单
        behavior: HitTestBehavior.opaque, // 确保整个区域都能响应点击
        child: Container(color: Colors.transparent), // 透明背景
      ),
    ),
  );

  // 2. 创建菜单层 (和以前一样)
  _overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      width: size.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0.0, size.height + 6.0),
        child: _buildMenu(),
      ),
    ),
  );

  // 3. 关键：先插入屏障，再插入菜单
  overlay.insert(_barrierEntry!);
  overlay.insert(_overlayEntry!);

  _animationController.forward();
}

void _hideMenu() async {
  // 等待动画完成
  await _animationController.reverse();

  // 关键：同时移除菜单和屏障
  _overlayEntry?.remove();
  _overlayEntry = null;

  _barrierEntry?.remove();
  _barrierEntry = null;
}

  void _onItemSelected(ElegantDropdownItem<T> item) {
    if (item.disabled) return;
    widget.onChanged(item.value);
    _hideMenu();
  }

  // 构建真正美观的菜单
  Widget _buildMenu() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: Container(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(padding: EdgeInsets.all(6),child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                shrinkWrap: true,
                 separatorBuilder: (context, index) => const SizedBox(height: 6.0),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = item.value == widget.value;

                  return Material(
                      // 1. 直接在 Material 上定义形状
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      // 2. 将背景色也移到 Material 上
                      color: isSelected
                          ? ThemeUtils.primaryColor(context).withOpacity(0.1)
                          : Colors.transparent,
                      // 3. 使用 Clip.antiAlias 确保子内容被完美裁剪
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _onItemSelected(item),
                        splashColor: item.disabled ? Colors.transparent : null,
                        highlightColor:
                            item.disabled ? Colors.transparent : null,
                        child: Container(
                          // 4. Container 现在只负责内边距(padding)
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Text(
                            item.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: item.disabled
                                  ? theme.disabledColor
                                  : (isSelected
                                      ? ThemeUtils.primaryColor(context)
                                      : theme.textTheme.bodyLarge?.color),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                },
              ),),
            ),
          ),
          )
        ),
      ),
    );
  }

  // 构建按钮部分
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    final selectedItem = widget.items.firstWhere(
        (item) => item.value == widget.value,
        orElse: () => ElegantDropdownItem<T>(
            value: widget.value as T, text: widget.hintText));

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        key: _buttonKey,
        width: widget.width,
        child: GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _isMenuOpen
                    ? ThemeUtils.primaryColor(context)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItem.text,
                    style: TextStyle(
                      color: widget.value != null
                          ? theme.textTheme.bodyLarge?.color
                          : theme.hintColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
