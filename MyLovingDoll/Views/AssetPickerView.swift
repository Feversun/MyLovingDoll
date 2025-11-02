//
//  AssetPickerView.swift
//  MyLovingDoll
//
//  素材选择器 - 类似换装游戏的素材库
//

import SwiftUI
import SwiftData

struct AssetPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetLibrary = AssetLibrary.shared
    @Query private var entities: [Entity]
    
    let onSelect: (Asset) -> Void
    let onSelectDoll: ((DollAsset) -> Void)?
    
    @State private var selectedCategory: ElementType = .doll
    
    init(onSelect: @escaping (Asset) -> Void, onSelectDoll: ((DollAsset) -> Void)? = nil) {
        self.onSelect = onSelect
        self.onSelectDoll = onSelectDoll
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部分类切换
                CategoryTabBar(selectedCategory: $selectedCategory)
                
                Divider()
                
                // 素材网格
                if selectedCategory == .doll {
                    // 娃娃分类：显示对象库
                    DollGrid(
                        dollAssets: assetLibrary.loadDollAssets(from: entities),
                        onSelect: { dollAsset in
                            onSelectDoll?(dollAsset)
                        }
                    )
                } else {
                    // 其他分类：PDF 素材
                    AssetGrid(
                        assets: assetLibrary.assets(for: selectedCategory),
                        onSelect: onSelect
                    )
                }
            }
            .navigationTitle("添加元素")
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

// MARK: - 分类标签栏
struct CategoryTabBar: View {
    @Binding var selectedCategory: ElementType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ElementType.allCases) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - 分类标签
struct CategoryTab: View {
    let category: ElementType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(12)
        }
    }
}

// MARK: - 素材网格
struct AssetGrid: View {
    let assets: [Asset]
    let onSelect: (Asset) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(assets) { asset in
                    AssetGridItem(asset: asset) {
                        onSelect(asset)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 素材网格项
struct AssetGridItem: View {
    @StateObject private var assetLibrary = AssetLibrary.shared
    let asset: Asset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                    
                    assetLibrary.getAssetImage(for: asset)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                }
                .frame(height: 100)
                
                Text(asset.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 娃娃网格
struct DollGrid: View {
    let dollAssets: [DollAsset]
    let onSelect: (DollAsset) -> Void
    
    var body: some View {
        if dollAssets.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("请先在对象库中添加娃娃")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(dollAssets) { dollAsset in
                        DollGridItem(dollAsset: dollAsset) {
                            onSelect(dollAsset)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - 娃娃网格项
struct DollGridItem: View {
    let dollAsset: DollAsset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                    
                    if let image = FileManager.loadImage(
                        relativePath: dollAsset.stickerPath,
                        specId: dollAsset.specId
                    ) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 100)
                
                Text(dollAsset.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AssetPickerView { asset in
        print("Selected: \(asset.name)")
    }
}
