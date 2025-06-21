import SwiftUI
import Charts

struct MetricsView: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    @State private var period: Period = .weekly
    @State private var tooltipData: (date: Date, count: Int)?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var selectedDate: Date? = nil
    
    enum Period: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }
    }
    
    var eventsCount: Int {
        switch period {
        case .weekly: return viewModel.eventsThisWeek()
        case .monthly: return viewModel.eventsThisMonth()
        }
    }
    
    var trendData: [(Date, Int)] {
        switch period {
        case .weekly: return viewModel.weeklyEventsOverYear()
        case .monthly: return viewModel.monthlyEventsOverYear()
        }
    }
    
    var reasonBreakdown: [(String, Int)] {
        // If a date is selected from chart interaction, use that
        if let selectedDate = selectedDate {
            switch period {
            case .weekly:
                return viewModel.reasonBreakdownForWeek(weekStart: selectedDate)
            case .monthly:
                return viewModel.reasonBreakdownForMonth(monthStart: selectedDate)
            }
        } else {
            // Otherwise use current week/month
            switch period {
            case .weekly: return viewModel.reasonBreakdownThisWeek()
            case .monthly: return viewModel.reasonBreakdownThisMonth()
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if HabitViewModel.isAIInsightsEnabled() {
                    aiAnalysisCard
                }
                periodToggle
                eventsCountCard
                trendChartCard
                reasonBreakdownCard
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .background(Color.grayLightBg.ignoresSafeArea())
    }

    private var aiAnalysisCard: some View {
        let credits = 0
        let weeksRemaining = 0
        let canWithdraw = credits > 0
        return VStack(spacing: 20) {
            // Insights Box (scrollable)
            ScrollView(.vertical, showsIndicators: true) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryBlue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primaryBlue)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This Week's Insights")
                            .font(.headline)
                            .bold()
                        if credits == 0 {
                            Text("Deposit credits to generate AI insights for your habits and earn rewards for improving.")
                                .font(.body)
                                .foregroundColor(.grayTertiary)
                        } else {
                            Text("Your habit patterns show a strong correlation between \"Reward\" activities and late evening hours (after 8 PM). You've logged 12 entries this week, with 60% occurring on weekends. Consider setting boundaries around reward-based habits during weekdays to maintain better balance. Your FOCUS category has decreased by 30% compared to last week - try scheduling dedicated focus time in the mornings when your patterns show higher success rates.")
                                .font(.body)
                                .foregroundColor(.grayPrimary)
                        }
                    }
                    Spacer()
                }
                .padding(16)
            }
            .background(Color.primaryBlue.opacity(0.07))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primaryBlue.opacity(0.15)))
            .frame(maxHeight: 180)
            // Credits and weeks remaining
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.yellow)
                Text("\(credits) credits • \(weeksRemaining) weeks remaining")
                    .font(.subheadline)
                    .foregroundColor(.graySecondary)
                Spacer()
            }
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {/* deposit credits */}) {
                    Text("Deposit Credits")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {/* withdraw credits */}) {
                    Text("Withdraw Credits")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.primaryBlue)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primaryBlue, lineWidth: 2))
                }
                .disabled(!canWithdraw)
                .opacity(canWithdraw ? 1.0 : 0.5)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
    }

    private var periodToggle: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases) { p in
                Button(action: { period = p }) {
                    Text(p.rawValue)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(period == p ? Color.primaryBlue.opacity(0.1) : Color.clear)
                        .foregroundColor(period == p ? .primaryBlue : .grayPrimary)
                }
            }
        }
        .background(Color.grayCardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.grayBorder))
        .padding(.horizontal)
        .onChange(of: period) { _ in
            // Reset selected date when switching periods
            selectedDate = nil
        }
    }

    private var eventsCountCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.primaryBlue)
            Text("\(eventsCount)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primaryBlue)
            Text(period == .weekly ? "This Week" : "This Month")
                .font(.headline)
                .foregroundColor(.grayPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
    }

    private var trendChartCard: some View {
        // Only show the range of trendData that contains data
        let allData = trendData
        let firstIdx = allData.firstIndex(where: { $0.1 > 0 }) ?? 0
        let lastIdx = allData.lastIndex(where: { $0.1 > 0 }) ?? (allData.count - 1)
        let chartData = (firstIdx <= lastIdx) ? Array(allData[firstIdx...lastIdx]) : []
        let xLabel = period == .weekly ? "Week" : "Month"
        let xUnit: Calendar.Component = period == .weekly ? .weekOfYear : .month
        let maxY = chartData.map { $0.1 }.max() ?? 1
        let bufferedMax = Double(maxY) * 1.1
        return VStack(alignment: .leading, spacing: 12) {
            Text(period == .weekly ? "Weekly Trend" : "Monthly Trend")
                .font(.headline)
                .foregroundColor(.grayPrimary)
            Chart {
              ForEach(chartData, id: \.0) { date, count in
                BarMark(
                  x: .value(xLabel, date, unit: xUnit),
                  y: .value("Events", count)
                )
              }
            }
            .chartYScale(domain: 0...bufferedMax)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = geo[proxy.plotAreaFrame]
                    let barCount = max(chartData.count, 1)
                    let barWidth = plotFrame.width / (CGFloat(barCount) * 1.5)
                    let halfBarWidth = barWidth / 2
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .frame(width: plotFrame.width, height: plotFrame.height)
                            .offset(x: plotFrame.minX, y: plotFrame.minY)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xInPlot = value.location.x
                                        guard proxy.value(atX: xInPlot, as: Date.self) != nil else {
                                            tooltipData = nil
                                            return
                                        }
                                        if let nearest = chartData.min(by: {
                                            guard
                                                let x0 = proxy.position(forX: $0.0),
                                                let x1 = proxy.position(forX: $1.0)
                                            else { return false }
                                            let center0 = x0 + halfBarWidth
                                            let center1 = x1 + halfBarWidth
                                            return abs(center0 - xInPlot) < abs(center1 - xInPlot)
                                        }) {
                                            tooltipData = (date: nearest.0, count: nearest.1)
                                            selectedDate = nearest.0
                                            tooltipPosition = CGPoint(x: value.location.x + plotFrame.minX, y: value.location.y + plotFrame.minY)
                                        }
                                    }
                                    .onEnded { _ in 
                                        tooltipData = nil
                                    }
                            )
                        if let tip = tooltipData {
                            VStack(spacing: 4) {
                                Text("\(tip.count)").font(.headline).foregroundColor(.white)
                                Text("events").font(.caption).foregroundColor(.white.opacity(0.8))
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(6)
                            .position(x: tooltipPosition.x, y: tooltipPosition.y - 40)
                        }
                    }
                    .frame(width: plotFrame.width, height: plotFrame.height)
                }
            }
            .frame(height: 200)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
    }

    private var reasonBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reason Breakdown")
                    .font(.headline)
                    .foregroundColor(.grayPrimary)
                Spacer()
                if selectedDate != nil {
                    Text("Tap to reset")
                        .font(.caption2)
                        .foregroundColor(.grayTertiary)
                }
            }
            
            // Always show date range - either selected date or current week/month
            Text(formatDateRange(for: selectedDate ?? getCurrentPeriodStart()))
                .font(.caption)
                .foregroundColor(.graySecondary)
                .padding(.bottom, 4)
            
            ForEach(Array(reasonBreakdown.enumerated()), id: \.offset) { _, element in
                let (reason, count) = element
                HStack {
                    Text(reason.capitalized)
                        .font(.body)
                        .foregroundColor(.grayPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(.body)
                        .foregroundColor(.primaryBlue)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(selectedDate != nil ? Color.primaryBlue.opacity(0.02) : Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
        .onTapGesture {
            // Reset to current week/month when tapped
            selectedDate = nil
        }
    }
    
    // Helper function to format date range for display
    private func formatDateRange(for date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        switch period {
        case .weekly:
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: date)!
            return "\(formatter.string(from: date)) - \(formatter.string(from: weekEnd))"
        case .monthly:
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: date)!
            let monthEndAdjusted = calendar.date(byAdding: .day, value: -1, to: monthEnd)!
            return "\(formatter.string(from: date)) - \(formatter.string(from: monthEndAdjusted))"
        }
    }
    
    private func getCurrentPeriodStart() -> Date {
        let calendar = Calendar.current
        switch period {
        case .weekly:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        case .monthly:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        }
    }
}

