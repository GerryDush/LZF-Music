import 'package:flutter/material.dart';
import '../lzf_text_feild.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void _toggleTheme() => setState(() => _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radix Style TextField Demo',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      home: DemoPage(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  const DemoPage({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final TextEditingController _ctrl = TextEditingController();
  final TextEditingController _ctrl2 = TextEditingController();
  String? _error;
  bool _disabled = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radix Style TextField'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RadixTextField(
              controller: _ctrl,
              label: 'Username',
              placeholder: 'Enter your username',
              leading: const Icon(Icons.person, size: 18),
              clearable: true,
              onChanged: (v) {
                // 简单示例验证：长度 < 3 报错
                setState(() => _error = (v.length < 3 && v.isNotEmpty) ? '用户名至少 3 个字符' : null);
              },
              errorText: _error,
            ),
            const SizedBox(height: 16),
            RadixTextField(
              controller: _ctrl2,
              label: 'Email (disabled)',
              placeholder: 'you@example.com',
              trailing: const Icon(Icons.email_outlined, size: 18),
              enabled: !_disabled,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _disabled = !_disabled),
                  child: Text(_disabled ? 'Enable' : 'Disable'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _ctrl.clear();
                    _ctrl2.clear();
                    setState(() => _error = null);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}