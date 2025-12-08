class StorageConfig {
  String id;
  String name;
  String type;
  String protocol;
  String server;
  String path;
  String username;
  String password;
  List<String> selectedFiles;

  StorageConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.protocol,
    required this.server,
    required this.path,
    required this.username,
    required this.password,
    this.selectedFiles = const [],
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
      'selectedFiles': selectedFiles,
    };
  }

  factory StorageConfig.fromJson(Map<String, dynamic> json) {
    return StorageConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'WebDAV',
      protocol: json['protocol'] ?? 'https',
      server: json['server'] ?? '',
      path: json['path'] ?? '/',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      selectedFiles: (json['selectedFiles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
  
  String get baseUrl {
    String cleanServer = server.replaceFirst(RegExp(r'^https?://'), '');
    return '${protocol.toLowerCase()}://$cleanServer';
  }
}