//
//  ProcessingSheetView.swift
//  MyLovingDoll
//
//  照片整理处理界面
//

import SwiftUI
import SwiftData
import Photos

struct ProcessingSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedAssets: [PHAsset]
    @Binding var isPresented: Bool
    
    @State private var currentTargetSpec: TargetSpec?
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var processedCount = 0
    @State private var isDone = false
    @State private var progress: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !isDone {
                    // 处理中状态
                    VStack(spacing: 16) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.pink.gradient)
                        
                        Text("正在整理照片")
                            .font(.title2.bold())
                        
                        Text("已选择 \(selectedAssets.count) 张照片")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // 进度显示
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressView(value: progress) {
                                Text("处理中...")
                            }
                            .progressViewStyle(.linear)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.headline)
                                .foregroundColor(.pink)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // 开始整理按钮
                    if !isProcessing {
                        Button {
                            Task {
                                await startProcessing()
                            }
                        } label: {
                            Label("开始整理", systemImage: "sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.pink.gradient)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                } else {
                    // 完成状态
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("整理完成!")
                            .font(.title.bold())
                        
                        Text("识别出 \(processedCount) 个对象")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("完成")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue.gradient)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 60)
                }
            }
            .navigationTitle("整理照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isProcessing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
            .task {
                await initializeTargetSpec()
            }
        }
    }
    
    // MARK: - Methods
    
    private func initializeTargetSpec() async {
        let descriptor = FetchDescriptor<TargetSpec>(
            predicate: #Predicate { $0.specId == "doll" }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            currentTargetSpec = existing
        } else {
            let spec = TargetSpec(
                specId: "doll",
                displayName: "娃娃",
                targetDescription: "toy doll, plush toy, stuffed animal"
            )
            modelContext.insert(spec)
            try? modelContext.save()
            currentTargetSpec = spec
        }
    }
    
    private func startProcessing() async {
        guard let targetSpec = currentTargetSpec, !selectedAssets.isEmpty else { return }
        
        isProcessing = true
        print("[DEBUG] [开始处理] 照片数量: \(selectedAssets.count)")
        
        do {
            // 创建服务实例
            let extractionService = ObjectCaseService(modelContext: modelContext)
            let clusterService = EntityClusterService(modelContext: modelContext)
            
            // 1. 提取主体
            print("[DEBUG] [Step 1] 开始提取主体...")
            
            // 监控进度
            Task { @MainActor in
                while isProcessing {
                    progress = extractionService.progress
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                }
            }
            
            try await extractionService.startExtraction(assets: selectedAssets, targetSpec: targetSpec)
            print("[DEBUG] [Step 1] 提取完成")
            
            // 2. 聚类
            print("[DEBUG] [Step 2] 开始聚类...")
            try await clusterService.clusterSubjects(for: targetSpec.specId)
            print("[DEBUG] [Step 2] 聚类完成")
            
            // 3. 确保保存
            try modelContext.save()
            print("[DEBUG] [Step 3] 数据保存完成")
            
            // 4. 等待一下让 SwiftData 更新
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 5. 获取处理结果
            let specId = targetSpec.specId
            let entityDescriptor = FetchDescriptor<Entity>(
                predicate: #Predicate<Entity> { entity in
                    entity.targetSpec?.specId == specId
                }
            )
            let createdEntities = try modelContext.fetch(entityDescriptor)
            print("[DEBUG] [Step 4] 查询结果: 发现 \(createdEntities.count) 个实体")
            
            // 完成
            await MainActor.run {
                isProcessing = false
                processedCount = createdEntities.count
                
                print("[DEBUG] [处理完成] 实体数: \(processedCount)")
                
                if processedCount > 0 {
                    isDone = true
                    selectedAssets = []
                } else {
                    print("[WARNING] 没有创建任何实体!")
                    errorMessage = "未识别到主体,请尝试使用背景简单的照片"
                    showingError = true
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "处理失败: \(error.localizedDescription)"
                showingError = true
                isProcessing = false
            }
        }
    }
}
