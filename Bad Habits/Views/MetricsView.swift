import SwiftUI
import Charts

struct MetricsView: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("This Week")) {
                    HStack {
                        Text("Events")
                        Spacer()
                        Text("\(viewModel.eventsThisWeek())")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("This Month")) {
                    HStack {
                        Text("Events")
                        Spacer()
                        Text("\(viewModel.eventsThisMonth())")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Weekly Events Over Time")) {
                    Chart {
                        ForEach(viewModel.weeklyEventsOverYear(), id: \.0) { date, count in
                            BarMark(
                                x: .value("Week", date, unit: .weekOfYear),
                                y: .value("Events", count)
                            )
                        }
                    }
                    .frame(height: 200)
                }
                
                Section(header: Text("AI Analysis")) {
                    HStack {
                        Text("Weekly Analysis")
                        Spacer()
                        Text("Unlock")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Metrics")
        }
    }
} 