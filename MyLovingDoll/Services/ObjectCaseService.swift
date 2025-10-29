//
//  ObjectCaseService.swift
//  MyLovingDoll
//
//  ObjectCase - 主体提取服务
//

import Foundation
import UIKit
import Vision
import Photos
import SwiftData
import Combine

@MainActor
class ObjectCaseService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentTaskId: UUID?
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 开始批量提取任务
    func startExtraction(assets: [PHAsset], targetSpec: TargetSpec) async throws {
        isProcessing = true
        progress = 0.0
        
        let assetIds = assets.map { $0.localIdentifier }
        let task = ProcessingTask(targetSpecId: targetSpec.specId, assetIds: assetIds)
        modelContext.insert(task)
        try modelContext.save()
        
        currentTaskId = task.id
        task.status = .processing
        task.startedAt = Date()
        
        let total = assets.count
        
        for (index, asset) in assets.enumerated() {
            do {
                try await extractSubject(from: asset, targetSpec: targetSpec)
                task.successCount += 1
            } catch {
                task.failureCount += 1
                task.addFailedAssetId(asset.localIdentifier)
                print("Failed to extract subject from asset \(asset.localIdentifier): \(error)")
            }
            
            task.processedCount = index + 1
            progress = Double(index + 1) / Double(total)
            try modelContext.save()
        }
        
        task.status = .completed
        task.completedAt = Date()
        try modelContext.save()
        
        isProcessing = false
        currentTaskId = nil
    }
    
    /// 从单个资产提取主体
    private func extractSubject(from asset: PHAsset, targetSpec: TargetSpec) async throws {
        // 确保 targetSpec 在当前 context 中
        let specId = targetSpec.specId
        let descriptor = FetchDescriptor<TargetSpec>(
            predicate: #Predicate { $0.specId == specId }
        )
        guard let contextTargetSpec = try modelContext.fetch(descriptor).first else {
            print("[EXTRACT] 错误: 无法找到 targetSpec: \(specId)")
            throw NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "TargetSpec not found"])
        }
        
        // 获取高质量图片
        let image = try await loadImage(from: asset)
        
        // 使用 Vision 提取主体
        let subjects = try await extractSubjectsUsingVision(from: image)
        
        // 保存每个主体
        for (subjectImage, confidence, boundingBox) in subjects {
            let subjectId = UUID()
            
            // 保存贴纸文件
            let stickerPath = try FileManager.saveSubjectSticker(
                subjectImage,
                specId: targetSpec.specId,
                subjectId: subjectId
            )
            
            // 生成缩略图
            let thumbnail = subjectImage.resized(to: CGSize(width: 200, height: 200))
            let thumbnailPath = try FileManager.saveThumbnail(
                thumbnail,
                specId: targetSpec.specId,
                subjectId: subjectId
            )
            
            // 创建 Subject 记录
            let subject = Subject(
                sourceAssetId: asset.localIdentifier,
                stickerPath: stickerPath,
                confidence: confidence,
                targetSpec: contextTargetSpec
            )
            subject.thumbnailPath = thumbnailPath
            subject.boundingBox = encodeBoundingBox(boundingBox)
            
            print("[EXTRACT] 创建 Subject, targetSpec: \(contextTargetSpec.specId), entity: \(subject.entity == nil ? "nil" : "has")")
            
            // 提取特征向量用于后续聚类
            if let featureVector = try? await extractFeatureVector(from: subjectImage) {
                subject.featureVector = encodeFeatureVector(featureVector)
                print("[EXTRACT] 提取特征向量成功, 维度: \(featureVector.count)")
            } else {
                print("[EXTRACT] 警告: 提取特征向量失败")
            }
            
            modelContext.insert(subject)
        }
        
        try modelContext.save()
    }
    
    /// 使用 Vision 提取主体
    private func extractSubjectsUsingVision(from image: UIImage) async throws -> [(UIImage, Double, CGRect)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNInstanceMaskObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var subjects: [(UIImage, Double, CGRect)] = []
                
                for observation in results {
                    do {
                        let maskedPixelBuffer = try observation.generateMaskedImage(
                            ofInstances: observation.allInstances,
                            from: handler,
                            croppedToInstancesExtent: true
                        )
                        
                        let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            subjects.append((
                                uiImage,
                                Double(observation.confidence),
                                ciImage.extent
                            ))
                        }
                    } catch {
                        print("Failed to generate masked image: \(error)")
                    }
                }
                
                continuation.resume(returning: subjects)
            }
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 提取特征向量
    private func extractFeatureVector(from image: UIImage) async throws -> [Float] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(throwing: NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "No feature print"]))
                    return
                }
                
                let featureData = observation.data
                let floatArray = featureData.withUnsafeBytes { pointer in
                    Array(pointer.bindMemory(to: Float.self))
                }
                
                continuation.resume(returning: floatArray)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 从 PHAsset 加载图片
    private func loadImage(from asset: PHAsset) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let image = image else {
                    continuation.resume(throwing: NSError(domain: "ObjectCamp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    /// 编码边界框
    private func encodeBoundingBox(_ rect: CGRect) -> String {
        let dict: [String: Double] = [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "width": Double(rect.width),
            "height": Double(rect.height)
        ]
        guard let data = try? JSONEncoder().encode(dict),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
    
    /// 编码特征向量
    private func encodeFeatureVector(_ vector: [Float]) -> String {
        guard let data = try? JSONEncoder().encode(vector),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - UIImage 扩展
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
