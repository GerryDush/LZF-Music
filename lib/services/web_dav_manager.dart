import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../model/storage_config.dart';

class WebDavManager {
  WebDavManager._internal();
  static final WebDavManager _instance = WebDavManager._internal();
  factory WebDavManager() => _instance;

  // 内存中的配置列表
  List<StorageConfig> _configs = [];
  
  // Client 缓存池
  final Map<String, webdav.Client> _clients = {};

  // 获取当前所有配置
  List<StorageConfig> get configs => List.unmodifiable(_configs);

  /// 【核心】App启动时调用：从本地加载配置并预热 Client
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = prefs.getString('storage_list') ?? '[]';
      final List<dynamic> decoded = jsonDecode(jsonStr);
      
      _configs = decoded.map((item) => StorageConfig.fromJson(item)).toList();
      
      // 预热：虽然不立即发起网络请求，但为每个配置准备好 Client 对象
      for (var config in _configs) {
        _createClient(config);
      }
      debugPrint("WebDavManager initialized with ${_configs.length} configs.");
    } catch (e) {
      debugPrint("WebDavManager init failed: $e");
      _configs = [];
    }
  }

  /// 获取指定配置的 Client
  webdav.Client getClient(StorageConfig config) {
    if (_clients.containsKey(config.id)) {
      return _clients[config.id]!;
    }
    return _createClient(config);
  }

  /// 创建并缓存 Client
  webdav.Client _createClient(StorageConfig config) {
    // 确保 URL 格式正确
    final baseUrl = config.baseUrl; 
    
    final client = webdav.newClient(
      baseUrl,
      user: config.username,
      password: config.password,
    );

    client.setConnectTimeout(15000); // 15s 连接超时
    client.setSendTimeout(15000);
    client.setReceiveTimeout(30000);

    // 缓存起来
    _clients[config.id] = client;
    return client;
  }

  /// 测试连接 (用于添加/编辑页面)
  /// 如果成功，会自动缓存该 Client
  Future<bool> testConnection(StorageConfig config) async {
    // 强制创建一个新的 Client 实例进行测试（防止旧缓存干扰）
    final client = _createClient(config); // 这会覆盖旧的缓存
    
    try {
      // 尝试读取目录
      await client.readDir(config.path.isEmpty ? '/' : config.path);
      return true;
    } catch (e) {
      // 连接失败，移除缓存，避免残留坏连接
      _clients.remove(config.id);
      rethrow;
    }
  }

  /// 添加或更新配置，并持久化
  Future<void> saveConfig(StorageConfig config) async {
    final index = _configs.indexWhere((e) => e.id == config.id);
    if (index != -1) {
      _configs[index] = config;
      // 如果密码或地址变了，testConnection 已经更新了缓存，这里不需要额外操作
      // 如果只是改名字，也不影响 client
    } else {
      _configs.add(config);
    }
    
    // 确保 Client 存在 (针对直接保存没测试的情况)
    if (!_clients.containsKey(config.id)) {
      _createClient(config);
    }

    await _persist();
  }

  /// 删除配置
  Future<void> deleteConfig(String id) async {
    _configs.removeWhere((e) => e.id == id);
    _clients.remove(id); // 移除连接缓存
    await _persist();
  }
  
  /// 仅更新选中文件列表 (无需重建 Client)
  Future<void> updateSelectedFiles(String id, List<String> files) async {
    final index = _configs.indexWhere((e) => e.id == id);
    if (index != -1) {
      _configs[index].selectedFiles = files;
      await _persist();
    }
  }

  /// 持久化到 SharedPreferences
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_configs.map((e) => e.toJson()).toList());
    await prefs.setString('storage_list', jsonStr);
  }
}