//
//  AIImageGenerationService.swift
//  MyLovingDoll
//
//  AI 图片生成服务
//

import Foundation
import UIKit

/// AI 图片生成请求
public struct AIImageGenerationRequest {
    let sourceImage: UIImage?
    let prompt: String
    let negativePrompt: String?
    let style: GenerationStyle?
    
    public enum GenerationStyle: String {
        case realistic
        case anime
        case cartoon
        case artistic
    }
    
    public init(
        sourceImage: UIImage? = nil,
        prompt: String,
        negativePrompt: String? = nil,
        style: GenerationStyle? = nil
    ) {
        self.sourceImage = sourceImage
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.style = style
    }
}

/// AI 图片生成响应
public struct AIImageGenerationResponse {
    let generatedImage: UIImage
    let prompt: String
    let seed: Int?
    let metadata: [String: Any]?
}

/// AI 图片生成服务协议
public protocol AIImageGenerationProvider {
    /// 生成图片
    func generateImage(request: AIImageGenerationRequest) async throws -> AIImageGenerationResponse
    
    /// 检查是否可用
    func isAvailable() async -> Bool
}

/// AI 服务错误
public enum AIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case serviceUnavailable
    case invalidImage
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "无效的 API Key"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .rateLimitExceeded:
            return "请求频率超限,请稍后再试"
        case .serviceUnavailable:
            return "服务不可用"
        case .invalidImage:
            return "无效的图片"
        }
    }
}

/// Gemini AI 图片生成服务
@MainActor
public class GeminiImageService: AIImageGenerationProvider {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func generateImage(request: AIImageGenerationRequest) async throws -> AIImageGenerationResponse {
        // 检查 API Key
        guard !apiKey.isEmpty else {
            throw AIServiceError.invalidAPIKey
        }
        
        // 构建请求
        var urlComponents = URLComponents(string: "\(baseURL)/models/gemini-pro-vision:generateContent")!
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw AIServiceError.invalidResponse
        }
        
        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        var parts: [[String: Any]] = [
            ["text": request.prompt]
        ]
        
        // 如果有源图片,添加到请求中
        if let sourceImage = request.sourceImage,
           let imageData = sourceImage.jpegData(compressionQuality: 0.8) {
            let base64Image = imageData.base64EncodedString()
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64Image
                ]
            ])
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": parts]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 4096
            ]
        ]
        
        httpRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        // 处理响应
        switch httpResponse.statusCode {
        case 200:
            // 解析响应 (这里需要根据实际 API 响应格式调整)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let imagePart = parts.first(where: { $0["inline_data"] != nil }),
                  let inlineData = imagePart["inline_data"] as? [String: Any],
                  let base64String = inlineData["data"] as? String,
                  let imageData = Data(base64Encoded: base64String),
                  let generatedImage = UIImage(data: imageData) else {
                throw AIServiceError.invalidResponse
            }
            
            return AIImageGenerationResponse(
                generatedImage: generatedImage,
                prompt: request.prompt,
                seed: nil,
                metadata: json
            )
            
        case 429:
            throw AIServiceError.rateLimitExceeded
        case 401, 403:
            throw AIServiceError.invalidAPIKey
        default:
            throw AIServiceError.serviceUnavailable
        }
    }
    
    public func isAvailable() async -> Bool {
        return !apiKey.isEmpty
    }
}
