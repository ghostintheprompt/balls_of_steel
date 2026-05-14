import SwiftUI
import Combine

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    var openTape: (() -> Void)? = nil
    var openRisk: (() -> Void)? = nil
    @StateObject private var marketPulse = MarketPulse.shared
    @StateObject private var timeManager = TimeManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("lastMarketDataEntry") private var lastMarketDataEntryData: Data = Data()

    private var lastMarketDataEntry: MarketDataEntry? {
        guard !lastMarketDataEntryData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MarketDataEntry.self, from: lastMarketDataEntryData)
    }

    private var phoneStrategyState: VXXStrategyState {
        VXXStrategyState(entry: lastMarketDataEntry)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                if horizontalSizeClass == .compact {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            phoneDeskContent
                        }
                        .padding(16)
                    }
                } else {
                    MacTerminalView(
                        signalMonitor: signalMonitor,
                        marketPulse: marketPulse,
                        entry: lastMarketDataEntry,
                        state: phoneStrategyState
                    )
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
                            .foregroundColor(DesignSystem.amber)
                    }
                }
            }
        }
    }

    @State private var selectedPhoneGate: PhoneGate?

    private var phoneDeskContent: some View {
        Group {
            if currentDeskState.isTakeover {
                PhoneHardExitTakeover(
                    signalMonitor: signalMonitor,
                    state: phoneStrategyState,
                    openRisk: openRisk
                )
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    PhoneTickerStrip(entry: lastMarketDataEntry, phase: marketPulse.currentPhase)
                    PhoneCommandCard(state: phoneStrategyState, signalMonitor: signalMonitor, openTape: openTape, openRisk: openRisk)
                    PhoneStrategyRail(entry: lastMarketDataEntry, openTape: openTape, onSelectGate: { selectedPhoneGate = $0 })
                    PhoneMiniChart(symbol: lastMarketDataEntry?.instrument ?? .vxx)
                    PhoneClockFooter()

                    if !signalMonitor.activeTrades.isEmpty {
                        activeTradesSection
                    }
                }
                .sheet(item: $selectedPhoneGate) { gate in
                    PhoneGateDetailSheet(gate: gate, state: phoneStrategyState, entry: lastMarketDataEntry, openTape: openTape)
                }
            }
        }
    }

    @MainActor
    private var currentDeskState: DeskState {
        DeskState.current(
            timeManager: timeManager,
            openPositions: signalMonitor.activeTrades.count
        )
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
                Text("VXX / VIX / VWAP")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Find the entry. Skip the rest. Execute on broker.")
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

private struct PhoneCommandCard: View {
    let state: VXXStrategyState
    @ObservedObject var signalMonitor: SignalMonitor
    let openTape: (() -> Void)?
    let openRisk: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT MOVE")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.mutedText)
                    Text(state.commandTitle)
                        .font(.system(size: 31, weight: .black, design: .default))
                        .foregroundColor(state.commandColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(state.commandDetail)
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: state.commandIcon)
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(state.commandColor)
                    .frame(width: 42, height: 42)
                    .background(state.commandColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }

            if state.ready {
                HStack(spacing: 10) {
                    NavigationLink {
                        PromptCoachView()
                    } label: {
                        Label("Prompt", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if let openRisk {
                        Button(action: openRisk) {
                            Label("Risk", systemImage: "shield.lefthalf.filled")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        NavigationLink {
                            ActiveTradesView(signalMonitor: signalMonitor)
                        } label: {
                            Label("Risk", systemImage: "shield.lefthalf.filled")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                if let openTape {
                    Button(action: openTape) {
                        Label(state.primaryActionTitle, systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    NavigationLink {
                        ManualDataEntryView()
                    } label: {
                        Label(state.primaryActionTitle, systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .deskPanel(glow: .clear, padding: 16)
    }
}

private struct PhoneTapeSnapshot: View {
    let entry: MarketDataEntry?
    let state: VXXStrategyState
    let openTape: (() -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeskSectionHeader(title: "Current Tape", systemImage: "rectangle.and.text.magnifyingglass", accent: DesignSystem.secondaryColor)

            if let entry {
                LazyVGrid(columns: columns, spacing: 8) {
                    TapeMetric(title: entry.instrument.displayName, value: String(format: "$%.2f", entry.price), accent: DesignSystem.primaryColor)
                    TapeMetric(title: "Volume", value: "\(Int(entry.volumePercent))%", accent: state.volumePass ? DesignSystem.bullishColor : DesignSystem.dangerColor)
                    TapeMetric(title: "Ratio", value: entry.instrument == .vxx ? String(format: "%.2f", entry.ratio) : "N/A", accent: state.ratioStatus.color)
                    TapeMetric(title: "Window", value: entry.timeWindow.shortName, accent: state.windowPass ? DesignSystem.bullishColor : DesignSystem.dangerColor)
                    TapeMetric(title: "VWAP", value: entry.vwapPosition.shortName, accent: state.levelStatus.color)
                    TapeMetric(title: "Pattern", value: entry.patternConfirmed ? "YES" : "NO", accent: state.patternStatus.color)
                }

                HStack {
                    Text("Posted \(entry.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    tapeControl(title: "Update")
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No tape posted yet.")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
                    Text("Start with VXX, VIX, volume, VWAP, level, pattern, and window.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                    tapeControl(title: "Open Tape", fill: true)
                        .buttonStyle(.bordered)
                }
            }
        }
        .deskPanel(glow: .clear, padding: 14)
    }

    @ViewBuilder
    private func tapeControl(title: String, fill: Bool = false) -> some View {
        if let openTape {
            Button(action: openTape) {
                Label(title, systemImage: "slider.horizontal.3")
                    .font(fill ? DesignSystem.Typography.headlineFont : DesignSystem.Typography.labelFont)
                    .frame(maxWidth: fill ? .infinity : nil)
            }
        } else {
            NavigationLink {
                ManualDataEntryView()
            } label: {
                Label(title, systemImage: "slider.horizontal.3")
                    .font(fill ? DesignSystem.Typography.headlineFont : DesignSystem.Typography.labelFont)
                    .frame(maxWidth: fill ? .infinity : nil)
            }
        }
    }
}

private struct TapeMetric: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(0.8)
                .foregroundColor(DesignSystem.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(10)
        .background(accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

private struct PhoneStrategyRail: View {
    let entry: MarketDataEntry?
    let openTape: (() -> Void)?

    var onSelectGate: ((PhoneGate) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ORDER OF ATTACK")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
            }

            VStack(spacing: 8) {
                tapeGateButton

                gateButton(.ratio) {
                    StrategyGateRow(
                        index: 2,
                        title: "Ratio",
                        detail: state.ratioDetail,
                        status: state.ratioStatus,
                        systemImage: "divide.circle",
                        accent: DesignSystem.amber,
                        isBlocker: blockerIndex == 2
                    )
                }

                gateButton(.level) {
                    StrategyGateRow(
                        index: 3,
                        title: "VWAP / key level",
                        detail: state.levelDetail,
                        status: state.levelStatus,
                        systemImage: "scope",
                        accent: DesignSystem.steel,
                        isBlocker: blockerIndex == 3
                    )
                }

                gateButton(.pattern) {
                    StrategyGateRow(
                        index: 4,
                        title: "Pattern now",
                        detail: state.patternDetail,
                        status: state.patternStatus,
                        systemImage: "candlestickchart",
                        accent: DesignSystem.long,
                        isBlocker: blockerIndex == 4
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func gateButton<Content: View>(_ gate: PhoneGate, @ViewBuilder content: () -> Content) -> some View {
        if let onSelectGate {
            Button { onSelectGate(gate) } label: { content() }
                .buttonStyle(.plain)
        } else {
            content()
        }
    }

    @ViewBuilder
    private var tapeGateButton: some View {
        let row = StrategyGateRow(
            index: 1,
            title: "Volume + window",
            detail: state.volumeWindowDetail,
            status: state.volumeWindowStatus,
            systemImage: "slider.horizontal.3",
            accent: DesignSystem.amber,
            isBlocker: blockerIndex == 1
        )

        if let openTape {
            Button(action: openTape) {
                row
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                ManualDataEntryView()
            } label: {
                row
            }
        }
    }

    private var blockerIndex: Int? { state.firstFailingGateIndex }

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
    var isBlocker: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Rectangle()
                .fill(isBlocker ? DesignSystem.amber : status.color)
                .frame(width: isBlocker ? 4 : 3)

            Text(String(format: "%02d", index))
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.muted)
                .frame(width: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title.uppercased())
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(status == .pass ? DesignSystem.long : (status == .fail ? DesignSystem.short : DesignSystem.text2))
                    if isBlocker {
                        Text("BLOCKER")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.4)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.amber)
                    }
                }
                Text(detail)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: status.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
        .overlay(
            Rectangle()
                .stroke(isBlocker ? DesignSystem.amber.opacity(0.5) : DesignSystem.hairline, lineWidth: 1)
        )
    }

    private var rowBackground: Color {
        if isBlocker { return DesignSystem.amber.opacity(0.06) }
        if status == .locked { return DesignSystem.bg1 }
        return DesignSystem.panel
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
        return entry.timeWindow.isVXXEntryWindow
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

    /// 1...4 if there is a blocker (first failing gate), nil if all pass or no entry.
    var firstFailingGateIndex: Int? {
        guard entry != nil else { return 1 }
        if !volumeWindowPass { return 1 }
        if !ratioPass { return 2 }
        if !levelPass { return 3 }
        if !patternPass { return 4 }
        return nil
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
        if entry.instrument != .vxx { return "This desk is for VXX. Switch the tape to VXX." }
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

    var commandTitle: String {
        guard let entry else { return "ENTER TAPE" }
        if entry.instrument != .vxx { return "SWITCH TO VXX" }
        if ready { return "CLEARED" }
        if !volumeWindowPass { return "NO TRADE" }
        if !ratioPass { return "NO TRADE" }
        if !levelPass { return "WAIT LEVEL" }
        if !patternPass { return "WAIT PATTERN" }
        return "WAIT"
    }

    var commandDetail: String {
        guard entry != nil else {
            return "Post the current VXX read before judging anything."
        }
        if ready {
            return decisionDetail
        }
        if !volumeWindowPass {
            return volumeWindowDetail
        }
        if !ratioPass {
            return ratioDetail
        }
        if !levelPass {
            return levelDetail
        }
        if !patternPass {
            return patternDetail
        }
        return decisionDetail
    }

    var commandColor: Color {
        if ready { return DesignSystem.bullishColor }
        guard entry != nil else { return DesignSystem.primaryColor }
        if !volumeWindowPass || !ratioPass { return DesignSystem.dangerColor }
        return DesignSystem.warningColor
    }

    var commandIcon: String {
        if ready { return "checkmark.seal.fill" }
        guard entry != nil else { return "slider.horizontal.3" }
        if !volumeWindowPass || !ratioPass { return "xmark.octagon.fill" }
        return "clock.badge.exclamationmark"
    }

    var primaryActionTitle: String {
        entry == nil ? "Enter Tape" : "Fix Tape"
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
            RoundedRectangle(cornerRadius: 2)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 2))
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
            .clipShape(RoundedRectangle(cornerRadius: 2))
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
                            .tint(DesignSystem.long)
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
                color: isVWAPAligned(data) ? DesignSystem.long : DesignSystem.amber,
                systemImage: "waveform.path.ecg"
            ),
            SPYSetupMetric(
                title: "Volume",
                value: formattedVolumeMultiple(data.volumeMultiple),
                detail: "Need \(formattedVolumeMultiple(requiredSPYVolumeMultiple(for: data)))",
                color: isVolumeReady(data) ? DesignSystem.long : DesignSystem.amber,
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
                color: data.gapPercent >= 0 ? DesignSystem.long : DesignSystem.short,
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
        guard let direction = data.arrowDirection else { return DesignSystem.steel }
        return direction == .bullish ? DesignSystem.long : DesignSystem.short
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
            return data.isHighVolatility ? DesignSystem.amber : DesignSystem.long
        case .moderate:
            return DesignSystem.amber
        case .high:
            return DesignSystem.short
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

// MARK: - Mac Single-Window Terminal (Phase 3)
//
// Three-column boiler-room layout: ticker strip / left rail / chart / right rail / status.
// The chart center is a placeholder until Phase 5 wires the TradingView WKWebView.

private struct MacTerminalView: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @ObservedObject var marketPulse: MarketPulse
    let entry: MarketDataEntry?
    let state: VXXStrategyState

    @State private var showingTapeSheet = false
    @State private var showingPromptSheet = false

    var body: some View {
        VStack(spacing: 0) {
            TickerStripView(entry: entry, marketPulse: marketPulse)

            HStack(spacing: 0) {
                LeftRailView(state: state, marketPulse: marketPulse)
                    .frame(width: 240)
                    .frame(maxHeight: .infinity, alignment: .top)

                Rectangle()
                    .fill(DesignSystem.hairline)
                    .frame(width: 1)

                ChartCenterView(symbol: entry?.instrument ?? .vxx)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(DesignSystem.hairline)
                    .frame(width: 1)

                RightRailView(
                    state: state,
                    entry: entry,
                    signalMonitor: signalMonitor,
                    onEditTape: { showingTapeSheet = true },
                    onSecondRead: { showingPromptSheet = true }
                )
                .frame(width: 320)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity)

            StatusFooterView(marketPulse: marketPulse, entry: entry)
        }
        .background(DesignSystem.bg)
        .sheet(isPresented: $showingTapeSheet) {
            ManualDataEntryView()
        }
        .sheet(isPresented: $showingPromptSheet) {
            PromptCoachView()
        }
    }
}

// MARK: - Ticker Strip

private struct TickerStripView: View {
    let entry: MarketDataEntry?
    @ObservedObject var marketPulse: MarketPulse

    var body: some View {
        HStack(spacing: 0) {
            tickerCell("VXX", value: priceText, accent: DesignSystem.text)
            divider
            tickerCell("VIX", value: vixText, accent: DesignSystem.text)
            divider
            tickerCell("R", value: ratioText, accent: ratioAccent)
            divider
            tickerCell("VWAP", value: vwapText, accent: DesignSystem.vwap)
            divider
            tickerCell("VOL", value: volText, accent: volAccent)
            divider
            tickerCell("PHASE", value: marketPulse.currentPhase.displayName.uppercased(), accent: DesignSystem.amber)
            Spacer(minLength: 0)
        }
        .frame(height: 34)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle()
                .fill(DesignSystem.hairline)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignSystem.hairline)
            .frame(width: 1, height: 18)
    }

    private func tickerCell(_ label: String, value: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            Text(value)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(accent)
        }
        .padding(.horizontal, 12)
    }

    private var priceText: String {
        guard let entry, entry.price > 0 else { return "—" }
        return String(format: "%.2f", entry.price)
    }

    private var vixText: String {
        guard let entry, entry.vixLevel > 0 else { return "—" }
        return String(format: "%.2f", entry.vixLevel)
    }

    private var ratioText: String {
        guard let entry, entry.instrument == .vxx, entry.ratio > 0 else { return "—" }
        return String(format: "%.3f", entry.ratio)
    }

    private var ratioAccent: Color {
        guard let entry, entry.instrument == .vxx, entry.ratio > 0 else { return DesignSystem.muted }
        if entry.ratio >= 1.55 { return DesignSystem.long }
        if entry.ratio >= 1.45 { return DesignSystem.amber }
        return DesignSystem.short
    }

    private var vwapText: String {
        guard let entry else { return "—" }
        return entry.vwapPosition.shortName
    }

    private var volText: String {
        guard let entry else { return "—" }
        return "\(Int(entry.volumePercent))%"
    }

    private var volAccent: Color {
        guard let entry else { return DesignSystem.muted }
        if entry.volumePercent >= 300 { return DesignSystem.long }
        if entry.volumePercent >= 200 { return DesignSystem.amber }
        return DesignSystem.short
    }
}

// MARK: - Left Rail

private struct LeftRailView: View {
    let state: VXXStrategyState
    @ObservedObject var marketPulse: MarketPulse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            railHeader("STEEL DESK")
                .padding(.top, 12)
                .padding(.horizontal, 12)

            Text("VXX / VIX / VWAP")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.text2)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

            railSection("ORDER OF ATTACK")
            VStack(spacing: 1) {
                gateRow(1, "VOL + WINDOW", state.volumeWindowDetail, status: state.volumeWindowStatus)
                gateRow(2, "RATIO", state.ratioDetail, status: state.ratioStatus)
                gateRow(3, "VWAP / LEVEL", state.levelDetail, status: state.levelStatus)
                gateRow(4, "PATTERN", state.patternDetail, status: state.patternStatus)
            }
            .padding(.bottom, 14)

            railSection("TODAY · WINDOWS")
            VStack(alignment: .leading, spacing: 2) {
                windowRow("09:35-10:05", "Open Drive")
                windowRow("09:50-10:15", "Morning Fade")
                windowRow("12:20-12:40", "Lunch Window")
                windowRow("15:10-15:25", "Power Hour")
                windowRow("15:45-16:10", "Institutional", highlight: true)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)

            railSection("RISK BUDGET")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("DAILY")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.muted)
                    Spacer()
                    Text("0 / 1R")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.text)
                }
                DeskMeterBar(value: 0, accent: DesignSystem.amber)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)

            railSection("EXECUTION")
            Text("THINKORSWIM (manual)")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.text2)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.bg1)
    }

    private func railHeader(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.labelFont)
            .tracking(1.6)
            .foregroundColor(DesignSystem.amber)
    }

    private func railSection(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.bg)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .top
        )
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .bottom
        )
    }

    private func gateRow(_ index: Int, _ title: String, _ detail: String, status: GateStatus) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(format: "%02d", index))
                .font(DesignSystem.Typography.labelFont)
                .foregroundColor(DesignSystem.muted)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(status == .pass ? DesignSystem.long : (status == .fail ? DesignSystem.short : DesignSystem.text2))
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .foregroundColor(DesignSystem.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            statusGlyph(for: status)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(blockerHighlight(status))
    }

    @ViewBuilder
    private func statusGlyph(for status: GateStatus) -> some View {
        switch status {
        case .pass:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.long)
        case .fail:
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.short)
        case .locked:
            Rectangle()
                .fill(DesignSystem.faint)
                .frame(width: 10, height: 2)
        }
    }

    private func blockerHighlight(_ status: GateStatus) -> Color {
        status == .fail ? DesignSystem.short.opacity(0.06) : Color.clear
    }

    private func windowRow(_ time: String, _ name: String, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(time)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(highlight ? DesignSystem.amber : DesignSystem.text2)
                .frame(width: 96, alignment: .leading)
            Text(name)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(highlight ? DesignSystem.amber : DesignSystem.muted)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Chart Center (Phase 5 wires TradingView)

private struct ChartCenterView: View {
    let symbol: TradingInstrument

    var body: some View {
        VStack(spacing: 0) {
            chartToolbar
            ZStack {
                DesignSystem.bg
                placeholder
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            chartFooter
        }
        .background(DesignSystem.bg)
    }

    private var chartToolbar: some View {
        HStack(spacing: 12) {
            ForEach(["1m", "5m", "15m", "1H", "1D"], id: \.self) { tf in
                Text(tf)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(tf == "5m" ? DesignSystem.amber : DesignSystem.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tf == "5m" ? DesignSystem.amber.opacity(0.10) : Color.clear)
            }

            Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 14)

            ForEach(["VWAP", "SMA20", "SMA50", "VOL"], id: \.self) { overlay in
                Text(overlay)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.text2)
            }

            Spacer()

            Text(symbol.displayName)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.amber)
        }
        .padding(.horizontal, 16)
        .frame(height: 30)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .bottom
        )
    }

    private var placeholder: some View {
        ChartWebView(symbol: ChartWebView.tradingViewSymbol(for: symbol))
            .background(DesignSystem.bg)
    }

    private var chartFooter: some View {
        HStack {
            Text("SRC · TRADINGVIEW · 15M DELAYED")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 22)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Right Rail

private struct RightRailView: View {
    let state: VXXStrategyState
    let entry: MarketDataEntry?
    @ObservedObject var signalMonitor: SignalMonitor
    let onEditTape: () -> Void
    let onSecondRead: () -> Void

    @State private var now = Date()
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let etTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nextMoveSection
            railDivider
            rawReadSection
            railDivider
            secondReadSection
            railDivider
            clockSection
            Spacer(minLength: 0)
        }
        .background(DesignSystem.bg1)
        .onReceive(clockTimer) { now = $0 }
    }

    private var railDivider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(height: 1)
    }

    // MARK: NEXT MOVE
    private var nextMoveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NEXT MOVE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
            }

            Text(state.commandTitle)
                .font(.system(size: 36, weight: .heavy, design: .default))
                .foregroundColor(state.commandColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(state.commandDetail)
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.text)
                .fixedSize(horizontal: false, vertical: true)

            if !signalMonitor.activeTrades.isEmpty {
                openPositionStrip
            }
        }
        .padding(16)
    }

    private var openPositionStrip: some View {
        HStack(spacing: 8) {
            DeskPulseDot(accent: DesignSystem.amber, size: 6)
            Text("\(signalMonitor.activeTrades.count) OPEN")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.amber)
            Spacer()
            Text(formattedNetPnL)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(netPnL >= 0 ? DesignSystem.long : DesignSystem.short)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.amber.opacity(0.08))
        .overlay(
            Rectangle().stroke(DesignSystem.amber.opacity(0.4), lineWidth: 1)
        )
    }

    private var netPnL: Double {
        signalMonitor.activeTrades.reduce(0) { $0 + ($1.unrealizedPnL / 100) }
    }

    private var formattedNetPnL: String {
        String(format: "$%+.2f", netPnL)
    }

    // MARK: RAW READ
    private var rawReadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RAW READ")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
                Button(action: onEditTape) {
                    Text(entry == nil ? "ENTER" : "EDIT")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.4)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.amber)
                }
                .buttonStyle(.plain)
            }

            if let entry {
                rawReadGrid(entry)
            } else {
                Text("NO TAPE — ENTER TO BEGIN")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.muted)
            }
        }
        .padding(16)
    }

    private func rawReadGrid(_ entry: MarketDataEntry) -> some View {
        VStack(spacing: 6) {
            rawReadRow("PRICE", String(format: "$%.2f", entry.price))
            rawReadRow("VIX", String(format: "%.2f", entry.vixLevel))
            if entry.instrument == .vxx {
                rawReadRow("RATIO", String(format: "%.3f", entry.ratio), accent: ratioAccent(entry))
                rawReadRow("TIER", entry.ratioTier.uppercased())
            }
            rawReadRow("VOLUME", "\(Int(entry.volumePercent))%")
            rawReadRow("VWAP", entry.vwapPosition.shortName)
            rawReadRow("WINDOW", entry.timeWindow.displayName.uppercased())
            rawReadRow("LEVEL", entry.keyLevelConfirmed ? "CONFIRMED" : "MISSING",
                       accent: entry.keyLevelConfirmed ? DesignSystem.long : DesignSystem.short)
            rawReadRow("PATTERN", entry.patternConfirmed ? "CONFIRMED" : "WAITING",
                       accent: entry.patternConfirmed ? DesignSystem.long : DesignSystem.amber)
        }
    }

    private func ratioAccent(_ entry: MarketDataEntry) -> Color {
        if entry.ratio >= 1.55 { return DesignSystem.long }
        if entry.ratio >= 1.45 { return DesignSystem.amber }
        return DesignSystem.short
    }

    private func rawReadRow(_ label: String, _ value: String, accent: Color = DesignSystem.text) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.muted)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(accent)
        }
    }

    // MARK: SECOND READ
    private var secondReadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SECOND READ")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
                Button(action: onSecondRead) {
                    Text("OPEN")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.4)
                        .foregroundColor(DesignSystem.amber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(Rectangle().stroke(DesignSystem.amber, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Paste prompt with current tape into the model of your choice. Use the read as a sanity check, not a green light.")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    // MARK: CLOCK
    private var clockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ET")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
                Text(Self.etTimeFormatter.string(from: now))
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.amber)
            }

            HStack {
                Text("HARD STOP IN")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
                Text(hardStopCountdown)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(hardStopColor)
            }
        }
        .padding(16)
    }

    private var hardStopCountdown: String {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 15
        components.minute = 55
        components.second = 0
        guard let target = cal.date(from: components) else { return "—" }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return "PAST" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var hardStopColor: Color {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 15
        components.minute = 55
        components.second = 0
        guard let target = cal.date(from: components) else { return DesignSystem.muted }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return DesignSystem.short }
        if interval < 600 { return DesignSystem.short }
        if interval < 1800 { return DesignSystem.amber }
        return DesignSystem.text
    }
}

