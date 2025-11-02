//
//  NetworkPermissionWarmer.swift
//  MyLovingDoll
//
//  网络权限预热器 - 在 App 启动时立即触发联网权限弹窗
//

import Photos
import UIKit

class NetworkPermissionWarmer {
    
    /// 在 App 启动时调用此方法，立即触发 iCloud 照片网络权限弹窗
    static func warmUp() {
        // 先检查照片权限
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        guard status == .authorized || status == .limited else {
            // 如果没有照片权限，等待用户授权后再触发网络请求
            return
        }
        
        // 立即触发一个小的网络请求来让系统弹出联网权限
        Task {
            await triggerNetworkPermission()
        }
    }
    
    /// 触发网络权限弹窗
    private static func triggerNetworkPermission() async {
        // 获取第一张照片（最快的方式）
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let firstAsset = assets.firstObject else {
            return
        }
        
        // 请求一个很小的缩略图，启用网络访问
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true  // 关键：启用 iCloud 网络访问
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        
        // 请求一个非常小的图片来触发权限
        PHImageManager.default().requestImage(
            for: firstAsset,
            targetSize: CGSize(width: 1, height: 1),  // 最小尺寸，几乎不占用流量
            contentMode: .aspectFit,
            options: options
        ) { _, _ in
            // 不需要处理结果，只是为了触发权限弹窗
            print("[NetworkWarmer] 网络权限已触发")
        }
    }
}
