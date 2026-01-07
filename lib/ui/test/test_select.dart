import 'package:flutter/material.dart';
import '../lzf_select.dart';
import '../lzf_button.dart';

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

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radix Select Demo',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: RadixSelectDemo(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

//
// ======================================
// 🌈 主页面
// ======================================
//

class RadixSelectDemo extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RadixSelectDemo({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<RadixSelectDemo> createState() => _RadixSelectDemoState();
}

class _RadixSelectDemoState extends State<RadixSelectDemo> {
  String _selectedValue = 'New Tab';

  final _options = ['New Tab', 'New Window', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Radix Style Select'),
        actions: [
          IconButton(
            icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: RadixSelect(
          value: _selectedValue,
          items: _options,
          onChanged: (v) => setState(() => _selectedValue = v),
          size: RadixButtonSize.medium,
        ),
      ),
    );
  }
}

//
// ======================================
// 🧩 Radix Select 组件
// ======================================
//