// MARK: - Status Footer

private struct StatusFooterView: View {
    @ObservedObject var marketPulse: MarketPulse
    let entry: MarketDataEntry?

    var body: some View {
        HStack(spacing: 0) {
            footerCell("CHART", "TRADINGVIEW · 15M", accent: DesignSystem.muted)
            divider
            footerCell("QUOTES", "MANUAL TAPE", accent: entry == nil ? DesignSystem.short : DesignSystem.amber)
            divider
            footerCell("EXEC", "THINKORSWIM", accent: DesignSystem.muted)
            divider
            footerCell("PHASE", marketPulse.currentPhase.displayName.uppercased(), accent: DesignSystem.amber)
            Spacer(minLength: 0)
            footerCell("v1.0 · LOCAL", "", accent: DesignSystem.muted)
        }
        .frame(height: 24)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .top
        )
    }

    private var divider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 14)
    }

    private func footerCell(_ label: String, _ value: String, accent: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            if !value.isEmpty {
                Text(value)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(accent)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Phone Gate Spine (Phase 4)

enum PhoneGate: Int, Identifiable, CaseIterable {
    case volumeWindow = 1
    case ratio = 2
    case level = 3
    case pattern = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .volumeWindow: return "VOLUME + WINDOW"
        case .ratio:        return "RATIO"
        case .level:        return "VWAP / LEVEL"
        case .pattern:      return "PATTERN"
        }
    }

    var houseRule: String {
        switch self {
        case .volumeWindow: return "Wait until vol actually gets loud."
        case .ratio:        return "Manufactured entries are how people donate."
        case .level:        return "No level, no edge. The tape has to earn it."
        case .pattern:      return "Rejection candle, or no candle. No early entry."
        }
    }
}

