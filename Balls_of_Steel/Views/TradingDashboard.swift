import SwiftUI
import Combine

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @StateObject private var marketPulse = MarketPulse.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        TestSessionBanner()
                        MarketStatusView(phase: marketPulse.currentPhase)
                        DashboardPulseStrip(
                            signalCount: signalMonitor.activeSignals.count,
                            tradeCount: signalMonitor.activeTrades.count,
                            phase: marketPulse.currentPhase
                        )

                        activeSignalsSection
                        activeTradesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Balls of Steel")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Symbol") { }
                        Button("Refresh Data") { }
                        Button("Clear All") { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DesignSystem.primaryColor)
                    }
                }
            }
        }
    }

    private var activeSignalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeskSectionHeader(title: "Signals Live", systemImage: "bolt.fill", accent: DesignSystem.warningColor)

            if signalMonitor.activeSignals.isEmpty {
                InfoCard {
                    Text("Nothing clean yet. Good. Manufactured entries are how people donate.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(signalMonitor.activeSignals) { signal in
                    SharedSignalRowView(signal: signal)
                        .swipeActions {
                            Button("Trade") {
                                signalMonitor.startTrade(signal)
                            }
                            .tint(DesignSystem.successColor)
                        }
                }
            }
        }
    }

    private var activeTradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeskSectionHeader(title: "Active Risk", systemImage: "flame.fill", accent: DesignSystem.dangerColor)

            if signalMonitor.activeTrades.isEmpty {
                InfoCard {
                    Text("No live risk. Keep it that way until the tape deserves it.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(signalMonitor.activeTrades) { trade in
                    TradeRowView(trade: trade)
                }
            }
        }
    }
}

struct TestSessionBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(alignment: .center, spacing: 14) {
                    BallsOfSteelMark(size: 62)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TEST SESSION")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.2)
                            .foregroundColor(DesignSystem.mutedText)
                        Text(AppConfig.Testing.nextTradingTestDate)
                            .font(DesignSystem.Typography.heroFont)
                            .foregroundColor(DesignSystem.primaryText)
                    }
                }

                Spacer()

                Text("OPEN FIRST")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .foregroundColor(DesignSystem.primaryColor)
            }

            Text("Open first. Close honest. Small size. If the chart wants aggression, it can earn it.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)

            HStack(spacing: 8) {
                sessionPill("SPY + VXX")
                sessionPill("Extended Hours Aware")
                sessionPill("No Fantasy Fills")
            }
        }
        .deskPanel(glow: DesignSystem.edgeGlow.opacity(0.16))
    }

    private func sessionPill(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DesignSystem.Typography.labelFont)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.04))
            .clipShape(Capsule())
            .foregroundColor(DesignSystem.primaryText)
    }
}

private struct DashboardPulseStrip: View {
    let signalCount: Int
    let tradeCount: Int
    let phase: MarketPhase

    var body: some View {
        HStack(spacing: 12) {
            PulseTile(title: "Setups", value: "\(signalCount)", accent: DesignSystem.warningColor)
            PulseTile(title: "Risk", value: "\(tradeCount)", accent: DesignSystem.dangerColor)
            PulseTile(title: "Now", value: phase.displayName, accent: phase.color)
        }
    }
}

