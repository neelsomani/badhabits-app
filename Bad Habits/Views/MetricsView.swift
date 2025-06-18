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
                            .foregroundColor(Color.graySecondary)
                    }
                }
                
                Section(header: Text("This Month")) {
                    HStack {
                        Text("Events")
                        Spacer()
                        Text("\(viewModel.eventsThisMonth())")
                            .foregroundColor(Color.graySecondary)
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
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "lock")
                            .font(.system(size: 20))
                            .foregroundColor(Color.grayTertiary)
                        Text("AI Analysis Locked")
                            .font(.headline)
                            .foregroundColor(.grayPrimary)
                        Text("Get personalized insights about your habit patterns with AI analysis")
                            .font(.subheadline)
                            .foregroundColor(Color.graySecondary)
                            .multilineTextAlignment(.center)
                        Button(action: {/* unlock premium action */}) {
                            Text("Unlock Premium")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                    .padding(4)
                    .background(Color.grayCardBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.grayBorder))
                }
            }
            .navigationTitle("Metrics")
        }
    }
} 