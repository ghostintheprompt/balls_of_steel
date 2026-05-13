import SwiftUI
import Combine

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @StateObject private var marketPulse = MarketPulse.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("lastMarketDataEntry") private var lastMarketDataEntryData: Data = Data()

    private var lastMarketDataEntry: MarketDataEntry? {
        guard !lastMarketDataEntryData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MarketDataEntry.self, from: lastMarketDataEntryData)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if horizontalSizeClass == .compact {
                            phoneDeskContent
                        } else {
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
                    }
                    .padding(horizontalSizeClass == .compact ? 16 : 20)
                }
            }
            .navigationTitle(horizontalSizeClass == .compact ? "Steel Desk" : "Steel Trading Desk")
            #if os(iOS)
            .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .inline : .large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(DesignSystem.secondaryColor)
                    }
                }
            }
        }
    }

    private var phoneDeskContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            PhoneDeskHeader(phase: marketPulse.currentPhase)
            PhoneStrategyRail(signalMonitor: signalMonitor, entry: lastMarketDataEntry)
            PhoneDeskReadout(
                signalCount: signalMonitor.activeSignals.count,
                tradeCount: signalMonitor.activeTrades.count,
                phase: marketPulse.currentPhase
            )
            activeSignalsSection
            activeTradesSection
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

private struct PhoneDeskHeader: View {
    let phase: MarketPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("STEEL DESK")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.0)
                    .foregroundColor(DesignSystem.primaryColor)
                Text("VXX / VWAP / WINDOW")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Read tape. Check rules. Execute elsewhere.")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(DesignSystem.panelStroke)

            HStack(spacing: 10) {
                PhoneStatusChip(title: "Phase", value: phase.displayName, accent: phase.color)
                PhoneStatusChip(title: "Mode", value: "Manual", accent: DesignSystem.secondaryColor)
            }
        }
        .deskPanel(glow: .clear, padding: 16)
    }
}

private struct PhoneStrategyRail: View {
    @ObservedObject var signalMonitor: SignalMonitor
    let entry: MarketDataEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeskSectionHeader(title: "VXX Sequence", systemImage: "checklist", accent: DesignSystem.primaryColor)

            VStack(spacing: 8) {
                NavigationLink {
                    ManualDataEntryView()
                } label: {
                    StrategyGateRow(
                        index: 1,
                        title: "Volume + window",
                        detail: state.volumeWindowDetail,
                        status: state.volumeWindowStatus,
                        systemImage: "slider.horizontal.3",
                        accent: DesignSystem.primaryColor
                    )
                }

                StrategyGateRow(
                    index: 2,
                    title: "Ratio",
                    detail: state.ratioDetail,
                    status: state.ratioStatus,
                    systemImage: "divide.circle",
                    accent: DesignSystem.warningColor
                )

                StrategyGateRow(
                    index: 3,
                    title: "VWAP / key level",
                    detail: state.levelDetail,
                    status: state.levelStatus,
                    systemImage: "scope",
                    accent: DesignSystem.secondaryColor
                )

                StrategyGateRow(
                    index: 4,
                    title: "Pattern now",
                    detail: state.patternDetail,
                    status: state.patternStatus,
                    systemImage: "candlestickchart",
                    accent: DesignSystem.bullishColor
                )

                StrategyDecisionRow(state: state, signalMonitor: signalMonitor)
            }
        }
    }

    private var state: VXXStrategyState {
        VXXStrategyState(entry: entry)
    }
}

private struct StrategyGateRow: View {
    let index: Int
    let title: String
    let detail: String
    let status: GateStatus
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Rectangle()
                .fill(status.color)
                .frame(width: 4)
                .clipShape(Capsule())