// MARK: Phone Ticker Strip

private struct PhoneTickerStrip: View {
    let entry: MarketDataEntry?
    let phase: MarketPhase

    var body: some View {
        HStack(spacing: 0) {
            cell("VXX", priceText, accent: DesignSystem.text)
            divider
            cell("R", ratioText, accent: ratioAccent)
            divider
            cell("VOL", volText, accent: volAccent)
            divider
            cell("VWAP", vwapText, accent: DesignSystem.vwap)
            divider
            cell("PHASE", phase.displayName.uppercased(), accent: DesignSystem.amber)
        }
        .frame(height: 32)
        .background(DesignSystem.bg1)
        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private var divider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 18)
    }

    private func cell(_ label: String, _ value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(DesignSystem.muted)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var priceText: String {
        guard let entry, entry.price > 0 else { return "—" }
        return String(format: "%.2f", entry.price)
    }

    private var ratioText: String {
        guard let entry, entry.instrument == .vxx, entry.ratio > 0 else { return "—" }
        return String(format: "%.2f", entry.ratio)
    }

    private var ratioAccent: Color {
        guard let entry, entry.instrument == .vxx, entry.ratio > 0 else { return DesignSystem.muted }
        if entry.ratio >= 1.55 { return DesignSystem.long }
        if entry.ratio >= 1.45 { return DesignSystem.amber }
        return DesignSystem.short
    }

    private var volText: String {
        guard let entry else { return "—" }
        return "\(Int(entry.volumePercent))%"
    }

    private var volAccent: Color {
        guard let entry else { return DesignSystem.muted }
        if entry.volumePercent >= 300 { return DesignSystem.long }
        if entry.volumePercent >= 200 { return DesignSystem.amber }
        return DesignSystem.short
    }

    private var vwapText: String {
        guard let entry else { return "—" }
        return entry.vwapPosition.shortName
    }
}

