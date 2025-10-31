//
//  NanoBananaService.swift
//  MyLovingDoll
//
//  Nano Banana API 封装（Gemini 2.5 Flash Image Preview）
//  支持文本生成、多图合成、单图编辑。
//  https://aistudio.google.com/models/gemini-2-5-flash-image
//

import Foundation
import UIKit

final class NanoBananaService {
    
    private let apiKey: String
    private let modelID = "gemini-2.5-flash-image-preview"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// 便捷初始化 - 从 Keychain 读取 API Key
    static func fromKeychain() throws -> NanoBananaService {
        let apiKey = try KeychainService.shared.loadGeminiAPIKey()
        return NanoBananaService(apiKey: apiKey)
    }
    
    // MARK: - 1️⃣ Text → Image
    func generateImage(prompt: String) async throws -> UIImage {
        print("[NanoBanana] 📝 文本生成图片")
        print("[NanoBanana] Prompt: \(prompt)")
        
        let url = URL(string: "\(endpoint)/\(modelID):generateContent?key=\(apiKey)")!
        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        let request = try makeRequest(url: url, payload: payload)
        
        print("[NanoBanana] 🌐 发送请求到: \(url.absoluteString.prefix(50))...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[NanoBanana] 📊 HTTP 状态码: \(httpResponse.statusCode)")
        }
        print("[NanoBanana] 📦 接收数据大小: \(data.count) bytes")
        
