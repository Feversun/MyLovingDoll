//
//  KeychainService.swift
//  MyLovingDoll
//
//  安全的 Keychain 存储服务
//

import Foundation
import Security

final class KeychainService {
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }
    
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - 保存
    func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 删除旧的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - 读取
    func load(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    // MARK: - 删除
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - 检查是否存在
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - 便捷访问
extension KeychainService {
    
    private static let geminiAPIKeyName = "com.mylovingdoll.gemini.apikey"
    
    /// 保存 Gemini API Key
    func saveGeminiAPIKey(_ apiKey: String) throws {
        try save(key: Self.geminiAPIKeyName, value: apiKey)
    }
    
    /// 读取 Gemini API Key
    func loadGeminiAPIKey() throws -> String {
        try load(key: Self.geminiAPIKeyName)
    }
    
    /// 删除 Gemini API Key
    func deleteGeminiAPIKey() throws {
        try delete(key: Self.geminiAPIKeyName)
    }
    
    /// 检查是否有 API Key
    var hasGeminiAPIKey: Bool {
        exists(key: Self.geminiAPIKeyName)
    }
}