private struct PulseTile: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                DeskPulseDot(accent: accent, size: 7)
                Text(title.uppercased())
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)
            }
            Text(value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: accent.opacity(0.12), padding: 14)
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
                    .foregroundColor(DesignSystem.warningColor)
                Text(title)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Spacer()
            }

            HStack(spacing: 16) {
                timingColumn(label: "First Warning", value: warningTime)
                timingColumn(label: "Hard Exit", value: hardExitTime)
            }

            Text(note)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.12))
    }

    private func timingColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(0.8)
                .foregroundColor(DesignSystem.mutedText)
            Text(value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MarketStatusView: View {
    let phase: MarketPhase
    
    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Market Phase".uppercased())
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .foregroundColor(DesignSystem.mutedText)
                Text(phase.displayName)
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text("Good tape pays. Dead tape wastes attention.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Spacer()

            phaseIndicator
        }
        .deskPanel(glow: phase.color.opacity(0.12))
    }
    
    private var phaseIndicator: some View {
        DeskPulseDot(accent: phase.color, size: 14)
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        InfoCard(glow: pnlColor.opacity(0.16)) {
            HStack(alignment: .center, spacing: 12) {
                DeskSignalGlyph(symbol: trade.symbol, accent: pnlColor, secondaryAccent: directionColor)

                VStack(alignment: .leading, spacing: 8) {
                    Text(trade.symbol)
                        .font(DesignSystem.Typography.titleFont)
                        .foregroundColor(DesignSystem.primaryText)
                    StrategyBadge(strategy: trade.strategy)
                    Text(trade.direction.optionLabel)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        DeskPulseDot(accent: pnlColor, size: 7)
                        Text("LIVE P/L")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(0.8)
                            .foregroundColor(DesignSystem.mutedText)
                    }
                    Text(String(format: "$%.2f", trade.unrealizedPnL / 100))
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(pnlColor)
                    DeskMeterBar(value: progressToTarget, accent: pnlColor)
                        .frame(width: 86)
                }
            }
        }
    }

    private var pnlColor: Color {
        trade.unrealizedPnL >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private var directionColor: Color {
        trade.direction == .bullish ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private var progressToTarget: Double {
        let denominator = abs(trade.target - trade.entry)
        guard denominator > 0 else { return 0 }
        let moved = trade.direction == .bullish ? (trade.currentPrice - trade.entry) : (trade.entry - trade.currentPrice)
        return min(max(moved / denominator, 0), 1)
    }
}

struct SPYTradingDashboard: View {
    @StateObject private var viewModel = SPYDashboardViewModel()
    @ObservedObject var signalMonitor: SignalMonitor

    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

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
                            note: "Warn first into the close. If you are still in it later, that should be a decision, not an accident."
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
            }
            .navigationTitle("SPY Desk")
        }
        .task {
            await viewModel.startMonitoring()
        }
    }

    private var spyMarketSnapshotSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SPY TAPE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .foregroundColor(DesignSystem.mutedText)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$\(viewModel.spyPrice, specifier: "%.2f")")
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)

                    Text("\(viewModel.spyChangePercent, specifier: "%+.2f")%")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(viewModel.spyChangePercent >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                }

                Text("Respect the tape, not the story.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: viewModel.spyChangePercent >= 0 ? DesignSystem.bullishColor.opacity(0.16) : DesignSystem.bearishColor.opacity(0.16))

            VStack(alignment: .leading, spacing: 8) {
                Text("CONTEXT")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .foregroundColor(DesignSystem.mutedText)

                Text(viewModel.contextLabel)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)

                Text(viewModel.lastUpdateLabel)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: DesignSystem.primaryColor.opacity(0.12))
        }
        .padding(.horizontal)
    }

    private var spyChecklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeskSectionHeader(title: "SPY Discipline", systemImage: "scope", accent: DesignSystem.primaryColor)
            .padding(.horizontal)

            VStack(spacing: 10) {
                spyFocusRow(title: "Open Drive", detail: "9:35-10:05. Arrow first. VWAP agreement. Volume there. No begging.")
                spyFocusRow(
                    title: "Close Drive",
                    detail: "3:30-\(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)). Warning at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)). Hard exit later at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalHardExitTime)) if you are still managing."
                )
                spyFocusRow(title: "News Filter", detail: "Heavy news can pay. It still has to prove it on volume before it graduates from watch to entry.")
            }
            .padding(.horizontal)
        }
    }

    private func spyFocusRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1)
                .foregroundColor(DesignSystem.primaryText)
            Text(detail)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.08), padding: 14)
    }

    private var spySignalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DeskSectionHeader(title: "SPY Signals", systemImage: "bolt.fill", accent: DesignSystem.warningColor)
                Spacer()
                DeskCountBadge(value: "\(spySignals.count)", accent: DesignSystem.warningColor)
            }
            .padding(.horizontal)

            if spySignals.isEmpty {
                InfoCard {
                    Text("Nothing live. If Manual is quiet, this tab should be quiet.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
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
                DeskSectionHeader(title: "SPY Risk", systemImage: "flame.fill", accent: DesignSystem.dangerColor)
                Spacer()
                DeskCountBadge(value: "\(spyTrades.count)", accent: DesignSystem.dangerColor)
            }
            .padding(.horizontal)

            if spyTrades.isEmpty {
                InfoCard {
                    Text("No SPY risk on. That is a position too.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
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
                Text("NEXT SPY WINDOW")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)
                Text(window.displayName)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text(window.timeRange)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(minutesUntil)m")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.warningColor)
                Text(minutesUntil > 0 ? "until it matters" : "window live")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.14))
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
        case _ where date.isAfternoonFlexWindow:
            return "Afternoon Flex Active"
        default:
            return "Between Windows"
        }
    }

    private func focusWindowDescription(for date: Date) -> String {
        if date.isSPYOpenWindow {
            return "Open flow is active right now."
        }
        if date.isAfternoonFlexWindow && !date.isSPYCloseWindow {
            return "Afternoon tape is tradable now. Good setups can build before the close if volume earns it."
        }
        if date.isSPYCloseWindow {
            return "Close flow is active right now."
        }
        if let nextWindow {
            return "\(nextWindow.window.displayName) in \(nextWindow.minutesUntil)m."
        }
        return "Outside the main windows now. Stay selective or manage what is already on."
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
                    .foregroundColor(DesignSystem.primaryColor)
                Text("SPY Bias Board")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Spacer()
            }

            Text(viewModel.setupHeadline)
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.primaryText)

            Text(viewModel.setupSubheadline)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.setupMetrics) { metric in
                    SPYSetupMetricCard(metric: metric)
                }
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.12))
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
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Text(metric.value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)

            Text(metric.detail)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: metric.color.opacity(0.12), padding: 14)
    }
}
