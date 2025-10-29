//
//  FileManager+ObjectCamp.swift
//  MyLovingDoll
//
//  ObjectCamp 文件管理扩展
//

import Foundation
import UIKit

extension FileManager {
    /// ObjectCamp 根目录
    static func objectCampDirectory() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent("ObjectCamp", isDirectory: true)
    }
    
    /// 特定 specId 的根目录
    static func specDirectory(for specId: String) -> URL {
        return objectCampDirectory().appendingPathComponent(specId, isDirectory: true)
    }
    
    /// 主体贴纸目录
    static func subjectsDirectory(for specId: String) -> URL {
        return specDirectory(for: specId).appendingPathComponent("subjects", isDirectory: true)
    }
    
    /// 缩略图目录
    static func thumbnailsDirectory(for specId: String) -> URL {
        return specDirectory(for: specId).appendingPathComponent("thumbnails", isDirectory: true)
    }
    
    /// 临时目录
    static func tempDirectory(for specId: String) -> URL {
        return specDirectory(for: specId).appendingPathComponent("temp", isDirectory: true)
    }
    
    /// 确保目录存在
    static func ensureDirectory(_ url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// 保存主体贴纸
    static func saveSubjectSticker(_ image: UIImage, specId: String, subjectId: UUID) throws -> String {
        let dir = subjectsDirectory(for: specId)
        try ensureDirectory(dir)
        
        let filename = "\(subjectId.uuidString).png"
        let fileURL = dir.appendingPathComponent(filename)
        
        guard let data = image.pngData() else {
            throw NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        
        try data.write(to: fileURL)
        return "subjects/\(filename)"
    }
    
    /// 保存缩略图
    static func saveThumbnail(_ image: UIImage, specId: String, subjectId: UUID) throws -> String {
        let dir = thumbnailsDirectory(for: specId)
        try ensureDirectory(dir)
        
        let filename = "\(subjectId.uuidString)_thumb.jpg"
        let fileURL = dir.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        try data.write(to: fileURL)
        return "thumbnails/\(filename)"
    }
    
    /// 读取图片
    static func loadImage(relativePath: String, specId: String) -> UIImage? {
        let fileURL = specDirectory(for: specId).appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// 删除特定 spec 的所有文件
    static func clearSpecData(for specId: String) throws {
        let dir = specDirectory(for: specId)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
    
    /// 删除所有 ObjectCamp 数据
    static func clearAllObjectCampData() throws {
        let dir = objectCampDirectory()
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