// MARK: Phone Mini Chart (Phase 5 wires real data)

private struct PhoneMiniChart: View {
    let symbol: TradingInstrument

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CHART")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
                Text(symbol.displayName)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text2)
            }

            ChartWebView(symbol: ChartWebView.tradingViewSymbol(for: symbol))
                .frame(height: 140)
                .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))

            Text("SRC · TRADINGVIEW · 15M DELAYED")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
        }
    }
}

// MARK: Phone Clock Footer

private struct PhoneClockFooter: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let etFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ET")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Text(Self.etFormatter.string(from: now))
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.amber)
            }

            Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("HARD STOP IN")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Text(hardStopCountdown)
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(hardStopAccent)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("NEXT WINDOW")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Text(nextWindowText)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.bg1)
        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
        .onReceive(timer) { now = $0 }
    }

    private var hardStopCountdown: String {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 15
        components.minute = 55
        components.second = 0
        guard let target = cal.date(from: components) else { return "—" }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return "PAST" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var hardStopAccent: Color {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 15
        components.minute = 55
        components.second = 0
        guard let target = cal.date(from: components) else { return DesignSystem.muted }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return DesignSystem.short }
        if interval < 600 { return DesignSystem.short }
        if interval < 1800 { return DesignSystem.amber }
        return DesignSystem.text
    }

    private var nextWindowText: String {
        let windows: [(String, Int, Int)] = [
            ("Open Drive", 9, 35),
            ("Morning", 9, 50),
            ("Lunch", 12, 20),
            ("Power Hour", 15, 10),
            ("Institutional", 15, 45)
        ]
        let cal = Calendar(identifier: .gregorian)
        var c = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        let curHour = c.hour ?? 0
        let curMin = c.minute ?? 0
        let curMins = curHour * 60 + curMin

        for (name, h, m) in windows {
            let target = h * 60 + m
            if target > curMins {
                let delta = target - curMins
                return "\(name) · \(delta)m"
            }
        }
        c.day = (c.day ?? 0) + 1
        return "Tomorrow · Open Drive"
    }
}

