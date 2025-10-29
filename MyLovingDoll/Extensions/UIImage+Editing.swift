//
//  UIImage+Editing.swift
//  MyLovingDoll
//
//  图片编辑扩展
//

import UIKit

extension UIImage {
    /// 旋转图片
    func rotate(radians: Double) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .size
        
        // 去除负数
        newSize.width = abs(newSize.width)
        newSize.height = abs(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 移动坐标系到中心
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: CGFloat(radians))
        
        // 绘制图片
        draw(in: CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 水平翻转
    func flipHorizontally() -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 翻转坐标系
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1, y: 1)
        
        // 绘制图片
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 垂直翻转
    func flipVertically() -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 翻转坐标系
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        
        // 绘制图片
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 裁剪图片
    func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // 转换坐标系 (UIKit 和 Core Graphics 坐标系不同)
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
    
    /// 调整尺寸
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 按比例缩放
    func scaled(by scale: CGFloat) -> UIImage? {
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return resize(to: newSize)
    }
}
