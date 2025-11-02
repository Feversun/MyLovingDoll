//
//  NetworkPermissionWarmer.swift
//  MyLovingDoll
//
//  网络权限预热器 - 在 App 启动时立即触发联网权限弹窗
//

import Foundation

class NetworkPermissionWarmer {
    
    /// 在 App 启动时调用此方法，立即触发 App 联网权限弹窗
    static func warmUp() {
        Task {
            await triggerNetworkPermission()
        }
    }
    
    /// 触发网络权限弹窗
    private static func triggerNetworkPermission() async {
        // 发起一个简单的 HTTP 请求来触发 iOS 的联网权限弹窗
        // 使用苹果的 captive.apple.com 来检测网络连接
        guard let url = URL(string: "https://captive.apple.com/hotspot-detect.html") else {
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("[NetworkWarmer] 网络权限已触发, 状态码: \(httpResponse.statusCode)")
            }
        } catch {
            // 即使失败也已经触发了权限弹窗
            print("[NetworkWarmer] 网络请求完成: \(error.localizedDescription)")
        }
    }
}
