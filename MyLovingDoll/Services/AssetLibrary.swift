//
//  AssetLibrary.swift
//  MyLovingDoll
//
//  素材库管理系统
//

import Foundation
import SwiftUI
import PDFKit
import Combine

/// 素材库管理器
class AssetLibrary: ObservableObject {
    static let shared = AssetLibrary()
    
    @Published var assets: [ElementType: [Asset]] = [:]
    
    private init() {
        loadAssets()
    }
    
    /// 从 Bundle 加载所有 PDF 素材
    private func loadAssets() {
        // 为每个类型加载素材
        for type in ElementType.allCases {
            let typeAssets = loadAssetsForType(type)
            assets[type] = typeAssets
        }
    }
    
    /// 加载指定类型的素材
    private func loadAssetsForType(_ type: ElementType) -> [Asset] {
        var result: [Asset] = []
        
        // 根据类型加载不同的素材
        switch type {
        case .doll:
            // 娃娃从对象库动态加载，这里返回空
            // 实际使用 loadDollAssets() 动态获取
            break
            
        case .furniture:
            result.append(contentsOf: [
                Asset(name: "sofa", category: .furniture),
                Asset(name: "table", category: .furniture),
                Asset(name: "chair", category: .furniture),
                Asset(name: "bed", category: .furniture)
            ])
            
        case .bubble:
            result.append(contentsOf: [
                Asset(name: "bubble_round", category: .bubble),
                Asset(name: "bubble_cloud", category: .bubble),
                Asset(name: "bubble_square", category: .bubble)
            ])
            
        case .decoration:
            result.append(contentsOf: [
                Asset(name: "star", category: .decoration),
                Asset(name: "heart", category: .decoration),
                Asset(name: "flower", category: .decoration),
                Asset(name: "sparkle", category: .decoration)
            ])
            
        case .background:
            result.append(contentsOf: [
                Asset(name: "bg_room", category: .background),
                Asset(name: "bg_garden", category: .background),
                Asset(name: "bg_sky", category: .background)
            ])
        }
        
        return result
    }
    
    /// 从 Bundle 加载 PDF 文件
    func loadPDF(named name: String) -> PDFDocument? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "pdf") else {
            print("⚠️ PDF 文件不存在: \(name).pdf")
            return nil
        }
        return PDFDocument(url: url)
    }
    
    /// 获取 PDF 的第一页作为图片
    func loadPDFImage(named name: String) -> UIImage? {
        guard let pdfDocument = loadPDF(named: name),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let pageBounds = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
        
        let image = renderer.image { context in
            UIColor.clear.set()
            context.fill(pageBounds)
            
            context.cgContext.translateBy(x: 0, y: pageBounds.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        return image
    }
    
    /// 获取素材图片（优先使用 PDF，fallback 到系统图标）
    func getAssetImage(for asset: Asset) -> Image {
        if let uiImage = loadPDFImage(named: asset.name) {
            return Image(uiImage: uiImage)
        }
        
        // Fallback: 使用系统图标
        return Image(systemName: asset.category.icon)
    }
    
    /// 获取分类下的所有素材
    func assets(for type: ElementType) -> [Asset] {
        assets[type] ?? []
    }
    
    /// 从对象库加载娃娃素材
    func loadDollAssets(from entities: [Entity]) -> [DollAsset] {
        var dollAssets: [DollAsset] = []
        
        for entity in entities {
            guard let subjects = entity.subjects, !subjects.isEmpty else { continue }
            
            // 为每个 Subject 创建一个 DollAsset
            for subject in subjects {
                let dollAsset = DollAsset(
                    entityId: entity.id,
                    subjectId: subject.id,
                    entityName: entity.customName ?? "未命名",
                    stickerPath: subject.stickerPath,
                    specId: entity.targetSpec?.specId ?? ""
                )
                dollAssets.append(dollAsset)
            }
        }
        
        return dollAssets
    }
}
