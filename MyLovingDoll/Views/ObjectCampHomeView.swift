//
//  ObjectCampHomeView.swift
//  MyLovingDoll
//
//  ObjectCamp 主界面
//

import SwiftUI
import SwiftData
import Photos

struct ObjectCampHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entities: [Entity]
    
    @StateObject private var extractionService: ObjectCaseService
    @StateObject private var clusterService: EntityClusterService
    
    @State private var showingPhotoPicker = false
    @State private var selectedAssets: [PHAsset] = []
    @State private var currentTargetSpec: TargetSpec?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var showCompletionMessage = false
    @State private var processedCount = 0
    
    init(modelContext: ModelContext) {
        let extractService = ObjectCaseService(modelContext: modelContext)
        let clusterSvc = EntityClusterService(modelContext: modelContext)
        _extractionService = StateObject(wrappedValue: extractService)
        _clusterService = StateObject(wrappedValue: clusterSvc)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 欢迎文案
                VStack(spacing: 12) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink.gradient)
                    
                    Text("ObjectCamp")
                        .font(.largeTitle.bold())
                    
                    Text("智能整理你的照片主体")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // 进度显示
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView(value: extractionService.progress) {
                            Text("处理中...")
                        }
                        .progressViewStyle(.linear)
                        
                        Text("\(Int(extractionService.progress * 100))%")
                            .font(.headline)
                            .foregroundColor(.pink)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // 实体预览
                if !entities.isEmpty {
                    NavigationLink {
                        EntityLibraryView()
                    } label: {
                        HStack {
                            Text("已整理 \(entities.count) 个对象")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 完成提示
                if showCompletionMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("整理完成! 识别出 \(processedCount) 个对象")
                            .font(.headline)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 操作按钮
                VStack(spacing: 16) {
                    Button {
                        checkPhotoLibraryPermission()
                    } label: {
                        Label("选择照片", systemImage: "photo.on.rectangle.angled")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.pink.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    Button {
                        Task {
                            await startProcessing()
                        }
                    } label: {
                        Label("开始整理", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedAssets.isEmpty ? AnyShapeStyle(.gray) : AnyShapeStyle(.blue.gradient))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedAssets.isEmpty || isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("ObjectCamp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedAssets: $selectedAssets)
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await initializeTargetSpec()
            }
        }
    }
    
    // MARK: - Methods
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            showingPhotoPicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showingPhotoPicker = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "请在系统设置中允许访问相册"
            showingError = true
        @unknown default:
            break
        }
    }
    
    private func initializeTargetSpec() async {
        // 创建默认的 doll 目标规格
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
            // 1. 提取主体
            print("[DEBUG] [Step 1] 开始提取主体...")
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
            
            // 检查 Subject 数量
            let subjectDescriptor = FetchDescriptor<Subject>(
                predicate: #Predicate<Subject> { subject in
                    subject.targetSpec?.specId == specId
                }
            )
            let subjects = try modelContext.fetch(subjectDescriptor)
            print("[DEBUG] [Step 4] 提取的主体数: \(subjects.count)")
            
            // 完成
            await MainActor.run {
                selectedAssets = []
                isProcessing = false
                processedCount = createdEntities.count
                
                print("[DEBUG] [处理完成] 实体数: \(processedCount)")
                
                // 显示完成提示
                if processedCount > 0 {
                    print("[DEBUG] [显示提示] 识别出 \(processedCount) 个对象")
                    showCompletionMessage = true
                    // 2秒后自动隐藏
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        showCompletionMessage = false
                    }
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

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearAlert = false
    
    var body: some View {
        List {
            Section("数据管理") {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("清空所有数据", systemImage: "trash")
                }
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .alert("确认清空", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("此操作将删除所有整理数据,无法恢复")
        }
    }
    
    private func clearAllData() {
        try? FileManager.clearAllObjectCampData()
        try? modelContext.delete(model: Entity.self)
        try? modelContext.delete(model: Subject.self)
        try? modelContext.delete(model: ProcessingTask.self)
        try? modelContext.save()
    }
}
