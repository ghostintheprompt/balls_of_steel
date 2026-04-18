import SwiftUI

// MARK: - Prompt Coach View
// Your personal AI prompt assistant - delivers the right analysis prompt at the right time

struct PromptCoachView: View {
    @StateObject private var viewModel = PromptCoachViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header/Explainer
                    promptCoachHeader

                    // Post-Trade Analysis
                    if let postTradePrompt = viewModel.postTradeAnalysisPrompt {
                        postTradeAnalysisCard(postTradePrompt)
                    }

                    // Active/Upcoming Prompts
                    if let activePrompt = viewModel.activePrompt {
                        activePromptCard(activePrompt)
                    }

                    // Today's Schedule
                    todayScheduleSection

                    // Conditional Alerts
                    if !viewModel.conditionalPrompts.isEmpty {
                        conditionalAlertsSection
                    }

                    // Prompt History
                    promptHistorySection
                }
                .padding()
            }
            .navigationTitle("Prompt Coach")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { viewModel.refreshPrompts() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(action: { viewModel.toggleNotifications() }) {
                            Label("Notifications", systemImage: "bell")
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
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.purple)
                Text("Your AI Prompt Coach")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("Get the right analysis prompt at the right time with live data pre-filled. Just copy & paste into ChatGPT or Claude.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                FeatureBadge(icon: "clock.fill", text: "Auto-Scheduled", color: .blue)
                FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Live Data", color: .green)
                FeatureBadge(icon: "doc.on.clipboard", text: "One-Tap Copy", color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Post-Trade Analysis Card
    private func postTradeAnalysisCard(_ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .padding(12)
                    .background(Circle().fill(Color.orange.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("POST-TRADE REVIEW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
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
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }

            Divider()

            ScrollView {
                Text(prompt)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 160)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange, lineWidth: 2)
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
                    .foregroundColor(.green)
                    .padding(12)
                    .background(Circle().fill(Color.green.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("READY NOW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
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
                    .background(Color.blue)
                    .cornerRadius(8)
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
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green, lineWidth: 2)
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
                    .foregroundColor(.red)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
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
        .cornerRadius(6)
    }
}

struct PromptScheduleRow: View {
    let prompt: TradingPrompt
    let isActive: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack {
            Image(systemName: prompt.type.icon)
                .foregroundColor(isActive ? .green : .gray)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            } else {
                Text(timeUntil)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
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
                .foregroundColor(.red)

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
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
}

struct PromptHistoryRow: View {
    let record: PromptHistoryRecord

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

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
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
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
        let losingStreak = 0 // User can track manually

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
            return prompt.template + "\n\n⚠️ No manual data entered. Go to Manual Data Entry to input current market conditions."
        }

        return generatePromptWithManualData(prompt, entry: entry)
    }

    private func generatePromptWithManualData(_ prompt: TradingPrompt, entry: MarketDataEntry) -> String {
        var filledPrompt = prompt.template

        // Replace placeholders with manual entry data
        let priceValue = String(format: "$%.2f", entry.price)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VXX_PRICE]", with: priceValue)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[SPY_PRICE]", with: priceValue)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VIX_LEVEL]", with: String(format: "%.2f", entry.vixLevel))
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VOLUME_PCT]", with: String(format: "%.0f%%", entry.volumePercent))
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VWAP_POSITION]", with: entry.vwapPosition.displayName)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[ARROW_SIGNAL]", with: entry.arrowSignal.displayName)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[TIME_WINDOW]", with: entry.timeWindow.displayName)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[ENTRY_TIME]", with: formatTime(entry.timestamp))

        // Add volume classification
        let volumeLevel = volumeClassification(entry.volumePercent)
        filledPrompt = filledPrompt.replacingOccurrences(of: "[VOLUME_LEVEL]", with: volumeLevel)

        // Add data freshness indicator
        let freshness = dataFreshness(entry.timestamp)
        filledPrompt += "\n\n📊 Data entered: \(freshness)"
        filledPrompt += "\n\n⚠️ Educational Tool: Analyze this setup and execute trades manually on your platform."

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

        // Show success feedback
        // Could trigger a toast/alert here
    }

    func markAsUsed(_ prompt: TradingPrompt) {
        promptHistory.insert(
            PromptHistoryRecord(promptType: prompt.type, timestamp: Date()),
            at: 0
        )

        // Clear active prompt
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
        // Implement notification settings
    }

    deinit {
        monitoringTask?.cancel()
    }
}
