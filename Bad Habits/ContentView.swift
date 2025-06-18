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
                    Image(systemName: "plus")
                    Text("Track")
                }
            MetricsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Metrics")
                }
            SettingsView(showingAddColumn: .constant(false), showingAddCategory: .constant(false))
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .accentColor(Color.primaryBlue)
        .environmentObject(viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
