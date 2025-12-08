import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    var tabBarVC: UITabBarController?
    var flutterEngine: FlutterEngine?
    private var methodChannelInitialized = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let flutterVC = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        flutterEngine = flutterVC.engine

        // 创建悬浮 TabBar
        setupTabBar(on: flutterVC)
        // 延迟 0.1 秒初始化 MethodChannel，确保 Flutter 已渲染
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.initializeMethodChannelIfNeeded()
    }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupTabBar(on flutterVC: UIViewController) {
        tabBarVC = UITabBarController()

        // 库
        let libraryVC = UIViewController()
        libraryVC.view.backgroundColor = .clear
        libraryVC.tabBarItem = UITabBarItem(title: "库", image: UIImage(systemName: "music.note.list"), tag: 0)

        // 喜欢
        let favoritesVC = UIViewController()
        favoritesVC.view.backgroundColor = .clear
        favoritesVC.tabBarItem = UITabBarItem(title: "喜欢", image: UIImage(systemName: "heart"), tag: 1)

        // 最近播放
        let recentVC = UIViewController()
        recentVC.view.backgroundColor = .clear
        recentVC.tabBarItem = UITabBarItem(title: "最近播放", image: UIImage(systemName: "clock"), tag: 2)

        // 系统设置
        let settingsVC = UIViewController()
        settingsVC.view.backgroundColor = .clear
        settingsVC.tabBarItem = UITabBarItem(title: "系统设置", image: UIImage(systemName: "gear"), tag: 3)

        tabBarVC?.viewControllers = [libraryVC, favoritesVC, recentVC, settingsVC]

        // 添加到 Flutter 顶层
        flutterVC.addChild(tabBarVC!)
        flutterVC.view.addSubview(tabBarVC!.view)
        tabBarVC!.didMove(toParent: flutterVC)

        // 设置只显示 tabBar，高度固定
        let tabBarHeight: CGFloat = 49
        tabBarVC!.view.frame = CGRect(
            x: 0,
            y: flutterVC.view.bounds.height - tabBarHeight,
            width: flutterVC.view.bounds.width,
            height: tabBarHeight
        )

        // 背景透明，不遮挡 Flutter
        tabBarVC!.view.backgroundColor = .clear
        tabBarVC!.tabBar.backgroundColor = .clear
        tabBarVC!.tabBar.isTranslucent = true

        // 设置 delegate
        tabBarVC?.delegate = self
    }

    private func initializeMethodChannelIfNeeded() {
        guard !methodChannelInitialized, let engine = flutterEngine else { return }

        let channel = FlutterMethodChannel(name: "native_tab_bar", binaryMessenger: engine.binaryMessenger)

        // Flutter 调用原生切换 Tab 或隐藏/显示
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "selectTab":
                if let index = call.arguments as? Int {
                    self?.tabBarVC?.selectedIndex = index
                    result("Tab switched to \(index)")
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Expected int", details: nil))
                }
            case "setTabBarHidden":
                if let hidden = call.arguments as? Bool {
                    self?.setTabBar(hidden: hidden, animated: true)
                    result("TabBar \(hidden ? "hidden" : "shown")")
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Expected bool", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        methodChannelInitialized = true
    }

    private var tabBarOriginalY: CGFloat?

func setTabBar(hidden: Bool, animated: Bool = true) {
    guard let tabBar = tabBarVC?.tabBar, let parentView = tabBarVC?.parent?.view else { return }

    // 记录初始位置
    if tabBarOriginalY == nil {
        tabBarOriginalY = tabBar.frame.origin.y
    }

    let targetY = hidden ? parentView.bounds.height+50 : tabBarOriginalY!

    let updateFrame = {
        tabBar.frame.origin.y = targetY
    }

    if animated {
        UIView.animate(withDuration: 0.25, animations: updateFrame)
    } else {
        updateFrame()
    }

    // 通知 Flutter 当前状态
    guard let engine = flutterEngine else { return }
    let channel = FlutterMethodChannel(name: "native_tab_bar", binaryMessenger: engine.binaryMessenger)
    channel.invokeMethod("onTabBarVisibilityChanged", arguments: !hidden)

    
}
}

// MARK: - UITabBarControllerDelegate
extension AppDelegate: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        // 选中事件回传 Flutter
        guard let engine = flutterEngine else { return }
        let channel = FlutterMethodChannel(name: "native_tab_bar", binaryMessenger: engine.binaryMessenger)
        channel.invokeMethod("onTabSelected", arguments: tabBarController.selectedIndex)
    }
}