        return try parseImage(from: data)
    }
    
    // MARK: - 2️⃣ Image → Image (单图编辑)
    func editImage(prompt: String, baseImage: UIImage) async throws -> UIImage {
        print("[NanoBanana] 🎨 单图编辑")
        print("[NanoBanana] Prompt: \(prompt)")
        print("[NanoBanana] 图片原始尺寸: \(baseImage.size)")
        
        // 压缩图片
        let compressedImage = compressImage(baseImage)
        let base64Image = compressedImage.jpegData(compressionQuality: 0.8)!.base64EncodedString()
        print("[NanoBanana] Base64 编码长度: \(base64Image.count) 字符 (\(base64Image.count / 1024)KB)")
        
        // 明确要求生成图片
        let enhancedPrompt = "Generate an image based on this request (DO NOT just describe it in text): \(prompt)"
        
        let url = URL(string: "\(endpoint)/\(modelID):generateContent?key=\(apiKey)")!
        let payload: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": enhancedPrompt],
                    ["inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]]
                ]]
            ]
        ]
        let request = try makeRequest(url: url, payload: payload)
        
        print("[NanoBanana] 🌐 发送请求...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[NanoBanana] 📊 HTTP 状态码: \(httpResponse.statusCode)")
        }
        print("[NanoBanana] 📦 接收数据大小: \(data.count) bytes")
        
        return try parseImage(from: data)
    }
    
    // MARK: - 3️⃣ Multi-Image → Image (多图合成)
    /// 最多支持 3 张输入图片。
    func composeImage(prompt: String, baseImages: [UIImage]) async throws -> UIImage {
        print("[NanoBanana] 🖼️ 多图合成")
        print("[NanoBanana] Prompt: \(prompt)")
        print("[NanoBanana] 图片数量: \(baseImages.count)")
        
        guard !baseImages.isEmpty else {
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "必须提供至少一张图片"])
        }
        if baseImages.count > 3 {
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "最多只能上传 3 张图片"])
        }
        
        // 压缩所有图片
        let compressedImages = baseImages.map { compressImage($0) }
        let base64Images = compressedImages.map { image in
            image.jpegData(compressionQuality: 0.8)!.base64EncodedString()
        }
        
        for (index, img) in baseImages.enumerated() {
            print("[NanoBanana] 图片 \(index + 1) 原始尺寸: \(img.size)")
        }
        for (index, img) in compressedImages.enumerated() {
            print("[NanoBanana] 图片 \(index + 1) 压缩后尺寸: \(img.size)")
        }
        
        // 明确要求生成图片而不是文本回复
        let enhancedPrompt = "Generate an image based on this request (DO NOT just describe it in text): \(prompt)"
        
        // parts: 文本提示 + 多张图片
        var parts: [[String: Any]] = [["text": enhancedPrompt]]
        for base64 in base64Images {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64
                ]
            ])
        }
        
        let payload: [String: Any] = [
            "contents": [
                ["parts": parts]
            ]
        ]
        
        let url = URL(string: "\(endpoint)/\(modelID):generateContent?key=\(apiKey)")!
        let request = try makeRequest(url: url, payload: payload)
        
        print("[NanoBanana] 🌐 发送请求...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[NanoBanana] 📊 HTTP 状态码: \(httpResponse.statusCode)")
        }
        print("[NanoBanana] 📦 接收数据大小: \(data.count) bytes")
        
        return try parseImage(from: data)
    }
    
    // MARK: - Helpers
    private func makeRequest(url: URL, payload: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 120 // 2分钟超时
        return request
    }
    
    /// 压缩图片到合适的大小（目标：小于 1MB base64）
    private func compressImage(_ image: UIImage, maxSizeMB: Double = 1.0) -> UIImage {
        let maxBytes = Int(maxSizeMB * 1024 * 1024)
        
        // 先尝试调整尺寸
        var targetImage = image
        let maxDimension: CGFloat = 1024 // 最大边长
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = resized
            }
            UIGraphicsEndImageContext()
            
            print("[NanoBanana] 📐 图片已调整尺寸: \(image.size) → \(targetImage.size)")
        }
        
        // 再调整压缩质量
        var compression: CGFloat = 0.8
        var imageData = targetImage.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = targetImage.jpegData(compressionQuality: compression)
        }
        
        if let data = imageData {
            print("[NanoBanana] 🗜️ 图片已压缩: 质量 \(Int(compression * 100))%, 大小 \(data.count / 1024)KB")
            return UIImage(data: data) ?? targetImage
        }
        
        return targetImage
    }
    
    private func parseImage(from data: Data) throws -> UIImage {
        print("[NanoBanana] 🔍 开始解析响应...")
        
        // 先打印原始 JSON 看看结构
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[NanoBanana] 📄 原始响应: \(jsonString.prefix(500))...")
        }
        
        // 先检查是否有内容过滤错误
        struct ErrorResponse: Decodable {
            struct Candidate: Decodable {
                let finishReason: String?
                let finishMessage: String?
            }
            let candidates: [Candidate]
        }
        
        if let errorCheck = try? JSONDecoder().decode(ErrorResponse.self, from: data),
           let firstCandidate = errorCheck.candidates.first,
           let finishReason = firstCandidate.finishReason,
           finishReason == "PROHIBITED_CONTENT" {
            let message = firstCandidate.finishMessage ?? "内容被 Google 安全过滤拦截"
            print("[NanoBanana] 🚫 内容被拦截: \(finishReason)")
            print("[NanoBanana] 📝 原因: \(message)")
            throw NSError(domain: "NanoBananaError", code: -403, userInfo: [
                NSLocalizedDescriptionKey: "内容被拦截：Google 认为图片或提示词违反了使用政策。请尝试更换图片或修改提示词。"
            ])
        }
        
        struct Response: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        struct InlineData: Decodable {
                            let data: String
                        }
                        let inlineData: InlineData?
                        let text: String?
                    }
                    let parts: [Part]
                }
                let content: Content?
            }
            let candidates: [Candidate]
        }
        
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            print("[NanoBanana] ✅ JSON 解析成功")
            print("[NanoBanana] Candidates 数量: \(decoded.candidates.count)")
            
            guard let firstCandidate = decoded.candidates.first else {
                print("[NanoBanana] ❌ 没有候选结果")
                throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有候选结果"])
            }
            
            guard let content = firstCandidate.content else {
                print("[NanoBanana] ❌ 响应中没有 content （可能被过滤）")
                throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应异常，请检查图片和提示词"])
            }
            
            print("[NanoBanana] Parts 数量: \(content.parts.count)")
            
            // 遍历 parts 找到包含图片的那个
            guard let imagePart = content.parts.first(where: { $0.inlineData != nil }),
                  let base64Data = imagePart.inlineData?.data else {
                print("[NanoBanana] ❌ 没有找到 inlineData")
                
                // 检查是否返回了纯文本
                if content.parts.first(where: { $0.text != nil }) != nil {
                    print("[NanoBanana] 📝 模型返回了文本而不是图片")
                    throw NSError(domain: "NanoBananaError", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "模型返回了文本说明而不是图片，请尝试更明确的提示词或更换图片"
                    ])
                }
                
                throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应中没有图片数据"])
            }
            
            print("[NanoBanana] Base64 数据长度: \(base64Data.count) 字符")
            
            guard let imageData = Data(base64Encoded: base64Data) else {
                print("[NanoBanana] ❌ Base64 解码失败")
                throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base64 解码失败"])
            }
            
            print("[NanoBanana] 图片数据大小: \(imageData.count) bytes")
            
            guard let image = UIImage(data: imageData) else {
                print("[NanoBanana] ❌ UIImage 创建失败")
                throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建 UIImage"])
            }
            
            print("[NanoBanana] ✅ 图片解析成功,尺寸: \(image.size)")
            return image
            
        } catch let decodingError as DecodingError {
            print("[NanoBanana] ❌ JSON 解析错误: \(decodingError)")
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON 解析失败: \(decodingError.localizedDescription)"])
        }
    }
}