// MARK: Phone Hard-Exit Takeover (3:50-4:10 ET)

private struct PhoneHardExitTakeover: View {
    @ObservedObject var signalMonitor: SignalMonitor
    let state: VXXStrategyState
    let openRisk: (() -> Void)?

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("HARD EXIT WINDOW")
                .font(DesignSystem.Typography.labelFont)
                .tracking(2.4)
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.short)

            Text(countdown)
                .font(.system(size: 64, weight: .heavy, design: .monospaced))
                .foregroundColor(DesignSystem.short)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("CLOSE EVERYTHING BY 15:55 ET.")
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.text)
                .multilineTextAlignment(.center)

            if !signalMonitor.activeTrades.isEmpty {
                openPositionsBlock
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("RULES")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)

                rule("01", "No new entries after 15:50.")
                rule("02", "Close winners on the 15:55 bell whether or not they're at target.")
                rule("03", "Cut losers immediately. No averaging into hope.")
            }
            .padding(12)
            .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(timer) { now = $0 }
    }

    private var countdown: String {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 15
        components.minute = 55
        components.second = 0
        guard let target = cal.date(from: components) else { return "—" }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return "00:00" }
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var openPositionsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("OPEN POSITIONS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
                Text(formattedNetPnL)
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(netPnL >= 0 ? DesignSystem.long : DesignSystem.short)
            }

            ForEach(signalMonitor.activeTrades) { trade in
                HStack {
                    Text(trade.symbol)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.text)
                    Spacer()
                    Text(String(format: "$%+.2f", trade.unrealizedPnL / 100))
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(trade.unrealizedPnL >= 0 ? DesignSystem.long : DesignSystem.short)
                }
            }

            if let openRisk {
                Button(action: openRisk) {
                    Text("OPEN RISK")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.4)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.amber)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(DesignSystem.short.opacity(0.08))
        .overlay(Rectangle().stroke(DesignSystem.short, lineWidth: 1))
    }

    private var netPnL: Double {
        signalMonitor.activeTrades.reduce(0) { $0 + ($1.unrealizedPnL / 100) }
    }

    private var formattedNetPnL: String {
        String(format: "$%+.2f", netPnL)
    }

    private func rule(_ index: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(index)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.muted)
            Text(text)
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: Phone Gate Detail Sheet

