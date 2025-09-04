import 'package:flutter/material.dart';
import '../../router/route_observer.dart';
class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  StorageSettingPageState createState() => StorageSettingPageState();
}

class StorageSettingPageState extends State<StorageSettingPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注册到 routeObserver
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 页面可见时回调
  @override
  void didPush() {
    debugPrint("StorageSettingPage: didPush (页面被打开)");
  }

  // 页面返回时回调
  @override
  void didPop() {
    debugPrint("StorageSettingPage: didPop (页面被关闭)");
  }

  // 从别的页面返回时
  @override
  void didPopNext() {
    debugPrint("StorageSettingPage: didPopNext (别的页面返回到我)");
  }

  // 跳转到别的页面时
  @override
  void didPushNext() {
    debugPrint("StorageSettingPage: didPushNext (我被盖住了)");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 返回
          },
        ),
      ),
      body: const Center(
        child: Text('存储设置页面内容'),
      ),
    );
  }
}