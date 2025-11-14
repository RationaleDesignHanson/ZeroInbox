import SwiftUI
import Charts

/**
 * DeadEndActionDashboard
 * Admin analytics tool for tracking dead-end action feature requests
 * Aggregates "dead_end_feature_requested" events from AnalyticsService
 *
 * Purpose: Product roadmap planning by identifying most-requested incomplete features
 *
 * Features:
 * - Action hit counts grouped by action_id
 * - Date range filtering for trend analysis
 * - UI mode breakdown (professional vs humorous preference)
 * - Visual charts showing top requested features
 * - CSV export for product team planning
 * - Intent context analysis
 */
struct DeadEndActionDashboard: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DeadEndDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching admin theme
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.deadEndEvents.isEmpty {
                    emptyStateView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Dead-End Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Refresh button
                        Button(action: { viewModel.loadAnalytics() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                        }

                        // Export button
                        Button(action: { viewModel.exportToCSV() }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                filterSheet
            }
            .alert("Export Complete", isPresented: $viewModel.showExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.exportMessage)
            }
        }
        .task {
            viewModel.loadAnalytics()
        }
    }

    // MARK: - Loading View

    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Loading analytics...")
                .font(.headline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(DesignTokens.Opacity.textDisabled))

            Text("No Data Yet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Dead-end actions will appear here when users request incomplete features")
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Dashboard Content

    var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Summary cards
                summaryCards

                // Date range filter
                dateRangeFilter

                // Top requested actions chart
                topActionsChart

                // UI mode breakdown
                uiModeBreakdown

                // Detailed action list
                actionDetailsList

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    // MARK: - Summary Cards

    var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                icon: "hand.raised.fill",
                title: "Total Requests",
                value: "\(viewModel.totalRequests)",
                color: .blue
            )

            summaryCard(
                icon: "puzzlepiece.extension.fill",
                title: "Unique Actions",
                value: "\(viewModel.uniqueActions)",
                color: .purple
            )
        }
    }

    func summaryCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1.5)
        )
    }

    // MARK: - Date Range Filter

    var dateRangeFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DATE RANGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                Spacer()

                Button(action: { viewModel.showingFilters = true }) {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedDateRange.displayName)
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.chip)
                }
            }

            Text("\(viewModel.filteredEvents.count) events in selected range")
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Top Actions Chart

    var topActionsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TOP REQUESTED ACTIONS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            if #available(iOS 16.0, *) {
                Chart(viewModel.topActionStats) { stat in
                    BarMark(
                        x: .value("Count", stat.count),
                        y: .value("Action", stat.actionLabel)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(stat.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                    }
                }
                .frame(height: CGFloat(viewModel.topActionStats.count * 40 + 40))
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(DesignTokens.Opacity.textDisabled))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
            } else {
                // Fallback for iOS 15
                ForEach(viewModel.topActionStats) { stat in
                    HStack {
                        Text(stat.actionLabel)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                    .frame(height: 24)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * stat.percentage,
                                        height: 24
                                    )
                            }
                        }
                        .frame(height: 24)

                        Text("\(stat.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - UI Mode Breakdown

    var uiModeBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UI MODE PREFERENCE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            HStack(spacing: 16) {
                modeCard(
                    mode: "Professional",
                    count: viewModel.professionalModeCount,
                    percentage: viewModel.professionalPercentage,
                    icon: "briefcase.fill",
                    color: .blue
                )

                modeCard(
                    mode: "Humorous",
                    count: viewModel.humorousModeCount,
                    percentage: viewModel.humorousPercentage,
                    icon: "face.smiling.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    func modeCard(mode: String, count: Int, percentage: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(mode)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Action Details List

    var actionDetailsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DETAILED BREAKDOWN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            ForEach(viewModel.actionStats) { stat in
                actionDetailRow(stat: stat)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    func actionDetailRow(stat: DeadEndActionStat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.actionLabel)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(stat.actionId)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                        .fontDesign(.monospaced)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stat.count)")
                        .font(.title3.bold())
                        .foregroundColor(.blue)

                    Text("requests")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }
            }

            // Intent context tags
            if !stat.intents.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(DesignTokens.Opacity.textSubtle))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(stat.intents, id: \.self) { intent in
                                Text(intent)
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
                                    .cornerRadius(DesignTokens.Radius.minimal)
                            }
                        }
                    }
                }
            }

            // Last requested timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                Text("Last requested: \(stat.lastRequestedFormatted)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Filter Sheet

    var filterSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    ForEach(DateRangeFilter.allCases, id: \.self) { range in
                        filterOptionRow(range: range)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Date Range Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showingFilters = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    func filterOptionRow(range: DateRangeFilter) -> some View {
        let isSelected = viewModel.selectedDateRange == range
        return Button(action: {
            viewModel.selectedDateRange = range
            viewModel.applyFilter()
            viewModel.showingFilters = false
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.4))
                Text(range.displayName)
                    .foregroundColor(.white)
                Spacer()
                Text(range.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model

@MainActor
class DeadEndDashboardViewModel: ObservableObject {
    @Published var deadEndEvents: [DeadEndEvent] = []
    @Published var filteredEvents: [DeadEndEvent] = []
    @Published var actionStats: [DeadEndActionStat] = []
    @Published var isLoading = false
    @Published var showingFilters = false
    @Published var selectedDateRange: DateRangeFilter = .last7Days
    @Published var showExportAlert = false
    @Published var exportMessage = ""

    var totalRequests: Int {
        filteredEvents.count
    }

    var uniqueActions: Int {
        Set(filteredEvents.map { $0.stepId }).count
    }

    var professionalModeCount: Int {
        filteredEvents.filter { $0.uiMode == "professional" }.count
    }

    var humorousModeCount: Int {
        filteredEvents.filter { $0.uiMode == "humorous" }.count
    }

    var professionalPercentage: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(professionalModeCount) / Double(totalRequests)
    }

    var humorousPercentage: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(humorousModeCount) / Double(totalRequests)
    }

    var topActionStats: [DeadEndActionStat] {
        Array(actionStats.prefix(10))
    }

    func loadAnalytics() {
        isLoading = true

        Task {
            do {
                // Parse analytics log file
                deadEndEvents = try await parseAnalyticsLog()
                applyFilter()
                computeStats()
            } catch {
                Logger.error("Failed to load dead-end analytics: \(error)", category: .analytics)
            }

            isLoading = false
        }
    }

    func applyFilter() {
        let cutoffDate = selectedDateRange.cutoffDate
        filteredEvents = deadEndEvents.filter { $0.timestamp >= cutoffDate }
        computeStats()
    }

    private func computeStats() {
        // Group events by action_id
        var statsDict: [String: DeadEndActionStat] = [:]

        for event in filteredEvents {
            if var stat = statsDict[event.stepId] {
                stat.count += 1
                if event.timestamp > stat.lastRequested {
                    stat.lastRequested = event.timestamp
                }
                if let intent = event.intent, !stat.intents.contains(intent) {
                    stat.intents.append(intent)
                }
                statsDict[event.stepId] = stat
            } else {
                statsDict[event.stepId] = DeadEndActionStat(
                    actionId: event.stepId,
                    actionLabel: event.stepId.replacingOccurrences(of: "_", with: " ").capitalized,
                    count: 1,
                    intents: event.intent != nil ? [event.intent!] : [],
                    lastRequested: event.timestamp
                )
            }
        }

        // Sort by count descending
        actionStats = statsDict.values
            .sorted { $0.count > $1.count }
            .map { stat in
                var updated = stat
                let maxCount = statsDict.values.map { $0.count }.max() ?? 1
                updated.percentage = Double(stat.count) / Double(maxCount)
                return updated
            }
    }

    private func parseAnalyticsLog() async throws -> [DeadEndEvent] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        let logFileURL = documentsPath.appendingPathComponent("analytics.log")

        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return []
        }

        let logContent = try String(contentsOf: logFileURL, encoding: .utf8)
        let lines = logContent.components(separatedBy: "\n")

        var events: [DeadEndEvent] = []

        for line in lines {
            guard line.contains("dead_end_feature_requested") else { continue }

            let components = line.components(separatedBy: " | ")
            guard components.count >= 3 else { continue }

            let timestampStr = components[0]
            let propertiesJSON = components[2]

            // Parse timestamp
            let formatter = ISO8601DateFormatter()
            guard let timestamp = formatter.date(from: timestampStr) else { continue }

            // Parse JSON properties
            guard let jsonData = propertiesJSON.data(using: .utf8),
                  let properties = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let stepId = properties["step_id"] as? String,
                  let uiMode = properties["ui_mode"] as? String else {
                continue
            }

            let intent = properties["card_intent"] as? String

            events.append(DeadEndEvent(
                timestamp: timestamp,
                stepId: stepId,
                uiMode: uiMode,
                intent: intent
            ))
        }

        return events.sorted { $0.timestamp > $1.timestamp }
    }

    func exportToCSV() {
        var csvLines: [String] = []

        // Header
        csvLines.append("Action ID,Action Label,Request Count,Last Requested,Intents,Professional Count,Humorous Count")

        // Data rows
        for stat in actionStats {
            let professionalCount = filteredEvents.filter { $0.stepId == stat.actionId && $0.uiMode == "professional" }.count
            let humorousCount = filteredEvents.filter { $0.stepId == stat.actionId && $0.uiMode == "humorous" }.count

            csvLines.append("\(stat.actionId),\(stat.actionLabel),\(stat.count),\(stat.lastRequestedFormatted),\"\(stat.intents.joined(separator: ", "))\",\(professionalCount),\(humorousCount)")
        }

        let csv = csvLines.joined(separator: "\n")

        // Save to documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportMessage = "Failed to access documents directory"
            showExportAlert = true
            return
        }

        let filename = "dead_end_analytics_\(Int(Date().timeIntervalSince1970)).csv"
        let fileURL = documentsPath.appendingPathComponent(filename)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportMessage = "Exported \(actionStats.count) actions to:\n\(fileURL.path)"
            showExportAlert = true
            Logger.info("Exported dead-end analytics to: \(fileURL.path)", category: .analytics)
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
            showExportAlert = true
        }
    }
}

// MARK: - Models

struct DeadEndEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let stepId: String
    let uiMode: String
    let intent: String?
}

struct DeadEndActionStat: Identifiable {
    let id = UUID()
    let actionId: String
    let actionLabel: String
    var count: Int
    var intents: [String]
    var lastRequested: Date
    var percentage: Double = 0.0

    var lastRequestedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRequested, relativeTo: Date())
    }
}

enum DateRangeFilter: String, CaseIterable {
    case last24Hours = "last_24_hours"
    case last7Days = "last_7_days"
    case last30Days = "last_30_days"
    case last90Days = "last_90_days"
    case allTime = "all_time"

    var displayName: String {
        switch self {
        case .last24Hours: return "Last 24 Hours"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .allTime: return "All Time"
        }
    }

    var description: String {
        switch self {
        case .last24Hours: return "Past day"
        case .last7Days: return "Past week"
        case .last30Days: return "Past month"
        case .last90Days: return "Past quarter"
        case .allTime: return "Since launch"
        }
    }

    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .last24Hours:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .last90Days:
            return calendar.date(byAdding: .day, value: -90, to: now) ?? now
        case .allTime:
            return Date.distantPast
        }
    }
}

// MARK: - Preview

#Preview {
    DeadEndActionDashboard()
}
