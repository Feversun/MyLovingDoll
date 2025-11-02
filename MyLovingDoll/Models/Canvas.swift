//
//  Canvas.swift
//  MyLovingDoll
//
//  画布数据模型
//

import Foundation
import SwiftUI
import SwiftData

/// 画布
@Model
final class Canvas {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var thumbnailPath: String? // 缩略图路径
    @Relationship(deleteRule: .cascade) var elements: [CanvasElement]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.elements = []
    }
    
    func addElement(_ element: CanvasElement) {
        if elements == nil {
            elements = []
        }
        elements?.append(element)
        updatedAt = Date()
    }
    
    func removeElement(_ element: CanvasElement) {
        elements?.removeAll { $0.id == element.id }
        updatedAt = Date()
    }
    
    func bringElementForward(_ element: CanvasElement) {
        guard let elements = elements else { return }
        let maxZIndex = elements.map { $0.zIndex }.max() ?? 0
        element.zIndex = min(element.zIndex + 1, maxZIndex + 1)
        updatedAt = Date()
    }
    
    func sendElementBackward(_ element: CanvasElement) {
        element.zIndex = max(element.zIndex - 1, 0)
        updatedAt = Date()
    }
}

/// 画布元素
@Model
final class CanvasElement {
    var id: UUID
    var type: String // ElementType 的 rawValue
    var assetName: String // 素材名称（PDF文件名或娃娃ID）
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotation: Double // 角度
    var zIndex: Double
    var canvas: Canvas?
    
    // 娃娃特有字段
    var dollEntityId: String? // Entity ID
    var dollSubjectId: String? // Subject ID
    var dollStickerPath: String? // sticker 路径
    var dollSpecId: String? // spec ID
    
    init(type: ElementType, assetName: String, position: CGPoint, scale: Double = 1.0) {
        self.id = UUID()
        self.type = type.rawValue
        self.assetName = assetName
        self.positionX = Double(position.x)
        self.positionY = Double(position.y)
        self.scale = scale
        self.rotation = 0
        self.zIndex = 0
    }
    
    // 创建娃娃元素
    init(dollAsset: DollAsset, position: CGPoint, scale: Double = 1.0) {
        self.id = UUID()
        self.type = ElementType.doll.rawValue
        self.assetName = dollAsset.entityName
        self.positionX = Double(position.x)
        self.positionY = Double(position.y)
        self.scale = scale
        self.rotation = 0
        self.zIndex = 0
        
        // 设置娃娃特有字段
        self.dollEntityId = dollAsset.entityId.uuidString
        self.dollSubjectId = dollAsset.subjectId.uuidString
        self.dollStickerPath = dollAsset.stickerPath
        self.dollSpecId = dollAsset.specId
    }
    
    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
        }
    }
    
    var elementType: ElementType {
        ElementType(rawValue: type) ?? .decoration
    }
}

/// 元素类型
enum ElementType: String, CaseIterable, Identifiable {
    case doll = "doll"              // 娃娃主体
    case furniture = "furniture"    // 家具
    case bubble = "bubble"          // 对话气泡
    case decoration = "decoration"  // 装饰元素
    case background = "background"  // 背景
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .doll: return "娃娃"
        case .furniture: return "家具"
        case .bubble: return "气泡"
        case .decoration: return "装饰"
        case .background: return "背景"
        }
    }
    
    var icon: String {
        switch self {
        case .doll: return "person.fill"
        case .furniture: return "sofa.fill"
        case .bubble: return "bubble.left.fill"
        case .decoration: return "star.fill"
        case .background: return "photo.fill"
        }
    }
}

/// 素材资源
struct Asset: Identifiable, Hashable {
    let id = UUID()
    let name: String        // PDF 文件名（不含扩展名）
    let category: ElementType
    let pdfName: String     // 完整 PDF 文件名
    
    init(name: String, category: ElementType) {
        self.name = name
        self.category = category
        self.pdfName = "\(name).pdf"
    }
}

/// 娃娃素材（从对象库获取）
struct DollAsset: Identifiable, Hashable {
    let id = UUID()
    let entityId: UUID
    let subjectId: UUID
    let entityName: String
    let stickerPath: String
    let specId: String
    
    var displayName: String {
        entityName
    }
}
