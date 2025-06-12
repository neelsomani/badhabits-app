//
//  ContentView.swift
//  Bad Habits
//
//  Created by Neel Somani on 6/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = HabitViewModel()
    
    var body: some View {
        TabView {
            HabitEntriesView()
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }
            
            MetricsView()
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar")
                }
        }
        .environmentObject(viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
