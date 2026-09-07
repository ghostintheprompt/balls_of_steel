import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Prompt Coach View
// Delivers the right analysis prompt for the active trading window.

struct PromptCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PromptCoachViewModel()
    @StateObject private var notifications = SignalNotification.shared

    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(spacing: 20) {
                        promptCoachHeader

                        if let postTradePrompt = viewModel.postTradeAnalysisPrompt {
                            postTradeAnalysisCard(postTradePrompt)
                        }

                        if let activePrompt = viewModel.activePrompt {
                            activePromptCard(activePrompt)
                        }

                        todayScheduleSection

                        if !viewModel.conditionalPrompts.isEmpty {
                            conditionalAlertsSection
                        }

                        promptHistorySection
                    }
                    .padding()
                }

            }
            .navigationTitle("Prompt Desk")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { viewModel.refreshPrompts() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button {
                            Task {
                                if notifications.isPermissionGranted {
                                    notifications.sendTestNotification()
                                } else {
                                    await notifications.handlePermissionAction()
                                }
                            }
                        } label: {
                            Label(notifications.isPermissionGranted ? "Test Notification" : notifications.permissionActionTitle, systemImage: "bell")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.startMonitoring()
        }
    }

    // MARK: - Header
    private var promptCoachHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.title)
                    .foregroundColor(DesignSystem.primaryColor)
                Text("Prompt Desk")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.primaryText)
            }

            Text("Copy the right question for the current window. Use your tape values. No magic, no autopilot.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                FeatureBadge(icon: "clock.fill", text: "Window", color: DesignSystem.primaryColor)
                FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Tape", color: DesignSystem.bullishColor)
                FeatureBadge(icon: "doc.on.clipboard", text: "Copy", color: DesignSystem.secondaryColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.panelTop)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(DesignSystem.panelStroke, lineWidth: 1)
                )
        )
    }

    // MARK: - Post-Trade Analysis Card
    private func postTradeAnalysisCard(_ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.secondaryColor)
                    .padding(12)
                    .background(Circle().fill(DesignSystem.secondaryColor.opacity(0.12)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("POST-TRADE REVIEW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.secondaryColor)
                    Text("Last Trade Analysis")
                        .font(.headline)
                }

                Spacer()

                Button(action: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prompt, forType: .string)
                    #else
                    UIPasteboard.general.string = prompt
                    #endif
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title3)
                        Text("Copy")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.secondaryColor)
                    .cornerRadius(2)
                }
            }

            Divider()

            ScrollView {
                Text(prompt)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.faint.opacity(0.40))
                    .cornerRadius(2)
            }
            .frame(maxHeight: 160)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.panelTop)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(DesignSystem.secondaryColor.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - Active Prompt Card
    private func activePromptCard(_ prompt: TradingPrompt) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: prompt.type.icon)
                    .font(.title2)
                    .foregroundColor(DesignSystem.long)
                    .padding(12)
                    .background(Circle().fill(DesignSystem.long.opacity(0.10)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("WINDOW PROMPT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.long)
                    Text(prompt.type.displayName)
                        .font(.headline)
                }

                Spacer()

                // Copy button
                Button(action: { viewModel.copyPrompt(prompt) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title3)
                        Text("Copy")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.amber)
                    .cornerRadius(2)
                }
            }

            Divider()

            // Preview
            Text("Prompt Preview (with live data):")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                Text(viewModel.generatePromptWithLiveData(prompt))
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.faint.opacity(0.40))
                    .cornerRadius(2)
            }
            .frame(maxHeight: 200)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { viewModel.copyPrompt(prompt) }) {
                    Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { viewModel.markAsUsed(prompt) }) {
                    Label("Mark Used", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.long.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(DesignSystem.long, lineWidth: 1)
                )
        )
    }

    // MARK: - Today's Schedule
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Prompt Schedule")
                .font(.headline)

            ForEach(viewModel.todayPrompts, id: \.id) { prompt in
                PromptScheduleRow(
                    prompt: prompt,
                    isActive: viewModel.isActive(prompt),
                    onCopy: { viewModel.copyPrompt(prompt) }
                )
            }
        }
    }

    // MARK: - Conditional Alerts
    private var conditionalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.short)
                Text("Conditional Alerts")
                    .font(.headline)
            }

            ForEach(viewModel.conditionalPrompts, id: \.id) { prompt in
                ConditionalAlertRow(
                    prompt: prompt,
                    onCopy: { viewModel.copyPrompt(prompt) }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.short.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(DesignSystem.short.opacity(0.30), lineWidth: 1)
                )
        )
    }

    // MARK: - History
    private var promptHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Prompts")
                .font(.headline)

            ForEach(viewModel.promptHistory.prefix(5), id: \.id) { record in
                PromptHistoryRow(record: record)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(2)
    }
}

