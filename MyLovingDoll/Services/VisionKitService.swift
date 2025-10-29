//
//  VisionKitService.swift
//  MyLovingDoll
//
//  VisionKit 交互式主体提取服务
//

import Foundation
import UIKit
import VisionKit
import SwiftData
import Combine

@available(iOS 17.0, *)
@MainActor
class VisionKitService: ObservableObject {
    private let modelContext: ModelContext
    private let analyzer = ImageAnalyzer()
    
    @Published var isAnalyzing = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 分析图像并提取主体
    func analyzeImage(_ image: UIImage) async throws -> ImageAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let configuration = ImageAnalyzer.Configuration([.visualLookUp])
        let analysis = try await analyzer.analyze(image, configuration: configuration)
        
        return analysis
    }
    
    /// 从分析结果中提取主体图像
    func extractSubjects(from analysis: ImageAnalysis) -> [UIImage] {
        // 注意: subjects API 在 iOS 17+ 可用
        // 这里我们通过 ImageAnalysisInteraction 在 UI 层处理
        // VisionKit 的主体提取主要通过交互完成
        
        return []
    }
    
    /// 检查图像是否包含可识别主体
    func hasRecognizableSubjects(_ analysis: ImageAnalysis) -> Bool {
        return analysis.hasResults(for: .visualLookUp)
    }
    
    /// 更新 Subject 数据 - 用户交互式提取后调用
    func updateSubject(_ subject: Subject, 
                       with newImage: UIImage,
                       specId: String) async throws {
        
        // 1. 删除旧贴纸文件
        let oldStickerPath = subject.stickerPath
        let oldFileURL = FileManager.specDirectory(for: specId).appendingPathComponent(oldStickerPath)
        try? FileManager.default.removeItem(at: oldFileURL)
        
        // 2. 保存新贴纸
        let newStickerPath = try FileManager.saveSubjectSticker(
            newImage,
            specId: specId,
            subjectId: subject.id
        )
        
        // 3. 生成新缩略图
        let thumbnail = newImage.resized(to: CGSize(width: 200, height: 200))
        let newThumbnailPath = try FileManager.saveThumbnail(
            thumbnail,
            specId: specId,
            subjectId: subject.id
        )
        
        // 4. 提取新特征向量
        let featureVector = try await extractFeatureVector(from: newImage)
        
        // 5. 更新 Subject 记录
        subject.stickerPath = newStickerPath
        subject.thumbnailPath = newThumbnailPath
        subject.featureVector = encodeFeatureVector(featureVector)
        subject.extractionMethod = "manual"
        subject.lastAdjustedAt = Date()
        subject.needsReview = false
        
        try modelContext.save()
    }
    
    /// 提取特征向量 (复用自 ObjectCaseService)
    private func extractFeatureVector(from image: UIImage) async throws -> [Float] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(throwing: NSError(domain: "VisionKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No feature print"]))
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
    
    /// 编码特征向量
    private func encodeFeatureVector(_ vector: [Float]) -> String {
        guard let data = try? JSONEncoder().encode(vector),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - 需要导入 Vision
import Vision
