import SwiftUI
import Combine

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @StateObject private var marketPulse = MarketPulse.shared
    
    var body: some View {
        NavigationView {
            List {
                TestSessionBanner()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                // Market Status Card
                MarketStatusView(phase: marketPulse.currentPhase)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                
                // Active Signals Section
                Section("Active Signals") {
                    ForEach(signalMonitor.activeSignals) { signal in
                        SharedSignalRowView(signal: signal)
                            .swipeActions {
                                Button("Trade") {
                                    signalMonitor.startTrade(signal)
                                }
                                .tint(.green)
                            }
                    }
                }
                
                // Active Trades Section
                Section("Active Trades") {
                    ForEach(signalMonitor.activeTrades) { trade in
                        TradeRowView(trade: trade)
                    }
                }
            }
            .navigationTitle("Trading Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Symbol") { }
                        Button("Refresh Data") { }
                        Button("Clear All") { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct TestSessionBanner: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Trading Test")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(AppConfig.Testing.nextTradingTestDate)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Spacer()
            Text("Open + Close Focus")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
        .padding([.horizontal, .top])
    }
}

struct CloseManagementCard: View {
    let title: String
    let warningTime: String
    let hardExitTime: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                timingColumn(label: "First Warning", value: warningTime)
                timingColumn(label: "Hard Exit", value: hardExitTime)
            }

            Text(note)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
    }

    private func timingColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Modern, clean market status view
struct MarketStatusView: View {
    let phase: MarketPhase
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Market Phase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(phase.displayName)
                        .font(.title2)
                        .bold()
                }
                Spacer()
                phaseIndicator
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
        .padding()
    }
    
    private var phaseIndicator: some View {
        Circle()
            .fill(phase.color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(phase.color.opacity(0.3), lineWidth: 4)
            )
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trade.symbol)
                    .font(.headline)
                StrategyBadge(strategy: trade.strategy)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("P/L: \(trade.unrealizedPnL, specifier: "%.2f")")
                    .foregroundColor(trade.unrealizedPnL >= 0 ? .green : .red)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
} 

struct SPYTradingDashboard: View {
    @StateObject private var viewModel = SPYDashboardViewModel()
    @ObservedObject var signalMonitor: SignalMonitor

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TestSessionBanner()
                        .padding(.horizontal)

                    spyMarketSnapshotSection

                    if let nextWindow = viewModel.nextWindow {
                        SPYWindowAlertCard(window: nextWindow.window, minutesUntil: nextWindow.minutesUntil)
                            .padding(.horizontal)
                    }

                    CloseManagementCard(
                        title: "SPY Close Management",
                        warningTime: AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime),
                        hardExitTime: AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalHardExitTime),
                        note: "We warn first into the close, then only force the exit later so extended-hours room stays available."
                    )
                    .padding(.horizontal)

                    if viewModel.hasManualData {
                        SPYSetupBoardCard(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    spyChecklistSection
                    spySignalsSection
                    spyTradesSection
                }
                .padding(.vertical)
            }
            .navigationTitle("SPY Trading")
        }
        .task {
            await viewModel.startMonitoring()
        }
    }

    private var spyMarketSnapshotSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SPY")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(viewModel.spyPrice, specifier: "%.2f")")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)

                    Text("\(viewModel.spyChangePercent, specifier: "%+.2f")%")
                        .font(.subheadline)
                        .foregroundColor(viewModel.spyChangePercent >= 0 ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 2)
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Context")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(viewModel.contextLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(viewModel.lastUpdateLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 2)
            )
        }
        .padding(.horizontal)
    }

    private var spyChecklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.blue)
                Text("SPY Focus")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                spyFocusRow(title: "Open Drive", detail: "9:35-10:05 AM. Needs arrow plus VWAP agreement and volume.")
                spyFocusRow(
                    title: "Close Drive",
                    detail: "3:30-\(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)). First warning at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)), extended hard exit at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalHardExitTime))."
                )
                spyFocusRow(title: "Risk Filter", detail: "High news now requires more volume before we promote a watch to an entry.")
            }
            .padding(.horizontal)
        }
    }

    private func spyFocusRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
    }

    private var spySignalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("SPY Signals")
                    .font(.headline)
                Spacer()
                Text("\(spySignals.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            if spySignals.isEmpty {
                Text("No active SPY signals yet. Use Manual Data Entry with SPY selected to drive this tab.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(spySignals) { signal in
                    SharedSignalRowView(signal: signal)
                        .padding(.horizontal)
                        .swipeActions {
                            Button("Trade") {
                                signalMonitor.startTrade(signal)
                            }
                            .tint(.green)
                        }
                }
            }
        }
    }

    private var spyTradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.green)
                Text("SPY Trades")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if spyTrades.isEmpty {
                Text("No active SPY trades")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(spyTrades) { trade in
                    TradeDetailCard(trade: trade)
                }
            }
        }
    }

    private var spySignals: [Signal] {
        signalMonitor.activeSignals.filter { $0.symbol == "SPY" }
    }

    private var spyTrades: [Trade] {
        signalMonitor.activeTrades.filter { $0.symbol == "SPY" }
    }
}

