import Foundation
import AVKit
import UIKit

class AudioRouteHandler {
    
    /// 显示 AirPlay 选择器
    static func showAirPlayPicker() {
        DispatchQueue.main.async {
            // 创建 AVRoutePickerView
            let routePickerView = AVRoutePickerView()
            routePickerView.prioritizesVideoDevices = false
            
            // 触发路由选择器按钮
            for view in routePickerView.subviews {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    break
                }
            }
        }
    }
}