struct PromptScheduleRow: View {
    let prompt: TradingPrompt
    let isActive: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack {
            Image(systemName: prompt.type.icon)
                .foregroundColor(isActive ? DesignSystem.long : DesignSystem.muted)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.type.displayName)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)

                Text(scheduleTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isActive {
                Button(action: onCopy) {
                    Text("Copy")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.amber)
                        .foregroundColor(.white)
                        .cornerRadius(2)
                }
            } else {
                Text(timeUntil)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? DesignSystem.long.opacity(0.10) : DesignSystem.faint.opacity(0.30))
        )
    }

    private var scheduleTime: String {
        switch prompt.scheduledTime {
        case .time(let hour, let minute):
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
            return formatter.string(from: date)
        default:
            return "Conditional"
        }
    }

    private var timeUntil: String {
        switch prompt.scheduledTime {
        case .time(let hour, let minute):
            let now = Date()
            let calendar = Calendar.current
            let target = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!

            let minutes = calendar.dateComponents([.minute], from: now, to: target).minute ?? 0
            if minutes < 0 {
                return "Past"
            } else if minutes == 0 {
                return "Now"
            } else {
                return "in \(minutes)m"
            }
        default:
            return ""
        }
    }
}

struct ConditionalAlertRow: View {
    let prompt: TradingPrompt
    let onCopy: () -> Void

    var body: some View {
        HStack {
            Image(systemName: prompt.type.icon)
                .foregroundColor(DesignSystem.short)

            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Triggered by market conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.short)
                    .foregroundColor(.white)
                    .cornerRadius(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.short.opacity(0.10))
        )
    }
}

struct PromptHistoryRow: View {
    let record: PromptHistoryRecord

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.long)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.promptType.displayName)
                    .font(.subheadline)
                Text(record.timestamp, style: .relative) + Text(" ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Used")
                .font(.caption)
                .foregroundColor(DesignSystem.long)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.faint.opacity(0.30))
        )
    }
}

// MARK: - Prompt History Record
struct PromptHistoryRecord: Identifiable {
    let id = UUID()
    let promptType: TradingPrompt.PromptType
    let timestamp: Date
}

// MARK: - View Model
@MainActor
class PromptCoachViewModel: ObservableObject {
    @Published var activePrompt: TradingPrompt?
    @Published var todayPrompts: [TradingPrompt] = []
    @Published var conditionalPrompts: [TradingPrompt] = []
    @Published var promptHistory: [PromptHistoryRecord] = []
    @Published var manualDataEntry: MarketDataEntry?
    @Published var postTradeAnalysisPrompt: String? = nil

    private let promptLibrary = PromptLibrary.shared
    private let journal = TradeJournal.shared
    private var monitoringTask: Task<Void, Never>?

    init() {
        loadManualDataEntry()
        refreshPostTradePrompt()
    }

    func startMonitoring() async {
        loadTodayPrompts()

        monitoringTask = Task {
            while !Task.isCancelled {
                checkActivePrompt()
                checkConditionalPrompts()
                loadManualDataEntry() // Refresh manual entry
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every minute
            }
        }
    }

    func loadTodayPrompts() {
        todayPrompts = promptLibrary.getTodayPrompts()
    }

    func checkActivePrompt() {
        activePrompt = promptLibrary.getScheduledPrompt()
    }

    func checkConditionalPrompts() {
        // Check VIX level from manual entry
        let vix = manualDataEntry?.vixLevel ?? 0
        let losingStreak = journal.calculateLosingStreak()

        conditionalPrompts = promptLibrary.checkConditionalPrompts(
            vix: vix,
            losingStreak: losingStreak
        )
    }

