//
//  APIKeySettingsView.swift
//  MyLovingDoll
//
//  API Key 设置视图
//

import SwiftUI

struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasExistingKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if hasExistingKey {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key 已配置")
                                .foregroundColor(.green)
                        }
                        
                        Button("删除 API Key", role: .destructive) {
                            deleteAPIKey()
                        }
                    }
                    
                    SecureField("输入 API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                    
                    Button("保存") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                    
                } header: {
                    Text("Gemini API 设置")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("获取 API Key:")
                        Link("🔗 https://aistudio.google.com/app/apikey",
                             destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                            .font(.caption)
                        
                        Text("\n💡 API Key 安全存储在系统 Keychain 中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("功能说明")
                            .font(.headline)
                        
                        Label("文本生成图片", systemImage: "wand.and.stars")
                        Label("单图编辑", systemImage: "photo.badge.arrow.down")
                        Label("多图合成 (最多3张)", systemImage: "rectangle.3.group")
                    }
                } header: {
                    Text("Nano Banana 功能")
                }
            }
            .navigationTitle("AI 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("好的") {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                checkExistingKey()
            }
        }
    }
    
    private func checkExistingKey() {
        hasExistingKey = KeychainService.shared.hasGeminiAPIKey
    }
    
    private func saveAPIKey() {
        do {
            try KeychainService.shared.saveGeminiAPIKey(apiKey)
            alertMessage = "API Key 保存成功! ✅"
            showingAlert = true
            hasExistingKey = true
            apiKey = "" // 清空输入框
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteAPIKey() {
        do {
            try KeychainService.shared.deleteGeminiAPIKey()
            alertMessage = "API Key 已删除"
            showingAlert = true
            hasExistingKey = false
        } catch {
            alertMessage = "删除失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