private struct SPYWindowAlertCard: View {
    let window: SPYFocusWindow
    let minutesUntil: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next SPY Window")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(window.displayName)
                    .font(.headline)
                Text(window.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(minutesUntil)m")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
    }
}

enum SPYFocusWindow {
    case open
    case close

    var displayName: String {
        switch self {
        case .open: return "Open Drive"
        case .close: return "Close Drive"
        }
    }

    var timeRange: String {
        switch self {
        case .open: return "9:35-10:05 AM"
        case .close: return "3:30-3:55 PM"
        }
    }
}

@MainActor
final class SPYDashboardViewModel: ObservableObject {
    @Published var spyPrice: Double = 0
    @Published var spyChangePercent: Double = 0
    @Published var nextWindow: (window: SPYFocusWindow, minutesUntil: Int)?
    @Published var hasManualData = false
    @Published private(set) var latestData: MarketData?

    private let marketData = MarketDataService.shared
    private var cancellables = Set<AnyCancellable>()

    var contextLabel: String {
        guard let data = latestData else { return "Waiting for SPY manual entry" }
        return "\(currentWindowLabel(for: data.timestamp)) • \(suggestedAction)"
    }

    var lastUpdateLabel: String {
        guard let data = latestData else { return "Enter SPY in Manual Data Entry" }
        return "Volume \(formattedVolumeMultiple(data.volumeMultiple)) • \(data.newsRisk.displayName) news risk"
    }

    var setupHeadline: String {
        guard let data = latestData else { return "Waiting for manual SPY feed" }

        if isVolumeReady(data) && isVWAPAligned(data) && data.hasArrowSignal {
            return "\(biasLabel(for: data)) ready when you are"
        }

        if data.hasArrowSignal && isVWAPAligned(data) {
            return "\(biasLabel(for: data)) watch only until volume firms up"
        }

        if data.hasArrowSignal {
            return "Arrow is live, but VWAP still needs to agree"
        }

        return "Watching for the next clean arrow into your focus window"
    }

    var setupSubheadline: String {
        guard let data = latestData else { return "The SPY tab will fill itself as soon as you post a manual entry." }
        return "\(focusWindowDescription(for: data.timestamp)) • Need \(formattedVolumeMultiple(requiredSPYVolumeMultiple(for: data))) for entry quality."
    }

    var setupMetrics: [SPYSetupMetric] {
        guard let data = latestData else { return [] }

        return [
            SPYSetupMetric(
                title: "Window",
                value: currentWindowLabel(for: data.timestamp),
                detail: focusWindowDescription(for: data.timestamp),
                color: .blue,
                systemImage: "clock"
            ),
            SPYSetupMetric(
                title: "Bias",
                value: biasLabel(for: data),
                detail: biasDetail(for: data),
                color: biasColor(for: data),
                systemImage: biasSystemImage(for: data)
            ),
            SPYSetupMetric(
                title: "VWAP",
                value: data.isAboveVWAP ? "Above VWAP" : "Below VWAP",
                detail: isVWAPAligned(data) ? "Aligned with arrow" : "Conflicts with arrow",
                color: isVWAPAligned(data) ? .green : .orange,
                systemImage: "waveform.path.ecg"
            ),
            SPYSetupMetric(
                title: "Volume",
                value: formattedVolumeMultiple(data.volumeMultiple),
                detail: "Need \(formattedVolumeMultiple(requiredSPYVolumeMultiple(for: data)))",
                color: isVolumeReady(data) ? .green : .orange,
                systemImage: "chart.bar.fill"
            ),
            SPYSetupMetric(
                title: "News",
                value: data.newsRisk.displayName,
                detail: data.isHighVolatility ? "VIX \(String(format: "%.1f", data.vix))" : "Volatility contained",
                color: newsColor(for: data),
                systemImage: "newspaper.fill"
            ),
            SPYSetupMetric(
                title: "Daily Move",
                value: String(format: "%+.2f%%", data.gapPercent),
                detail: "Price $\(String(format: "%.2f", data.currentPrice))",
                color: data.gapPercent >= 0 ? .green : .red,
                systemImage: "point.topleft.down.curvedto.point.bottomright.up"
            )
        ]
    }

    func startMonitoring() async {
        subscribe()
        updateNextWindow()
    }