private struct PhoneGateDetailSheet: View {
    let gate: PhoneGate
    let state: VXXStrategyState
    let entry: MarketDataEntry?
    let openTape: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignSystem.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(format: "GATE %02d", gate.rawValue))
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.6)
                        .foregroundColor(DesignSystem.amber)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignSystem.text2)
                    }
                    .buttonStyle(.plain)
                }

                Text(gate.title)
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(DesignSystem.text)

                bigNumber

                tierTable

                Text(gate.houseRule)
                    .font(DesignSystem.Typography.bodyFont)
                    .italic()
                    .foregroundColor(DesignSystem.amber)
                    .padding(.vertical, 8)

                Text(detail)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.text2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if let openTape {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { openTape() }
                    } label: {
                        Text("EDIT TAPE")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.6)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.amber)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var bigNumber: some View {
        Text(numberText)
            .font(.system(size: 48, weight: .heavy, design: .monospaced))
            .foregroundColor(numberColor)
    }

    @ViewBuilder
    private var tierTable: some View {
        VStack(spacing: 1) {
            ForEach(tiers, id: \.label) { tier in
                HStack {
                    Text(tier.label)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(tier.active ? .black : DesignSystem.text2)
                    Spacer()
                    Text(tier.range)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(tier.active ? .black : DesignSystem.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(tier.active ? tier.color : DesignSystem.panel)
            }
        }
        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private var numberText: String {
        guard let entry else { return "—" }
        switch gate {
        case .volumeWindow:
            return "\(Int(entry.volumePercent))%"
        case .ratio:
            return entry.instrument == .vxx ? String(format: "%.3f", entry.ratio) : "N/A"
        case .level:
            return entry.keyLevelConfirmed ? "YES" : "NO"
        case .pattern:
            return entry.patternConfirmed ? "YES" : "NO"
        }
    }

    private var numberColor: Color {
        switch gate {
        case .volumeWindow:
            return state.volumeWindowStatus == .pass ? DesignSystem.long : DesignSystem.short
        case .ratio:
            return state.ratioStatus == .pass ? DesignSystem.long : DesignSystem.short
        case .level:
            return state.levelStatus == .pass ? DesignSystem.long : DesignSystem.short
        case .pattern:
            return state.patternStatus == .pass ? DesignSystem.long : DesignSystem.short
        }
    }

    private var detail: String {
        switch gate {
        case .volumeWindow: return state.volumeWindowDetail
        case .ratio:        return state.ratioDetail
        case .level:        return state.levelDetail
        case .pattern:      return state.patternDetail
        }
    }

    private struct Tier {
        let label: String
        let range: String
        let color: Color
        let active: Bool
    }

    private var tiers: [Tier] {
        switch gate {
        case .volumeWindow:
            let pct = entry?.volumePercent ?? 0
            return [
                Tier(label: "INSTITUTIONAL", range: "300%+",   color: DesignSystem.long,  active: pct >= 300),
                Tier(label: "STANDARD",      range: "200-299%",color: DesignSystem.amber, active: pct >= 200 && pct < 300),
                Tier(label: "BELOW",         range: "<200%",   color: DesignSystem.short, active: pct < 200)
            ]
        case .ratio:
            let r = entry?.ratio ?? 0
            return [
                Tier(label: "PREMIUM FADE", range: "1.60+",     color: DesignSystem.long,  active: r >= 1.60),
                Tier(label: "STRONG FADE",  range: "1.55-1.60", color: DesignSystem.long,  active: r >= 1.55 && r < 1.60),
                Tier(label: "NORMAL FADE",  range: "1.45-1.55", color: DesignSystem.amber, active: r >= 1.45 && r < 1.55),
                Tier(label: "WEAK FADE",    range: "1.35-1.45", color: DesignSystem.short, active: r >= 1.35 && r < 1.45),
                Tier(label: "NO FADE",      range: "<1.35",     color: DesignSystem.short, active: r < 1.35)
            ]
        case .level:
            let confirmed = entry?.keyLevelConfirmed ?? false
            return [
                Tier(label: "CONFIRMED", range: "VWAP / SMA / round / break", color: DesignSystem.long,  active: confirmed),
                Tier(label: "MISSING",   range: "no anchor",                  color: DesignSystem.short, active: !confirmed)
            ]
        case .pattern:
            let confirmed = entry?.patternConfirmed ?? false
            return [
                Tier(label: "REJECTION", range: "candle confirmed", color: DesignSystem.long,  active: confirmed),
                Tier(label: "WAITING",   range: "no clean signal",  color: DesignSystem.amber, active: !confirmed)
            ]
        }
    }
}
