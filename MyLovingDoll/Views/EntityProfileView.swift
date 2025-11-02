//
//  EntityProfileView.swift
//  MyLovingDoll
//
//  对象详情编辑页
//

import SwiftUI
import SwiftData

struct EntityProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var entity: Entity
    
    @State private var showingCoverPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    // 名称
                    TextField("名称", text: Binding(
                        get: { entity.customName ?? "" },
                        set: { entity.customName = $0 }
                    ))
                    
                    // 封面
                    Button {
                        showingCoverPicker = true
                    } label: {
                        HStack {
                            Text("封面图")
                            Spacer()
                            if let coverSubjectId = entity.coverSubjectId,
                               let subject = entity.subjects?.first(where: { $0.id == coverSubjectId }),
                               let specId = entity.targetSpec?.specId,
                               let image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 关系/身份
                    TextField("关系（如：我的女儿、我的朋友）", text: Binding(
                        get: { entity.relationship ?? "" },
                        set: { entity.relationship = $0.isEmpty ? nil : $0 }
                    ))
                    
                    // 生日
                    DatePicker(
                        "生日",
                        selection: Binding(
                            get: { entity.birthday ?? Date() },
                            set: { entity.birthday = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
                
                // 性格特征
                Section("性格特征") {
                    TextField("性格（如：活泼、温柔、勇敢）", text: Binding(
                        get: { entity.personality ?? "" },
                        set: { entity.personality = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("爱好（如：画画、唱歌、探险）", text: Binding(
                        get: { entity.hobbies ?? "" },
                        set: { entity.hobbies = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
                
                // 外貌与能力
                Section("外貌与能力") {
                    TextField("外貌描述", text: Binding(
                        get: { entity.appearance ?? "" },
                        set: { entity.appearance = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...5)
                    
                    TextField("特殊能力（如：会魔法、超级力量）", text: Binding(
                        get: { entity.specialAbilities ?? "" },
                        set: { entity.specialAbilities = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
                
                // 故事背景
                Section("故事背景") {
                    TextField("背景故事", text: Binding(
                        get: { entity.backgroundStory ?? "" },
                        set: { entity.backgroundStory = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...8)
                }
                
                // 预览 Prompt
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("生成的角色描述")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(PromptManager.shared.generateCharacterDescription(for: entity))
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } header: {
                    Text("AI Prompt 预览")
                } footer: {
                    Text("这些信息将用于生成个性化的故事内容")
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        entity.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCoverPicker) {
                CoverPickerSheet(entity: entity)
            }
        }
    }
}

// MARK: - 封面选择器
struct CoverPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var entity: Entity
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(entity.subjects ?? []) { subject in
                        CoverImageItem(
                            subject: subject,
                            specId: entity.targetSpec?.specId ?? "",
                            isSelected: entity.coverSubjectId == subject.id
                        ) {
                            entity.coverSubjectId = subject.id
                            entity.updatedAt = Date()
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择封面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 封面图片项
struct CoverImageItem: View {
    let subject: Subject
    let specId: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if let image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