    private func subscribe() {
        marketData.subscribeToMarketData(symbol: "SPY")
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] data in
                guard let self else { return }
                self.spyPrice = data.currentPrice
                self.spyChangePercent = data.gapPercent
                self.hasManualData = true
                self.latestData = data
                self.updateNextWindow()
            }
            .store(in: &cancellables)
    }

    private func updateNextWindow() {
        let now = Date()
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents(in: easternTimeZone, from: now)
        guard let hour = components.hour, let minute = components.minute else { return }

        let currentMinutes = hour * 60 + minute
        let windows: [(SPYFocusWindow, Int)] = [
            (.open, 9 * 60 + 35),
            (.close, 15 * 60 + 30)
        ]

        for (window, startMinutes) in windows where currentMinutes < startMinutes {
            nextWindow = (window, startMinutes - currentMinutes)
            return
        }

        nextWindow = nil
    }

    private func currentWindowLabel(for date: Date) -> String {
        switch date {
        case _ where date.isSPYOpenWindow:
            return "Open Drive Active"
        case _ where date.isSPYCloseWindow:
            return "Close Drive Active"
        default:
            return "Between Windows"
        }
    }

    private func focusWindowDescription(for date: Date) -> String {
        if date.isSPYOpenWindow {
            return "Open flow is active right now."
        }
        if date.isSPYCloseWindow {
            return "Close flow is active right now."
        }
        if let nextWindow {
            return "\(nextWindow.window.displayName) in \(nextWindow.minutesUntil)m."
        }
        return "Cash session focus is over, so alerts are now mostly exit management."
    }

    private var suggestedAction: String {
        guard let data = latestData else { return "manual feed offline" }

        if isVolumeReady(data) && isVWAPAligned(data) && data.hasArrowSignal {
            return "entry-grade setup"
        }
        if data.hasArrowSignal && isVWAPAligned(data) {
            return "watch-grade setup"
        }
        if data.hasArrowSignal {
            return "mixed setup"
        }
        return "waiting for arrow"
    }

    private func biasLabel(for data: MarketData) -> String {
        guard let direction = data.arrowDirection else {
            return "No Arrow Yet"
        }

        return direction == .bullish ? "Calls Bias" : "Puts Bias"
    }

    private func biasDetail(for data: MarketData) -> String {
        guard let direction = data.arrowDirection else {
            return "Need a fresh arrow to pick direction."
        }

        if direction == .bullish {
            return data.isAboveVWAP ? "Bullish arrow with VWAP support" : "Bullish arrow, but VWAP still overhead"
        }

        return data.isAboveVWAP ? "Bearish arrow, but price is still above VWAP" : "Bearish arrow with VWAP pressure"
    }

    private func biasColor(for data: MarketData) -> Color {
        guard let direction = data.arrowDirection else { return .secondary }
        return direction == .bullish ? .green : .red
    }

    private func biasSystemImage(for data: MarketData) -> String {
        guard let direction = data.arrowDirection else { return "scope" }
        return direction == .bullish ? "arrow.up.forward.circle.fill" : "arrow.down.forward.circle.fill"
    }

    private func isVWAPAligned(_ data: MarketData) -> Bool {
        guard let direction = data.arrowDirection else { return false }
        return direction == .bullish ? data.isAboveVWAP : !data.isAboveVWAP
    }

    private func requiredSPYVolumeMultiple(for data: MarketData) -> Double {
        var required = 1.5
        if data.newsRisk != .none {
            required *= data.newsRisk.volumeMultiplier
        }
        if data.isHighVolatility {
            required = max(required, 2.0)
        }
        return required
    }

    private func isVolumeReady(_ data: MarketData) -> Bool {
        data.volumeMultiple >= requiredSPYVolumeMultiple(for: data)
    }

    private func formattedVolumeMultiple(_ value: Double) -> String {
        String(format: "%.1fx avg", value)
    }

    private func newsColor(for data: MarketData) -> Color {
        switch data.newsRisk {
        case .none:
            return data.isHighVolatility ? .orange : .green
        case .moderate:
            return .orange
        case .high:
            return .red
        }
    }
}

struct SPYSetupMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let color: Color
    let systemImage: String
}

private struct SPYSetupBoardCard: View {
    let viewModel: SPYDashboardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scope")
                    .foregroundColor(.blue)
                Text("SPY Setup Board")
                    .font(.headline)
                Spacer()
            }

            Text(viewModel.setupHeadline)
                .font(.headline)

            Text(viewModel.setupSubheadline)
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.setupMetrics) { metric in
                    SPYSetupMetricCard(metric: metric)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)
        )
    }
}

private struct SPYSetupMetricCard: View {
    let metric: SPYSetupMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: metric.systemImage)
                    .foregroundColor(metric.color)
                Text(metric.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(metric.value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(metric.detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(metric.color.opacity(0.08))
        )
    }
}
