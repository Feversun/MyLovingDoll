//
//  MainTabView.swift
//  MyLovingDoll
//
//  主 Tab 导航视图
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            // Tab 1: 对象库
            ObjectCampHomeView(modelContext: modelContext)
                .tabItem {
                    Label("对象库", systemImage: "photo.stack.fill")
                }
            
            // Tab 2: 故事书
            StoryBooksView()
                .tabItem {
                    Label("故事书", systemImage: "book.fill")
                }
            
            // Tab 3: 我的故事
            MyStoriesView()
                .tabItem {
                    Label("我的故事", systemImage: "book.pages.fill")
                }
            
            // Tab 4: 画布
            CanvasListView()
                .tabItem {
                    Label("画布", systemImage: "rectangle.on.rectangle.angled")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Entity.self, Subject.self, TargetSpec.self, ProcessingTask.self, StoryInstance.self])
}
