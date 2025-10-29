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
        let url = URL(string: "\(endpoint)/\(modelID):generateContent?key=\(apiKey)")!
        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        let request = try makeRequest(url: url, payload: payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseImage(from: data)
    }
    
    // MARK: - 2️⃣ Image → Image (单图编辑)
    func editImage(prompt: String, baseImage: UIImage) async throws -> UIImage {
        let base64Image = baseImage.pngData()!.base64EncodedString()
        let url = URL(string: "\(endpoint)/\(modelID):generateContent?key=\(apiKey)")!
        
        let payload: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt],
                    ["inline_data": [
                        "mime_type": "image/png",
                        "data": base64Image
                    ]]
                ]]
            ]
        ]
        let request = try makeRequest(url: url, payload: payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseImage(from: data)
    }
    
    // MARK: - 3️⃣ Multi-Image → Image (多图合成)
    /// 最多支持 3 张输入图片。
    func composeImage(prompt: String, baseImages: [UIImage]) async throws -> UIImage {
        guard !baseImages.isEmpty else {
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "必须提供至少一张图片"])
        }
        if baseImages.count > 3 {
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "最多只能上传 3 张图片"])
        }
        
        let base64Images = baseImages.map { image in
            image.pngData()!.base64EncodedString()
        }
        
        // parts: 文本提示 + 多张图片
        var parts: [[String: Any]] = [["text": prompt]]
        for base64 in base64Images {
            parts.append([
                "inline_data": [
                    "mime_type": "image/png",
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
        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseImage(from: data)
    }
    
    // MARK: - Helpers
    private func makeRequest(url: URL, payload: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }
    
    private func parseImage(from data: Data) throws -> UIImage {
        struct Response: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        struct InlineData: Decodable {
                            let data: String
                        }
                        let inline_data: InlineData?
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard
            let base64Data = decoded.candidates.first?.content.parts.first?.inline_data?.data,
            let imageData = Data(base64Encoded: base64Data),
            let image = UIImage(data: imageData)
        else {
            throw NSError(domain: "NanoBananaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "未能解析返回图片"])
        }
        return image
    }
}