            Text("\(index)")
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
                .frame(width: 28, height: 28)
                .background(status.color.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text(detail)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: status.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(14)
        .frame(minHeight: 68)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status == .locked ? DesignSystem.panelTop.opacity(0.55) : DesignSystem.panelTop)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.panelStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StrategyDecisionRow: View {
    let state: VXXStrategyState
    @ObservedObject var signalMonitor: SignalMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: state.ready ? "checkmark.seal.fill" : "hand.raised.fill")
                    .foregroundColor(state.ready ? DesignSystem.bullishColor : DesignSystem.warningColor)
                Text(state.ready ? "CLEARED: EXECUTE ON BROKER" : "NOT CLEARED")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
            }

            Text(state.decisionDetail)
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            if state.ready {
                HStack(spacing: 10) {
                    NavigationLink {
                        PromptCoachView()
                    } label: {
                        Label("Prompt", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        ActiveTradesView(signalMonitor: signalMonitor)
                    } label: {
                        Label("Risk", systemImage: "shield.lefthalf.filled")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                NavigationLink {
                    ManualDataEntryView()
                } label: {
                    Label("Fix Tape", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .deskPanel(glow: .clear, padding: 16)
    }
}

private enum GateStatus: Equatable {
    case pass
    case fail
    case locked

    var icon: String {
        switch self {
        case .pass: return "checkmark.circle.fill"
        case .fail: return "xmark.circle.fill"
        case .locked: return "lock.fill"
        }
    }

    var color: Color {
        switch self {
        case .pass: return DesignSystem.bullishColor
        case .fail: return DesignSystem.dangerColor
        case .locked: return DesignSystem.mutedText
        }
    }
}

private struct VXXStrategyState {
    let entry: MarketDataEntry?

    var volumePass: Bool {
        guard let entry else { return false }
        return entry.volumePercent >= 200
    }

    var windowPass: Bool {
        guard let entry else { return false }
        return [.morning, .lunch, .powerHour, .institutional].contains(entry.timeWindow)
    }

    var volumeWindowPass: Bool {
        volumePass && windowPass
    }

    var ratioPass: Bool {
        guard let entry else { return false }
        return entry.instrument == .vxx && entry.ratio >= 1.45
    }

    var levelPass: Bool {
        guard let entry else { return false }
        return entry.keyLevelConfirmed
    }

    var patternPass: Bool {
        guard let entry else { return false }
        return entry.patternConfirmed
    }

    var ready: Bool {
        volumeWindowPass && ratioPass && levelPass && patternPass
    }

    var volumeWindowStatus: GateStatus {
        guard entry != nil else { return .fail }
        return volumeWindowPass ? .pass : .fail
    }

    var ratioStatus: GateStatus {
        guard volumeWindowPass else { return .locked }
        return ratioPass ? .pass : .fail
    }

    var levelStatus: GateStatus {
        guard volumeWindowPass && ratioPass else { return .locked }
        return levelPass ? .pass : .fail
    }

    var patternStatus: GateStatus {
        guard volumeWindowPass && ratioPass && levelPass else { return .locked }
        return patternPass ? .pass : .fail
    }

    var volumeWindowDetail: String {
        guard let entry else { return "Start here. Enter current VXX tape." }
        if !volumePass && !windowPass {
            return "Need volume >200% and valid VXX window. Now: \(Int(entry.volumePercent))%, \(entry.timeWindow.displayName)."
        }
        if !volumePass {
            return "Volume is \(Int(entry.volumePercent))%. Need >200% before anything else."
        }
        if !windowPass {
            return "\(entry.timeWindow.displayName) is not a VXX window. Wait."
        }
        return "Volume \(Int(entry.volumePercent))% inside \(entry.timeWindow.displayName)."
    }

    var ratioDetail: String {
        guard let entry else { return "Locked until tape is entered." }
        if !volumeWindowPass { return "Locked until volume and time pass." }
        return ratioPass
            ? "Ratio \(String(format: "%.2f", entry.ratio)) passes. \(entry.ratioTier)."
            : "Ratio \(String(format: "%.2f", entry.ratio)) fails. Need >1.45."
    }

    var levelDetail: String {
        guard volumeWindowPass && ratioPass else { return "Locked until ratio passes." }
        guard let entry else { return "Locked until tape is entered." }
        return levelPass
            ? "Key level confirmed. VWAP read: \(entry.vwapPosition.displayName)."
            : "No key level. Need VWAP, 50 SMA, round number, prior high, or support break."
    }

    var patternDetail: String {
        guard volumeWindowPass && ratioPass && levelPass else { return "Locked until level passes." }
        guard let entry else { return "Locked until tape is entered." }
        if patternPass {
            return entry.arrowSignal == .none ? "Rejection pattern confirmed." : "Pattern confirmed with \(entry.arrowSignal.displayName)."
        }
        return "Wait for rejection candle. No early entry."
    }

    var decisionDetail: String {
        guard let entry else { return "No tape entered. Start with Tape." }
        if ready {
            return "All five are live. Size by ratio: \(entry.ratioTier). Execute on broker. Time stop still rules."
        }
        return "One failed gate means skip or wait. Do not average your way into a trade."
    }
}

private struct PhoneDeskReadout: View {
    let signalCount: Int
    let tradeCount: Int
    let phase: MarketPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeskSectionHeader(title: "Now", systemImage: "gauge.with.dots.needle.33percent", accent: phase.color)
            HStack(spacing: 10) {
                PhoneStatusChip(title: "Signals", value: "\(signalCount)", accent: DesignSystem.warningColor)
                PhoneStatusChip(title: "Risk", value: "\(tradeCount)", accent: DesignSystem.dangerColor)
            }
        }
    }
}

private struct PhoneStatusChip: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(0.8)
                .foregroundColor(DesignSystem.mutedText)
            Text(value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TestSessionBanner: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if horizontalSizeClass == .compact {
                compactHeader
            } else {
                expandedHeader
            }

            Text("Manual SPY/VXX discipline desk: enter context, check the playbook, manage risk, get out clean.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    sessionPill("Manual Only")
                    sessionPill("SPY / VXX")
                    sessionPill("Risk First")
                }

                VStack(alignment: .leading, spacing: 8) {
                    sessionPill("Manual Only")
                    sessionPill("SPY / VXX")
                    sessionPill("Risk First")
                }
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.12), padding: 20)
    }

    private var compactHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            SteelDeskMark(size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("STEEL DESK")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.primaryColor)
                Text(AppConfig.Testing.nextTradingTestDate)
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            Spacer(minLength: 0)
        }
    }

    private var expandedHeader: some View {
        HStack(alignment: .top) {
            HStack(alignment: .center, spacing: 16) {
                SteelDeskMark(size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("STEEL TRADING DESK")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.5)
                        .foregroundColor(DesignSystem.primaryColor)
                    Text(AppConfig.Testing.nextTradingTestDate)
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                sessionTag("LOCAL FIRST", color: DesignSystem.primaryColor)
                sessionTag("NO AUTOTRADE", color: DesignSystem.secondaryColor)
            }
        }
    }

    private func sessionTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DesignSystem.Typography.labelFont)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .overlay(
                Capsule().stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(color)
    }

    private func sessionPill(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DesignSystem.Typography.labelFont)
            .tracking(1.0)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                DeskPulseDot(accent: accent, size: 6)
                Text(title.uppercased())
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.mutedText)
            }
            Text(value)
                .font(DesignSystem.Typography.titleFont)
                .fontWeight(.black)
                .foregroundColor(DesignSystem.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: accent.opacity(0.15), padding: 16)
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
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MARKET PHASE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.5)
                    .foregroundColor(DesignSystem.mutedText)
                Text(phase.displayName)
                    .font(DesignSystem.Typography.titleFont)
                    .fontWeight(.black)
                    .foregroundColor(DesignSystem.primaryText)
                Text("Good tape pays. Dead tape wastes attention.")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .italic()
            }

            Spacer()

            DeskPulseDot(accent: phase.color, size: 16)
        }
        .deskPanel(glow: phase.color.opacity(0.18), padding: 20)
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        InfoCard(glow: pnlColor.opacity(0.18)) {
            HStack(alignment: .center, spacing: 16) {
                DeskSignalGlyph(symbol: trade.symbol, accent: pnlColor, secondaryAccent: directionColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text(trade.symbol)
                        .font(DesignSystem.Typography.titleFont)
                        .fontWeight(.black)
                        .foregroundColor(DesignSystem.primaryText)
                    StrategyBadge(strategy: trade.strategy)
                    Text(trade.direction.optionLabel)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        DeskPulseDot(accent: pnlColor, size: 6)
                        Text("LIVE P/L")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.2)
                            .foregroundColor(DesignSystem.mutedText)
                    }
                    Text(String(format: "$%.2f", trade.unrealizedPnL / 100))
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(pnlColor)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        DeskMeterBar(value: progressToTarget, accent: pnlColor)
                            .frame(width: 100)
                        Text("\(progressToTarget * 100, specifier: "%.0f")% TO TARGET")
                            .font(DesignSystem.Typography.labelFont)
                            .foregroundColor(DesignSystem.mutedText)
                    }
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
                    .tracking(1.5)
                    .foregroundColor(DesignSystem.primaryColor)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("$\(viewModel.spyPrice, specifier: "%.2f")")
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)

                    Text("\(viewModel.spyChangePercent, specifier: "%+.2f")%")
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(viewModel.spyChangePercent >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                }

                Text("Respect the tape, not the story.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: viewModel.spyChangePercent >= 0 ? DesignSystem.bullishColor.opacity(0.18) : DesignSystem.bearishColor.opacity(0.18), padding: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("CONTEXT")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.5)
                    .foregroundColor(DesignSystem.primaryColor)

                Text(viewModel.contextLabel)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)

                Text(viewModel.lastUpdateLabel)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: DesignSystem.primaryColor.opacity(0.15), padding: 20)
        }
        .padding(.horizontal)
    }

    private var spyChecklistSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            DeskSectionHeader(title: "SPY Discipline", systemImage: "scope", accent: DesignSystem.primaryColor)
            .padding(.horizontal)

            VStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.5)
                .foregroundColor(DesignSystem.primaryText)
            Text(detail)
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.10), padding: 16)
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
        return "\(currentWindowLabel(for: data.timestamp)) - \(suggestedAction)"
    }

    var lastUpdateLabel: String {
        guard let data = latestData else { return "Enter SPY in Manual Data Entry" }
        return "Volume \(formattedVolumeMultiple(data.volumeMultiple)) - \(data.newsRisk.displayName) news risk"
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
        return "\(focusWindowDescription(for: data.timestamp)) - Need \(formattedVolumeMultiple(requiredSPYVolumeMultiple(for: data))) for entry quality."
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
