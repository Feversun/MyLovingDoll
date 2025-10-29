//
//  MyLovingDollApp.swift
//  MyLovingDoll
//
//  Created by How Sun on 2025/10/29.
//

import SwiftUI
import SwiftData

@main
struct MyLovingDollApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TargetSpec.self,
            Subject.self,
            Entity.self,
            ProcessingTask.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ObjectCampHomeView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
}
