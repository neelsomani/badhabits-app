//
//  Bad_HabitsApp.swift
//  Bad Habits
//
//  Created by Neel Somani on 6/12/25.
//

import SwiftUI
import SwiftData

@main
struct Bad_HabitsApp: App {
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .light
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
