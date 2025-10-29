//
//  ObjectRecognitionAdapter.swift
//  MyLovingDoll
//
//  ObjectRecognitionKit 适配器 - 桥接 SwiftData 模型
//

import Foundation
import SwiftData
import CoreGraphics
import ObjectRecognitionKit

/// SwiftData Subject → RecognizedSubject 转换
extension Subject {
    func toRecognizedSubject() -> RecognizedSubject {
        // 解码特征向量
        let features = decodeFeatureVector(featureVector)
        
        // 解码边界框
        let bbox = decodeBoundingBox(boundingBox)
        
        return RecognizedSubject(
            id: id.uuidString,
            imagePath: stickerPath,
            thumbnailPath: thumbnailPath,
            boundingBox: bbox,
            confidence: confidence,
            featureVector: features,
            extractedAt: extractedAt,
            extractionMethod: extractionMethod == "manual" ? .manual : .auto,
            entityId: entity?.id.uuidString,
            isMarkedAsNonTarget: isMarkedAsNonTarget,
            lastAdjustedAt: lastAdjustedAt
        )
    }
    
    private func decodeFeatureVector(_ json: String?) -> [Float] {
        guard let json = json,
              let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([Float].self, from: data) else {
            return []
        }
        return array
    }
    
    private func decodeBoundingBox(_ json: String?) -> CGRect? {
        guard let json = json,
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return nil
        }
        return CGRect(
            x: dict["x"] ?? 0,
            y: dict["y"] ?? 0,
            width: dict["width"] ?? 0,
            height: dict["height"] ?? 0
        )
    }
}

/// RecognizedSubject → SwiftData Subject 更新
extension RecognizedSubject {
    func updateSubject(_ subject: Subject) {
        // 编码特征向量
        if let data = try? JSONEncoder().encode(featureVector),
           let json = String(data: data, encoding: .utf8) {
            subject.featureVector = json
        }
        
        // 编码边界框
        if let bbox = boundingBox {
            let dict = ["x": bbox.origin.x, "y": bbox.origin.y, "width": bbox.width, "height": bbox.height]
            if let data = try? JSONEncoder().encode(dict),
               let json = String(data: data, encoding: .utf8) {
                subject.boundingBox = json
            }
        }
        
        subject.stickerPath = imagePath
        subject.thumbnailPath = thumbnailPath
        subject.confidence = confidence
        subject.extractedAt = extractedAt
        subject.extractionMethod = extractionMethod == .manual ? "manual" : "auto"
        subject.isMarkedAsNonTarget = isMarkedAsNonTarget
        subject.lastAdjustedAt = lastAdjustedAt
    }
}

/// Entity → RecognizedEntity 转换
extension Entity {
    func toRecognizedEntity() -> RecognizedEntity {
        let representativePath = subjects?.first?.stickerPath
        
        return RecognizedEntity(
            id: id.uuidString,
            customName: customName,
            averageConfidence: averageConfidence,
            subjectCount: subjects?.count ?? 0,
            createdAt: createdAt,
            updatedAt: updatedAt,
            representativeImagePath: representativePath
        )
    }
}
