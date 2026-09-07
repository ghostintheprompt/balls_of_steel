import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Prompt Coach View
//
// Delivers the right analysis prompt for the active trading window. Visual
// language matches SystemsPanel (Settings) / TradeJournalView: flat,
// hairline-bordered panels, monospace label/value rows, amber accents --
// this file used to be built against an older, generic-iOS visual language
// (system fonts, colored circle icon badges, rounded pill buttons) that
// never matched the rest of the app.

struct PromptCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PromptCoachViewModel()
    @StateObject private var notifications = SignalNotification.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(DesignSystem.hairline).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Copy the right question for the current window. Use your tape values. No magic, no autopilot.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    // The schedule below only has something to copy during ~4
                    // narrow windows a day -- outside those it was pure
                    // countdown noise ("IN 171M", "PAST", nothing readable).
                    // This is always live, built from the same real tape data
                    // the dashboard shows, whatever time it is.
                    promptPanel(
                        title: "CURRENT TAPE",
                        accent: DesignSystem.amber,
                        body: viewModel.currentTapePrompt,
                        onCopy: { copyToPasteboard(viewModel.currentTapePrompt) }
                    )

                    if let postTradePrompt = viewModel.postTradeAnalysisPrompt {
                        promptPanel(
                            title: "POST-TRADE REVIEW",
                            accent: DesignSystem.text2,
                            body: postTradePrompt,
                            onCopy: { copyToPasteboard(postTradePrompt) }
                        )
                    }

                    if let activePrompt = viewModel.activePrompt {
                        promptPanel(
                            title: "WINDOW PROMPT · \(activePrompt.type.displayName.uppercased())",
                            accent: DesignSystem.long,
                            body: viewModel.generatePromptWithLiveData(activePrompt),
                            onCopy: { viewModel.copyPrompt(activePrompt) },
                            onMarkUsed: { viewModel.markAsUsed(activePrompt) }
                        )
                    }

                    schedulePanel

                    if !viewModel.conditionalPrompts.isEmpty {
                        conditionalPanel
                    }

                    historyPanel
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.bg.ignoresSafeArea())
        .task {
            await viewModel.startMonitoring()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Text("PROMPT DESK")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.amber)

            Spacer()

            headerIconButton("arrow.clockwise", help: "Refresh") {
                viewModel.refreshPrompts()
            }
            headerIconButton("bell", help: notifications.isPermissionGranted ? "Test Notification" : notifications.permissionActionTitle) {
                Task {
                    if notifications.isPermissionGranted {
                        notifications.sendTestNotification()
                    } else {
                        await notifications.handlePermissionAction()
                    }
                }
            }
            #if os(macOS)
            headerIconButton("xmark", help: "Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.bg)
    }

    private func headerIconButton(_ systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.primaryText)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(DesignSystem.bg1)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
        .help(help)
    }

    // MARK: Prompt panel (post-trade review / active window prompt)

    private func promptPanel(
        title: String,
        accent: Color,
        body: String,
        onCopy: @escaping () -> Void,
        onMarkUsed: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(accent)
                Spacer()
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.clipboard")
                        .font(DesignSystem.Typography.captionFont)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.amber)
                if let onMarkUsed {
                    Button(action: onMarkUsed) {
                        Label("Used", systemImage: "checkmark")
                            .font(DesignSystem.Typography.captionFont)
                    }
                    .buttonStyle(.bordered)
                    .tint(DesignSystem.muted)
                }
            }

            ScrollView {
                Text(body)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(maxHeight: 160)
            .background(DesignSystem.bg1)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
        }
        .padding(14)
        .background(DesignSystem.panel)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(accent.opacity(0.5), lineWidth: 1))
    }

    // MARK: Today's schedule

    private var schedulePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY'S SCHEDULE")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.amber)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.todayPrompts.enumerated()), id: \.element.id) { index, prompt in
                    scheduleRow(prompt)
                    if index < viewModel.todayPrompts.count - 1 {
                        Rectangle().fill(DesignSystem.hairline).frame(height: 1)
                    }
                }
            }
            .background(DesignSystem.bg1)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
        }
        .padding(14)
        .background(DesignSystem.panel)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private func scheduleRow(_ prompt: TradingPrompt) -> some View {
        let isActive = viewModel.isActive(prompt)
        return HStack {
            Text(prompt.type.displayName.uppercased())
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(isActive ? DesignSystem.long : DesignSystem.text2)
            Spacer()
            if isActive {
                Button {
                    viewModel.copyPrompt(prompt)
                } label: {
                    Text("COPY")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.amber)
            } else {
                Text(scheduleTimeText(prompt))
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.faint)
            }
        }
        .padding(12)
    }

    private func scheduleTimeText(_ prompt: TradingPrompt) -> String {
        switch prompt.scheduledTime {
        case .time(let hour, let minute):
            let now = Date()
            let calendar = Calendar.current
            guard let target = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else { return "" }
            let minutes = calendar.dateComponents([.minute], from: now, to: target).minute ?? 0
            if minutes < 0 { return "PAST" }
            if minutes == 0 { return "NOW" }
            return "IN \(minutes)M"
        default:
            return "CONDITIONAL"
        }
    }

    // MARK: Conditional alerts

    private var conditionalPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONDITIONAL ALERTS")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.short)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.conditionalPrompts.enumerated()), id: \.element.id) { index, prompt in
                    HStack {
                        Text(prompt.type.displayName.uppercased())
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.text2)
                        Spacer()
                        Button {
                            viewModel.copyPrompt(prompt)
                        } label: {
                            Text("COPY")
                                .font(DesignSystem.Typography.labelFont)
                                .tracking(1.2)
                        }
                        .buttonStyle(.bordered)
                        .tint(DesignSystem.short)
                    }
                    .padding(12)
                    if index < viewModel.conditionalPrompts.count - 1 {
                        Rectangle().fill(DesignSystem.hairline).frame(height: 1)
                    }
                }
            }
            .background(DesignSystem.bg1)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.short.opacity(0.3), lineWidth: 1))
        }
        .padding(14)
        .background(DesignSystem.panel)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.short.opacity(0.3), lineWidth: 1))
    }

    // MARK: History

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.amber)

            if viewModel.promptHistory.isEmpty {
                Text("Nothing marked used yet.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.faint)
            } else {
                let recent = Array(viewModel.promptHistory.prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, record in
                        HStack {
                            Text(record.promptType.displayName.uppercased())
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.text2)
                            Spacer()
                            Text(record.timestamp, style: .relative)
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.faint)
                        }
                        .padding(12)
                        if index < recent.count - 1 {
                            Rectangle().fill(DesignSystem.hairline).frame(height: 1)
                        }
                    }
                }
                .background(DesignSystem.bg1)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
            }
        }
        .padding(14)
        .background(DesignSystem.panel)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private func copyToPasteboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
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

    /// Always available, whatever the clock says -- built from the same
    /// live tape data the dashboard shows, not tied to a scheduled window.
    var currentTapePrompt: String {
        guard let entry = manualDataEntry else {
            return "No tape yet. Enter a manual read or wait for a live tick, then check back here."
        }

        var lines: [String] = [
            "Checking the desk right now (\(dataFreshness(entry.timestamp))).",
            "",
            "LIVE READ:",
            "- \(entry.instrument.displayName) price: $\(String(format: "%.2f", entry.price))",
            "- VIX: \(String(format: "%.2f", entry.vixLevel))"
        ]
        if entry.instrument == .vxx {
            lines.append("- VXX/VIX ratio: \(String(format: "%.3f", entry.ratio)) (\(entry.ratioTier.uppercased()))")
        }
        lines.append(contentsOf: [
            "- Volume: \(volumeClassification(entry.volumePercent))",
            "- VWAP position: \(entry.vwapPosition.shortName)",
            "- Window: \(entry.timeWindow.displayName)",
            "- Key level: \(entry.keyLevelConfirmed ? "confirmed" : "not confirmed")",
            "",
            "Is this actually a clean setup right now, or am I forcing it? Rate volume, timing, ratio, and VWAP/level against the rules -- don't just tell me what I want to hear."
        ])
        return lines.joined(separator: "\n")
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
