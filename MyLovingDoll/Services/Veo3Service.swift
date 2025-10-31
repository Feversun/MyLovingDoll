//
//  Veo3Service.swift
//  MyLovingDoll
//
//  VEO 3.1 视频生成 API 封装
//  支持文本生成视频、图片转视频、视频扩展、多参考图片、帧插值
//  https://ai.google.dev/gemini-api/docs/video
//

import Foundation
import UIKit

final class Veo3Service {
    
    private let apiKey: String
    private let modelID = "veo-3.1-generate-preview"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// 便捷初始化 - 从 Keychain 读取 API Key
    static func fromKeychain() throws -> Veo3Service {
        let apiKey = try KeychainService.shared.loadGeminiAPIKey()
        return Veo3Service(apiKey: apiKey)
    }
    
    // MARK: - 配置选项
    
    struct VideoConfig {
        var aspectRatio: String? = "16:9" // "16:9", "9:16", "1:1"
        var resolution: String? = "720p"  // "720p", "1080p"
        var negativePrompt: String?
        
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            if let aspectRatio = aspectRatio { dict["aspectRatio"] = aspectRatio }
            if let resolution = resolution { dict["resolution"] = resolution }
            if let negativePrompt = negativePrompt { dict["negativePrompt"] = negativePrompt }
            return dict
        }
    }
    
    // MARK: - 1️⃣ Text → Video
    
    /// 文本生成视频
    func generateVideo(prompt: String, config: VideoConfig? = nil) async throws -> URL {
        print("[Veo3] 📝 文本生成视频")
        print("[Veo3] Prompt: \(prompt)")
        
        let url = URL(string: "\(endpoint)/\(modelID):predictLongRunning?key=\(apiKey)")!
        
        var payload: [String: Any] = [
            "instances": [
                ["prompt": prompt]
            ]
        ]
        
        if let config = config {
            payload["parameters"] = config.toDictionary()
        }
        
        return try await executeVideoGeneration(url: url, payload: payload)
    }
    
    // MARK: - 2️⃣ Image → Video
    
    /// 图片转视频（单图作为第一帧）
    func generateVideo(prompt: String, firstImage: UIImage, config: VideoConfig? = nil) async throws -> URL {
        print("[Veo3] 🖼️ 图片转视频")
        print("[Veo3] Prompt: \(prompt)")
        print("[Veo3] 图片尺寸: \(firstImage.size)")
        
        let base64Image = firstImage.pngData()!.base64EncodedString()
        print("[Veo3] Base64 编码长度: \(base64Image.count) 字符")
        
        let url = URL(string: "\(endpoint)/\(modelID):predictLongRunning?key=\(apiKey)")!
        
        let instance: [String: Any] = [
            "prompt": prompt,
            "image": [
                "bytesBase64Encoded": base64Image,
                "mimeType": "image/png"
            ]
        ]
        
        var payload: [String: Any] = [
            "instances": [instance]
        ]
        
        if let config = config {
            payload["parameters"] = config.toDictionary()
        }
        
        return try await executeVideoGeneration(url: url, payload: payload)
    }
    
    // MARK: - 3️⃣ 帧插值（指定首尾帧）
    
    /// 帧插值：指定第一帧和最后一帧生成视频
    func generateVideo(prompt: String, firstImage: UIImage, lastImage: UIImage, config: VideoConfig? = nil) async throws -> URL {
        print("[Veo3] 🎬 帧插值生成")
        print("[Veo3] Prompt: \(prompt)")
        
        let base64First = firstImage.pngData()!.base64EncodedString()
        let base64Last = lastImage.pngData()!.base64EncodedString()
        
        let url = URL(string: "\(endpoint)/\(modelID):predictLongRunning?key=\(apiKey)")!
        
        let instance: [String: Any] = [
            "prompt": prompt,
            "image": [
                "bytesBase64Encoded": base64First,
                "mimeType": "image/png"
            ],
            "lastFrame": [
                "bytesBase64Encoded": base64Last,
                "mimeType": "image/png"
            ]
        ]
        
        var payload: [String: Any] = [
            "instances": [instance]
        ]
        
        if let config = config {
            payload["parameters"] = config.toDictionary()
        }
        
        return try await executeVideoGeneration(url: url, payload: payload)
    }
    
    // MARK: - 4️⃣ 多参考图片（最多3张）
    
    enum ReferenceType: String {
        case asset = "asset"      // 保留物体/角色外观
        case style = "style"      // 风格参考
    }
    
    struct ReferenceImage {
        let image: UIImage
        let type: ReferenceType
    }
    
    /// 使用多张参考图片生成视频
    func generateVideo(prompt: String, references: [ReferenceImage], config: VideoConfig? = nil) async throws -> URL {
        print("[Veo3] 🎨 多参考图片生成")
        print("[Veo3] Prompt: \(prompt)")
        print("[Veo3] 参考图片数量: \(references.count)")
        
        guard !references.isEmpty && references.count <= 3 else {
            throw NSError(domain: "Veo3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "参考图片数量必须在 1-3 之间"])
        }
        
        let url = URL(string: "\(endpoint)/\(modelID):predictLongRunning?key=\(apiKey)")!
        
        let referenceArray: [[String: Any]] = references.map { ref in
            [
                "image": [
                    "bytesBase64Encoded": ref.image.pngData()!.base64EncodedString(),
                    "mimeType": "image/png"
                ],
                "referenceType": ref.type.rawValue
            ]
        }
        
        let instance: [String: Any] = [
            "prompt": prompt,
            "referenceImages": referenceArray
        ]
        
        var payload: [String: Any] = [
            "instances": [instance]
        ]
        
        if let config = config {
            payload["parameters"] = config.toDictionary()
        }
        
        return try await executeVideoGeneration(url: url, payload: payload)
    }
    
    // MARK: - 5️⃣ 视频扩展
    
    /// 扩展已生成的视频（续接）
    /// - Parameters:
    ///   - prompt: 新的提示词
    ///   - previousVideoURL: 之前生成的视频 URL（需要先上传到 Gemini Files API）
    ///   - config: 配置选项
    func extendVideo(prompt: String, previousVideoURL: String, config: VideoConfig? = nil) async throws -> URL {
        print("[Veo3] 🔄 视频扩展")
        print("[Veo3] Prompt: \(prompt)")
        print("[Veo3] 前置视频: \(previousVideoURL)")
        
        let url = URL(string: "\(endpoint)/\(modelID):predictLongRunning?key=\(apiKey)")!
        
        let instance: [String: Any] = [
            "prompt": prompt,
            "video": [
                "fileUri": previousVideoURL
            ]
        ]
        
        var payload: [String: Any] = [
            "instances": [instance]
        ]
        
        if let config = config {
            payload["parameters"] = config.toDictionary()
        }
        
        return try await executeVideoGeneration(url: url, payload: payload)
    }
    
    // MARK: - 执行引擎
    
    private func executeVideoGeneration(url: URL, payload: [String: Any]) async throws -> URL {
        print("[Veo3] 🌐 发送请求...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[Veo3] 📊 HTTP 状态码: \(httpResponse.statusCode)")
        }
        
        print("[Veo3] 📦 接收数据大小: \(data.count) bytes")
        
        // 打印原始响应（用于调试）
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[Veo3] 📄 原始响应: \(jsonString.prefix(1000))")
        }
        
        // 解析 operation name
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[Veo3] ❌ 无法解析 JSON 响应")
            throw NSError(domain: "Veo3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析响应数据"])
        }
        
        // 检查错误
        if let error = json["error"] as? [String: Any] {
            let errorMessage = error["message"] as? String ?? "未知错误"
            let errorCode = error["code"] as? Int ?? -1
            print("[Veo3] ❌ API 错误 [\(errorCode)]: \(errorMessage)")
            throw NSError(domain: "Veo3Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let operationName = json["name"] as? String else {
            print("[Veo3] ❌ 响应中没有 operation name")
            throw NSError(domain: "Veo3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取 operation name"])
        }
        
        print("[Veo3] ⏳ Operation: \(operationName)")
        
        // 轮询等待完成
        return try await pollOperation(operationName: operationName)
    }
    
    private func pollOperation(operationName: String) async throws -> URL {
        let statusURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(operationName)?key=\(apiKey)")!
        
        while true {
            print("[Veo3] 🔄 检查视频生成状态...")
            
            let (data, _) = try await URLSession.shared.data(from: statusURL)
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "Veo3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析状态响应"])
            }
            
            let isDone = json["done"] as? Bool ?? false
            
            if isDone {
                print("[Veo3] ✅ 视频生成完成")
                
                // 提取视频 URI
                guard let response = json["response"] as? [String: Any],
                      let generateVideoResponse = response["generateVideoResponse"] as? [String: Any],
                      let generatedSamples = generateVideoResponse["generatedSamples"] as? [[String: Any]],
                      let firstSample = generatedSamples.first,
                      let video = firstSample["video"] as? [String: Any],
                      let videoURIString = video["uri"] as? String,
                      let videoURI = URL(string: videoURIString) else {
                    throw NSError(domain: "Veo3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应中没有视频 URI"])
                }
                
                print("[Veo3] 🎥 视频 URI: \(videoURI.absoluteString)")
                
                // 下载视频到本地
                return try await downloadVideo(from: videoURI)
            }
            
            // 等待 10 秒后重试
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
    }
    
    private func downloadVideo(from uri: URL) async throws -> URL {
        print("[Veo3] ⬇️ 开始下载视频...")
        
        var request = URLRequest(url: uri)
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        print("[Veo3] 📦 视频大小: \(data.count) bytes")
        
        // 保存到临时目录
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "veo3_\(UUID().uuidString).mp4"
        let localURL = tempDir.appendingPathComponent(fileName)
        
        try data.write(to: localURL)
        
        print("[Veo3] ✅ 视频已保存到: \(localURL.path)")
        
        return localURL
    }
}
