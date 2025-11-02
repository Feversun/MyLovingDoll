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
                    Image("TabIcon_Home")
                        .renderingMode(.original)
                    Text("对象库")
                }
            
            // Tab 2: 故事书
            StoryBooksView()
                .tabItem {
                    Image("TabIcon_Book")
                        .renderingMode(.original)
                    Text("故事书")
                }
            
            // Tab 3: 我的故事
            MyStoriesView()
                .tabItem {
                    Image("TabIcon_MyStory")
                        .renderingMode(.original)
                    Text("我的故事")
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