    func loadManualDataEntry() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "lastMarketDataEntry"),
           let entry = try? JSONDecoder().decode(MarketDataEntry.self, from: data) {
            manualDataEntry = entry
        }
    }

    func isActive(_ prompt: TradingPrompt) -> Bool {
        activePrompt?.id == prompt.id
    }

    func generatePromptWithLiveData(_ prompt: TradingPrompt) -> String {
        // Use manual entry data to pre-fill prompt
        guard let entry = manualDataEntry else {
            return prompt.template + "\n\nWARNING: No manual data entered. Go to Manual Data Entry to input current market conditions."
        }
        
        // Convert MarketDataEntry to MarketData for the prompt system
        // This leverages the centralized logic in PromptSystem
        let marketData = MarketData(
            quote: Quote(
                symbol: "VXX", // Assuming VXX as primary focus
                price: entry.price,
                volume: Int(entry.volumePercent * 10_000),
                vwap: entry.vwapPosition == .above ? entry.price * 0.99 : entry.price * 1.01,
                previousClose: entry.price,
                timestamp: entry.timestamp,
                recentCandles: []
            ),
            vwap: entry.vwapPosition == .above ? entry.price * 0.99 : entry.price * 1.01,
            volume: Int(entry.volumePercent * 10000), // Scaled
            trades: 0,
            ivRank: 0,
            daysToEarnings: 0,
            hasFundamentalNews: false,
            vix: entry.vixLevel,
            vixDailyChange: 0,
            spyDailyChange: 0,
            newsRisk: .none,
            hasZDTEOptions: false,
            averageVolume: 1000000,
            averageOptionsVolume: 0,
            optionsVolume: 0,
            rsi: 0,
            emaBreakout: false,
            vwapBreakout: false,
            isWeeklyExpiration: false,
            otmProbability: 0,
            minutesSinceMarketOpen: 0,
            marketOpen: 0,
            detectedPattern: nil,
            technicalIndicators: nil,
            detectedArrowSignal: nil
        )

        let stats = TradingStats.current()
        var filledPrompt = prompt.generateWithLiveData(marketData: marketData, tradingStats: stats)

        // Add volume classification (specialized for manual entry context)
        let volumeLevel = volumeClassification(entry.volumePercent)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VOLUME_LEVEL]", with: volumeLevel)

        // Add data freshness indicator
        let freshness = dataFreshness(entry.timestamp)
        filledPrompt += "\n\n[DATA] Data entered: \(freshness)"
        filledPrompt += "\n\nWARNING: Educational Tool: Analyze this setup and execute trades manually on your platform."

        return filledPrompt
    }

    private func volumeClassification(_ volumePct: Double) -> String {
        if volumePct >= 400 {
            return "MAJOR INSTITUTION (400%+)"
        } else if volumePct >= 300 {
            return "INSTITUTIONAL FLOW (300%+)"
        } else if volumePct >= 200 {
            return "Standard Entry OK (200%+)"
        } else {
            return "BELOW THRESHOLD - SKIP"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func dataFreshness(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }

    func copyPrompt(_ prompt: TradingPrompt) {
        let filledPrompt = generatePromptWithLiveData(prompt)

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(filledPrompt, forType: .string)
        #else
        UIPasteboard.general.string = filledPrompt
        #endif
    }

    func markAsUsed(_ prompt: TradingPrompt) {
        promptHistory.insert(
            PromptHistoryRecord(promptType: prompt.type, timestamp: Date()),
            at: 0
        )

        if activePrompt?.id == prompt.id {
            activePrompt = nil
        }
    }

    func refreshPostTradePrompt() {
        let context = journal.postTradeAnalysisContext()
        guard !context.isEmpty else {
            postTradeAnalysisPrompt = nil
            return
        }
        postTradeAnalysisPrompt = """
        You are a VXX trading coach. Analyze this trade entry against the discipline framework: \
        only fade when the ratio is stretched, volume confirms, timing is right, no fresh news.

        \(context)

        In 3-4 sentences: did the setup meet all four conditions? What was the actual edge? \
        What should be reinforced or avoided next time?
        """
    }

    func refreshPrompts() {
        loadTodayPrompts()
        checkActivePrompt()
        checkConditionalPrompts()
        refreshPostTradePrompt()
    }

    func toggleNotifications() {
        Task {
            if SignalNotification.shared.isPermissionGranted {
                SignalNotification.shared.sendTestNotification()
            } else {
                await SignalNotification.shared.handlePermissionAction()
            }
        }
    }

    deinit {
        monitoringTask?.cancel()
    }
}
