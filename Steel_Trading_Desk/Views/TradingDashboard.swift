import SwiftUI
import Combine
import Charts
#if os(macOS)
import AppKit
#endif

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    var openTape: (() -> Void)? = nil
    var openRisk: (() -> Void)? = nil
    @StateObject private var marketPulse = MarketPulse.shared
    @StateObject private var timeManager = TimeManager.shared
    @StateObject private var liveTape = LiveTapeService.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("lastMarketDataEntry") private var lastMarketDataEntryData: Data = Data()

    private var lastMarketDataEntry: MarketDataEntry? {
        guard !lastMarketDataEntryData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MarketDataEntry.self, from: lastMarketDataEntryData)
    }

    private var phoneStrategyState: VXXStrategyState {
        VXXStrategyState(entry: lastMarketDataEntry)
    }

    private var usesCompactPhoneLayout: Bool {
        #if os(macOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }

    @State private var isSettingsSheetOpen = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                TradingBackdrop()

                if usesCompactPhoneLayout {
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
            .navigationTitle(usesCompactPhoneLayout ? "Steel Desk" : "Steel Trading Desk")
            #if os(iOS)
            .navigationBarTitleDisplayMode(usesCompactPhoneLayout ? .inline : .large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isSettingsSheetOpen = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(DesignSystem.amber)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .sheet(isPresented: $isSettingsSheetOpen) {
                SettingsView()
                    #if os(macOS)
                    .frame(width: 1180, height: 780)
                    #endif
            }
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: .debugOpenSettings)) { _ in
                isSettingsSheetOpen = true
            }
            #endif
        }
    }

    @State private var selectedPhoneGate: PhoneGate?
    @State private var isChartSheetOpen = false

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
                    PhoneStrategyRail(entry: lastMarketDataEntry, openTape: openTape, onSelectGate: { selectedPhoneGate = $0 })
                    PhoneCandleStrip(symbol: lastMarketDataEntry?.instrument ?? .vxx) {
                        isChartSheetOpen = true
                    }
                    PhoneCommandCard(state: phoneStrategyState, signalMonitor: signalMonitor, openRisk: openRisk)

                    if !signalMonitor.activeTrades.isEmpty {
                        activeTradesSection
                    }

                    PhoneClockFooter()
                    PhoneTapeActionCard(state: phoneStrategyState, openTape: openTape)
                }
                .sheet(item: $selectedPhoneGate) { gate in
                    PhoneGateDetailSheet(gate: gate, state: phoneStrategyState, entry: lastMarketDataEntry, openTape: openTape)
                }
                .sheet(isPresented: $isChartSheetOpen) {
                    PhoneChartSheet(symbol: lastMarketDataEntry?.instrument ?? .vxx)
                }
            }
        }
    }

    @MainActor
    private var currentDeskState: DeskState {
        DeskState.current(
            timeManager: timeManager,
            openPositions: signalMonitor.activeTrades.count,
            openPositionTimestamps: signalMonitor.activeTrades.map(\.timestamp)
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
            }
        }
        .deskPanel(glow: .clear, padding: 16)
    }
}

private struct PhoneTapeActionCard: View {
    let state: VXXStrategyState
    let openTape: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAPE")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)

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
        .deskPanel(glow: .clear, padding: 14)
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
                gateButton(.volume) {
                    StrategyGateRow(
                        index: 1,
                        title: "Volume",
                        detail: state.volumeDetail,
                        status: state.volumeStatus,
                        systemImage: "chart.bar.xaxis",
                        accent: DesignSystem.amber,
                        isBlocker: blockerIndex == 1
                    )
                }

                gateButton(.window) {
                    StrategyGateRow(
                        index: 2,
                        title: "Window",
                        detail: state.windowDetail,
                        status: state.windowStatus,
                        systemImage: "clock",
                        accent: DesignSystem.amber,
                        isBlocker: blockerIndex == 2
                    )
                }

                gateButton(.ratio) {
                    StrategyGateRow(
                        index: 3,
                        title: "Ratio",
                        detail: state.ratioDetail,
                        status: state.ratioStatus,
                        systemImage: "divide.circle",
                        accent: DesignSystem.amber,
                        isBlocker: blockerIndex == 3
                    )
                }

                gateButton(.level) {
                    StrategyGateRow(
                        index: 4,
                        title: "VWAP / key level",
                        detail: state.levelDetail,
                        status: state.levelStatus,
                        systemImage: "scope",
                        accent: DesignSystem.steel,
                        isBlocker: blockerIndex == 4
                    )
                }

                gateButton(.pattern) {
                    StrategyGateRow(
                        index: 5,
                        title: "Pattern now",
                        detail: state.patternDetail,
                        status: state.patternStatus,
                        systemImage: "candlestickchart",
                        accent: DesignSystem.long,
                        isBlocker: blockerIndex == 5
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
    /// Live divergence read. Read once at struct construction; views that
    /// observe `LiveTapeService.shared` will re-render with a fresh value.
    let liveSnapshot: LiveTapeService.LiveSnapshot?

    @MainActor
    init(entry: MarketDataEntry?) {
        self.entry = entry
        self.liveSnapshot = LiveTapeService.shared.lastSnapshot
    }

    init(entry: MarketDataEntry?, liveSnapshot: LiveTapeService.LiveSnapshot?) {
        self.entry = entry
        self.liveSnapshot = liveSnapshot
    }

    var volumePass: Bool {
        guard let entry else { return false }
        return entry.volumePercent >= entry.timeWindow.requiredVolumePercent
    }

    var windowPass: Bool {
        guard let entry else { return false }
        return entry.timeWindow.isVXXEntryWindow
    }

    var baseConditionsPass: Bool {
        volumePass && windowPass
    }

    /// True when VIX is meaningfully outpacing VXX.
    /// That's the wrong direction for this setup, so it needs plain warning
    /// copy before any sizing decision.
    /// Only evaluated when live data is available; manual mode has no
    /// pct-change input and can't enforce this constraint.
    var vixLeadingVxx: Bool {
        guard let snap = liveSnapshot else { return false }
        return snap.isDiverging && snap.divergencePoints < 0
    }

    var ratioPass: Bool {
        guard let entry else { return false }
        // Strict doc rule: ratio ≥ 1.45. Convergence is now surfaced as a
        // soft warning in `ratioDetail` rather than blocking the gate —
        // [[feedback-catch-drift-always]] said don't bolt on heuristics the
        // doc doesn't enforce, and the strategy prompts list ratio>=1.45 as
        // the only ratio rule. Drift fix 2026-05-14.
        return entry.instrument == .vxx && entry.ratio >= StrategySpec.minimumRatioForEntry
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
        baseConditionsPass && ratioPass && levelPass && patternPass
    }

    /// 1...5 if there is a blocker (first failing condition), nil if all pass or no entry.
    var firstFailingGateIndex: Int? {
        guard entry != nil else { return 1 }
        if !volumePass { return 1 }
        if !windowPass { return 2 }
        if !ratioPass { return 3 }
        if !levelPass { return 4 }
        if !patternPass { return 5 }
        return nil
    }

    var volumeStatus: GateStatus {
        guard entry != nil else { return .fail }
        return volumePass ? .pass : .fail
    }

    var windowStatus: GateStatus {
        guard entry != nil else { return .fail }
        return windowPass ? .pass : .fail
    }

    var ratioStatus: GateStatus {
        guard baseConditionsPass else { return .locked }
        return ratioPass ? .pass : .fail
    }

    var levelStatus: GateStatus {
        guard baseConditionsPass && ratioPass else { return .locked }
        return levelPass ? .pass : .fail
    }

    var patternStatus: GateStatus {
        guard baseConditionsPass && ratioPass && levelPass else { return .locked }
        return patternPass ? .pass : .fail
    }

    var volumeDetail: String {
        guard let entry else { return "Start here. Enter current VXX tape." }
        let req = Int(entry.timeWindow.requiredVolumePercent)
        if !volumePass {
            return "Volume \(Int(entry.volumePercent))%. Need >\(req)% before this setup is live."
        }
        return "Volume \(Int(entry.volumePercent))% clears the \(req)% requirement."
    }

    var windowDetail: String {
        guard let entry else { return "Need a valid VXX entry window." }
        if !windowPass {
            return "\(entry.timeWindow.displayName) is outside this setup. No alert."
        }
        return "\(entry.timeWindow.displayName) is a valid VXX entry window."
    }

    var ratioDetail: String {
        guard let entry else { return "Locked until tape is entered." }
        if !baseConditionsPass { return "Locked until volume and window pass." }
        if entry.instrument != .vxx { return "This desk is for VXX. Switch the tape to VXX." }
        if entry.ratio < StrategySpec.minimumRatioForEntry {
            return "Ratio \(String(format: "%.2f", entry.ratio)) fails. Need >\(String(format: "%.2f", StrategySpec.minimumRatioForEntry))."
        }
        if vixLeadingVxx, let snap = liveSnapshot {
            // Soft warning — gate still passes per doc, but the direction
            // is worth knowing before sizing up.
            return "Ratio \(String(format: "%.2f", entry.ratio)) passes (\(entry.ratioTier)). HEADS UP: VIX is leading VXX (\(String(format: "%+.2f", snap.divergencePoints))pp). Wait for a cleaner read or size down."
        }
        return "Ratio \(String(format: "%.2f", entry.ratio)) passes. \(entry.ratioTier)."
    }

    var levelDetail: String {
        guard baseConditionsPass && ratioPass else { return "Locked until ratio passes." }
        guard let entry else { return "Locked until tape is entered." }
        return levelPass
            ? "Key level confirmed. VWAP read: \(entry.vwapPosition.displayName)."
            : "No key level. Need VWAP, 50 SMA, round number, prior high, or support break."
    }

    var patternDetail: String {
        guard baseConditionsPass && ratioPass && levelPass else { return "Locked until level passes." }
        guard let entry else { return "Locked until tape is entered." }
        if patternPass {
            return entry.arrowSignal == .none ? "Rejection pattern confirmed." : "Pattern confirmed with \(entry.arrowSignal.displayName)."
        }
        return "Wait for rejection candle. No early entry."
    }

    var decisionDetail: String {
        guard let entry else { return "No tape entered. Start with Tape." }
        if ready {
            return "All five conditions are live. Size by ratio: \(entry.ratioTier). Review, then execute manually on broker. 4:15 ET session close still rules."
        }
        return "One failed gate means skip or wait. Do not average your way into a trade."
    }

    var commandTitle: String {
        guard let entry else { return "ENTER TAPE" }
        if entry.instrument != .vxx { return "SWITCH TO VXX" }
        if ready { return "CLEARED" }
        if !volumePass { return "NO TRADE" }
        if !windowPass { return "NO TRADE" }
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
        if !volumePass {
            return volumeDetail
        }
        if !windowPass {
            return windowDetail
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
        if !volumePass || !windowPass || !ratioPass { return DesignSystem.dangerColor }
        return DesignSystem.warningColor
    }

    var commandIcon: String {
        if ready { return "checkmark.seal.fill" }
        guard entry != nil else { return "slider.horizontal.3" }
        if !volumePass || !windowPass || !ratioPass { return "xmark.octagon.fill" }
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
                timingColumn(label: "Session Close", value: hardExitTime)
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
                    detail: "3:30-\(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)). Warning at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime)). Alert session closes at \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalHardExitTime)) if you are still managing."
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
        case .close: return "3:30-4:15 PM"
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
// The chart center renders only Schwab-authenticated live tape candles.

private enum MacTerminalSheet: Identifiable {
    case tape
    case prompt

    var id: String {
        switch self {
        case .tape: return "tape"
        case .prompt: return "prompt"
        }
    }
}

private struct MacTerminalView: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @ObservedObject var marketPulse: MarketPulse
    let entry: MarketDataEntry?
    let state: VXXStrategyState

    @State private var activeSheet: MacTerminalSheet?

    #if os(macOS)
    private var tapeSheetSize: CGSize {
        let visibleFrame = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1100, height: 840)
        return CGSize(
            width: min(980, max(760, visibleFrame.width - 160)),
            height: min(780, max(640, visibleFrame.height - 120))
        )
    }
    #endif

    var body: some View {
        GeometryReader { geometry in
            terminalBody(for: geometry.size.width)
        }
        .background(DesignSystem.bg)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .tape:
                ZStack {
                    DesignSystem.bg.ignoresSafeArea()
                    ManualDataEntryView()
                }
                    #if os(macOS)
                    .frame(width: tapeSheetSize.width, height: tapeSheetSize.height)
                    #endif
            case .prompt:
                ZStack {
                    DesignSystem.bg.ignoresSafeArea()
                    PromptCoachView()
                }
                    #if os(macOS)
                    .frame(minWidth: 640, minHeight: 720)
                    #endif
            }
        }
    }

    @ViewBuilder
    private func terminalBody(for width: CGFloat) -> some View {
        let metrics = MacDeskMetrics(width: width)

        VStack(spacing: 0) {
            TickerStripView(entry: entry, marketPulse: marketPulse)

            if metrics.isStacked {
                stackedTerminalBody
            } else {
                HStack(spacing: 0) {
                    if metrics.showsLeftRail {
                        LeftRailView(state: state, marketPulse: marketPulse)
                            .frame(width: metrics.leftRailWidth)
                            .frame(maxHeight: .infinity, alignment: .top)

                        Rectangle()
                            .fill(DesignSystem.hairline)
                            .frame(width: 1)
                    }

                    VStack(spacing: 0) {
                        if !metrics.showsLeftRail {
                            CompactGateStripView(state: state)
                        }

                        ChartCenterView(symbol: entry?.instrument ?? .vxx)
                    }
                    .frame(minWidth: metrics.minimumChartWidth, maxWidth: .infinity, maxHeight: .infinity)

                    Rectangle()
                        .fill(DesignSystem.hairline)
                        .frame(width: 1)

                    RightRailView(
                        state: state,
                        entry: entry,
                        signalMonitor: signalMonitor,
                        onEditTape: { activeSheet = .tape },
                        onSecondRead: { activeSheet = .prompt }
                    )
                    .frame(width: metrics.rightRailWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxHeight: .infinity)
            }

            StatusFooterView(marketPulse: marketPulse, entry: entry)
        }
    }

    private var stackedTerminalBody: some View {
        VStack(spacing: 0) {
            CompactGateStripView(state: state)

            ChartCenterView(symbol: entry?.instrument ?? .vxx)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(DesignSystem.hairline)
                .frame(height: 1)

            RightRailView(
                state: state,
                entry: entry,
                signalMonitor: signalMonitor,
                onEditTape: { activeSheet = .tape },
                onSecondRead: { activeSheet = .prompt }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 250)
        }
        .frame(maxHeight: .infinity)
    }
}

private struct MacDeskMetrics {
    let width: CGFloat

    var isStacked: Bool {
        width < 900
    }

    var showsLeftRail: Bool {
        width >= 1120
    }

    var leftRailWidth: CGFloat {
        if width >= 1700 { return 320 }
        if width >= 1440 { return 300 }
        return 260
    }

    var rightRailWidth: CGFloat {
        if width >= 1700 { return 430 }
        if width >= 1440 { return 390 }
        if width >= 1120 { return 340 }
        return min(320, max(290, width * 0.34))
    }

    var minimumChartWidth: CGFloat {
        showsLeftRail ? 540 : 560
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
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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

private struct CompactGateStripView: View {
    let state: VXXStrategyState

    var body: some View {
        HStack(spacing: 0) {
            gateCell("01", "VOL", state.volumeStatus)
            divider
            gateCell("02", "WIN", state.windowStatus)
            divider
            gateCell("03", "RATIO", state.ratioStatus)
            divider
            gateCell("04", "LEVEL", state.levelStatus)
            divider
            gateCell("05", "PATTERN", state.patternStatus)
        }
        .frame(height: 44)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .bottom
        )
    }

    private var divider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 22)
    }

    private func gateCell(_ index: String, _ label: String, _ status: GateStatus) -> some View {
        HStack(spacing: 7) {
            Text(index)
                .font(DesignSystem.Typography.labelFont)
                .foregroundColor(DesignSystem.muted)

            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)

            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.1)
                .foregroundColor(status.color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }
}

private struct LeftRailView: View {
    let state: VXXStrategyState
    @ObservedObject var marketPulse: MarketPulse
    @State private var now = Date()

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let etTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    private struct RailWindowItem: Identifiable {
        let id: String
        let time: String
        let name: String
        let startMinutes: Int
        let endMinutes: Int
    }

    private enum RailWindowStatus {
        case live
        case next
        case idle

        var label: String {
            switch self {
            case .live: return "LIVE"
            case .next: return "NEXT"
            case .idle: return ""
            }
        }

        var accent: Color {
            switch self {
            case .live: return DesignSystem.long
            case .next: return DesignSystem.amber
            case .idle: return DesignSystem.muted
            }
        }
    }

    private static let railWindows: [RailWindowItem] = [
        RailWindowItem(id: "open", time: compactRange(start: 9 * 60 + 35, end: 10 * 60 + 5), name: "Open Drive", startMinutes: 9 * 60 + 35, endMinutes: 10 * 60 + 5),
        RailWindowItem(id: "morning", time: compactRange(StrategySpec.morningWindow), name: "Morning Fade", startMinutes: StrategySpec.morningWindow.startMinutes, endMinutes: StrategySpec.morningWindow.endMinutes),
        RailWindowItem(id: "lunch", time: compactRange(start: 12 * 60 + 20, end: 12 * 60 + 40), name: "Lunch Window", startMinutes: 12 * 60 + 20, endMinutes: 12 * 60 + 40),
        RailWindowItem(id: "powerHour", time: compactRange(StrategySpec.powerHourWindow), name: "Power Hour", startMinutes: StrategySpec.powerHourWindow.startMinutes, endMinutes: StrategySpec.powerHourWindow.endMinutes),
        RailWindowItem(id: "institutional", time: compactRange(StrategySpec.institutionalWindow), name: "Institutional", startMinutes: StrategySpec.institutionalWindow.startMinutes, endMinutes: StrategySpec.institutionalWindow.endMinutes)
    ]

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
                gateRow(1, "VOLUME", state.volumeDetail, status: state.volumeStatus)
                gateRow(2, "WINDOW", state.windowDetail, status: state.windowStatus)
                gateRow(3, "RATIO", state.ratioDetail, status: state.ratioStatus)
                gateRow(4, "VWAP / LEVEL", state.levelDetail, status: state.levelStatus)
                gateRow(5, "PATTERN", state.patternDetail, status: state.patternStatus)
            }
            .padding(.bottom, 14)

            railSection("ET · SESSION")
            sessionClockBlock
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

            railSection("TODAY · WINDOWS")
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Self.railWindows) { window in
                    windowRow(window, status: status(for: window))
                }
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

            railSection("ORDERS")
            Text("MANUAL ONLY")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.text2)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.bg1)
        .onReceive(clockTimer) { now = $0 }
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

    private var sessionClockBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ET")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
                Text(Self.etTimeFormatter.string(from: now))
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.amber)
            }

            HStack {
                Text("4:15 CLOSE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
                Text(sessionCloseCountdown)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(sessionCloseColor)
            }
        }
        .padding(.top, 7)
    }

    private var sessionCloseCountdown: String {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 16
        components.minute = 15
        components.second = 0
        guard let target = cal.date(from: components) else { return "—" }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return "CLOSED" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var sessionCloseColor: Color {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 16
        components.minute = 15
        components.second = 0
        guard let target = cal.date(from: components) else { return DesignSystem.muted }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return DesignSystem.short }
        if interval < 600 { return DesignSystem.short }
        if interval < 1800 { return DesignSystem.amber }
        return DesignSystem.text
    }

    private static func compactRange(_ window: StrategySpec.TradingWindow) -> String {
        compactRange(start: window.startMinutes, end: window.endMinutes)
    }

    private static func compactRange(start: Int, end: Int) -> String {
        String(
            format: "%02d:%02d-%02d:%02d",
            start / 60,
            start % 60,
            end / 60,
            end % 60
        )
    }

    private var etMinutes: Int {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: now)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private var nextWindowID: String? {
        Self.railWindows
            .filter { $0.endMinutes > etMinutes }
            .min { $0.startMinutes < $1.startMinutes }?
            .id
    }

    private func status(for window: RailWindowItem) -> RailWindowStatus {
        if etMinutes >= window.startMinutes && etMinutes < window.endMinutes {
            return .live
        }
        if window.id == nextWindowID {
            return .next
        }
        return .idle
    }

    private func windowRow(_ window: RailWindowItem, status: RailWindowStatus) -> some View {
        HStack(spacing: 10) {
            Text(window.time)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(status == .idle ? DesignSystem.text2 : status.accent)
                .frame(width: 92, alignment: .leading)
            Text(window.name)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(status == .idle ? DesignSystem.muted : status.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
            if status != .idle {
                Text(status.label)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(status.accent)
                    .frame(width: 34, alignment: .trailing)
            }
        }
    }
}

// MARK: - Schwab Live Chart Center

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
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 560
            let overlays = isCompact ? ["VWAP", "20", "50", "VOL"] : ["VWAP", "SMA20", "SMA50", "VOL"]

            HStack(spacing: isCompact ? 6 : 10) {
                ForEach(isCompact ? ["1m", "5m", "15m", "1H"] : ["1m", "5m", "15m", "1H", "1D"], id: \.self) { tf in
                    Text(tf)
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.0)
                        .foregroundColor(tf == "5m" ? DesignSystem.amber : DesignSystem.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                        .padding(.horizontal, isCompact ? 5 : 7)
                        .padding(.vertical, 4)
                        .background(tf == "5m" ? DesignSystem.amber.opacity(0.10) : Color.clear)
                }

                Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 14)

                ForEach(overlays, id: \.self) { overlay in
                    Text(overlay)
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.0)
                        .foregroundColor(DesignSystem.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                }

                Spacer(minLength: 6)

                Text(symbol.displayName)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.amber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, isCompact ? 10 : 16)
            .frame(width: geometry.size.width, height: 30, alignment: .leading)
        }
        .frame(height: 30)
        .clipped()
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .bottom
        )
    }

    @ObservedObject private var liveTape = LiveTapeService.shared

    @ViewBuilder
    private var placeholder: some View {
        if let series = currentSeries, !series.candles.isEmpty {
            PhoneCandleChart(
                series: series,
                showAxisLabels: true,
                windowStripeOpacity: 0.10,
                showPatternMarkers: true
            )
            .padding(12)
        } else {
            SchwabChartLockedState()
        }
    }

    private var currentSeries: PhoneChartSeries? {
        let bars = liveTape.lastSnapshot?.vxxCandles ?? []
        guard AppConfig.Schwab.hasOAuthTokens, !bars.isEmpty else { return nil }
        return PhoneChartSeries.build(from: bars, bucketSeconds: 5 * 60)
    }

    private var chartFooter: some View {
        HStack {
            Text(chartSourceText)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(chartSourceAccent)
            Spacer()
            if let tick = liveTape.lastTickAt {
                Text("LAST · \(Self.tickFormatter.string(from: tick))")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.faint)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 22)
        .background(DesignSystem.bg1)
        .overlay(
            Rectangle().fill(DesignSystem.hairline).frame(height: 1),
            alignment: .top
        )
    }

    private var chartSourceText: String {
        if liveTape.isLive { return "SRC · SCHWAB LIVE" }
        if AppConfig.Schwab.hasOAuthTokens { return "SRC · SCHWAB · WAITING FOR TICK" }
        if AppConfig.Schwab.hasDeveloperCredentials { return "SRC · SCHWAB · OAUTH REQUIRED" }
        return "SRC · SCHWAB · KEYS REQUIRED"
    }

    private var chartSourceAccent: Color {
        liveTape.isLive ? DesignSystem.long : DesignSystem.amber
    }

    private static let tickFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()
}


private struct SchwabChartLockedState: View {
    @ObservedObject private var liveTape = LiveTapeService.shared

    var body: some View {
        VStack(spacing: 10) {
            Text("SCHWAB LIVE REQUIRED")
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.amber)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(statusText)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                statusPip
                Text(sourceText)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(statusAccent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusText: String {
        if let error = liveTape.lastError, !error.isEmpty {
            return error
        }
        if AppConfig.Schwab.hasOAuthTokens {
            return "OAuth is connected. Waiting for the first verified Schwab candle batch."
        }
        if AppConfig.Schwab.hasDeveloperCredentials {
            return "Open Settings and complete Schwab OAuth to unlock live candles."
        }
        return "Add Schwab app key and app secret in Settings to unlock live candles."
    }

    private var sourceText: String {
        if liveTape.isLive { return "SCHWAB LIVE" }
        if AppConfig.Schwab.hasOAuthTokens { return "TOKEN STORED" }
        if AppConfig.Schwab.hasDeveloperCredentials { return "OAUTH REQUIRED" }
        return "KEYS REQUIRED"
    }

    private var statusAccent: Color {
        liveTape.isLive ? DesignSystem.long : DesignSystem.amber
    }

    private var statusPip: some View {
        Circle()
            .fill(statusAccent)
            .frame(width: 7, height: 7)
    }
}


// MARK: - Right Rail

private struct RightRailView: View {
    let state: VXXStrategyState
    let entry: MarketDataEntry?
    @ObservedObject var signalMonitor: SignalMonitor
    let onEditTape: () -> Void
    let onSecondRead: () -> Void

    @ObservedObject private var liveTape = LiveTapeService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nextMoveSection
            railDivider
            rawReadSection
            railDivider
            secondReadSection
            Spacer(minLength: 0)
        }
        .background(DesignSystem.bg1)
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
            if let snap = liveTape.lastSnapshot {
                divergenceRows(snap)
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

    @ViewBuilder
    private func divergenceRows(_ snap: LiveTapeService.LiveSnapshot) -> some View {
        rawReadRow("VXX Δ",
                   String(format: "%+.2f%%", snap.vxxPctChange),
                   accent: snap.vxxPctChange >= 0 ? DesignSystem.long : DesignSystem.short)
        rawReadRow("VIX Δ",
                   String(format: "%+.2f%%", snap.vixPctChange),
                   accent: snap.vixPctChange >= 0 ? DesignSystem.long : DesignSystem.short)
        rawReadRow("DIVERGE",
                   divergenceText(snap),
                   accent: divergenceAccent(snap))
    }

    private func divergenceText(_ snap: LiveTapeService.LiveSnapshot) -> String {
        let sign = snap.divergencePoints >= 0 ? "+" : ""
        let label: String
        if !snap.isDiverging {
            label = "TRACKING"
        } else if snap.divergencePoints > 0 {
            label = "VXX OUT"   // VXX outpacing VIX = fade-worthy expansion
        } else {
            label = "VIX OUT"   // VIX outpacing VIX = regime move, not the fade
        }
        return "\(label) \(sign)\(String(format: "%.2f", snap.divergencePoints))pp"
    }

    private func divergenceAccent(_ snap: LiveTapeService.LiveSnapshot) -> Color {
        if !snap.isDiverging { return DesignSystem.steel }
        return snap.divergencePoints > 0 ? DesignSystem.amber : DesignSystem.short
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

}

// MARK: - Status Footer

private struct StatusFooterView: View {
    @ObservedObject var marketPulse: MarketPulse
    let entry: MarketDataEntry?
    @ObservedObject private var liveTape = LiveTapeService.shared
    @State private var schwabCredentialRevision = 0

    var body: some View {
        HStack(spacing: 0) {
            footerCell("CHART", chartText, accent: chartAccent)
            divider
            footerCell("QUOTES", quotesText, accent: quotesAccent)
            divider
            footerCell("ORDERS", "MANUAL ONLY", accent: DesignSystem.muted)
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
        .onReceive(NotificationCenter.default.publisher(for: .schwabCredentialsChanged)) { _ in
            schwabCredentialRevision += 1
        }
    }

    private var chartText: String {
        _ = schwabCredentialRevision
        if liveTape.isLive { return "SCHWAB LIVE" }
        if AppConfig.Schwab.oauthTokensStored { return "SCHWAB WAIT" }
        if AppConfig.Schwab.developerCredentialsStored { return "OAUTH REQ" }
        return "LOCKED"
    }

    private var chartAccent: Color {
        _ = schwabCredentialRevision
        if liveTape.isLive { return DesignSystem.long }
        if AppConfig.Schwab.oauthTokensStored || AppConfig.Schwab.developerCredentialsStored { return DesignSystem.amber }
        return DesignSystem.muted
    }

    private var quotesText: String {
        _ = schwabCredentialRevision
        if liveTape.isLive {
            if let last = liveTape.lastTickAt {
                let delta = Int(Date().timeIntervalSince(last))
                return "LIVE · \(delta)s"
            }
            return "LIVE"
        }
        if liveTape.isEnabled, let err = liveTape.lastError {
            return "LIVE · ERR · \(err.prefix(40))".uppercased()
        }
        if AppConfig.Schwab.oauthTokensStored {
            return "SCHWAB TOKEN · FEED OFF"
        }
        if AppConfig.Schwab.developerCredentialsStored {
            return "SCHWAB KEYS · OAUTH PENDING"
        }
        return entry == nil ? "NO TAPE" : "MANUAL TAPE"
    }

    private var quotesAccent: Color {
        _ = schwabCredentialRevision
        if liveTape.isLive { return DesignSystem.long }
        if liveTape.isEnabled && liveTape.lastError != nil { return DesignSystem.short }
        if AppConfig.Schwab.oauthTokensStored { return DesignSystem.bullishColor }
        if AppConfig.Schwab.developerCredentialsStored { return DesignSystem.warningColor }
        return entry == nil ? DesignSystem.short : DesignSystem.amber
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
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if !value.isEmpty {
                Text(value)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Phone Gate Spine (Phase 4)

enum PhoneGate: Int, Identifiable, CaseIterable {
    case volume = 1
    case window = 2
    case ratio = 3
    case level = 4
    case pattern = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .volume:       return "VOLUME"
        case .window:       return "WINDOW"
        case .ratio:        return "RATIO"
        case .level:        return "VWAP / LEVEL"
        case .pattern:      return "PATTERN"
        }
    }

    var houseRule: String {
        switch self {
        case .volume:       return "No loud tape, no setup."
        case .window:       return "Wrong window, wrong trade."
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

// MARK: Phone Candle Strip + Chart Sheet
//
// Two-tier chart for the iPhone home, matching the pattern Robinhood / Webull /
// Schwab and ToS mobile use a compact native candle preview inline,
// preview inline on the dense view, and a fullscreen native chart on tap.
//
// Strategy context (see docs/trading docs/): the trader reads candle shape at
// VWAP / 20 SMA / 50 SMA to confirm entry. A 140pt squashed web embed
// hides exactly that wick-vs-body detail. Swift Charts gives crisp candles at
// 96pt and lets us draw the ToS overlays at the right colors.

private struct PhoneChartSeries {
    let candles: [Candle]
    let vwap: [(Date, Double)]
    let sma20: [(Date, Double)]
    let sma50: [(Date, Double)]
    let priceLow: Double
    let priceHigh: Double
    let tradingWindows: [(start: Date, end: Date, label: String)]
    let avgVolume: Double  // 30-period (or shorter if fewer bars) — for 200% threshold
    let patterns: [(candle: Candle, pattern: CandlestickPattern)]

    static func build(from raw: [Candle], bucketSeconds: TimeInterval) -> PhoneChartSeries {
        let bars = bucketSeconds > 60 ? raw.aggregated(bucketSeconds: bucketSeconds) : raw
        let candles = Array(bars.suffix(160))  // hard cap so the chart stays readable
        let vwap = runningVWAP(candles)
        let sma20 = sma(candles, period: 20)
        let sma50 = sma(candles, period: 50)

        let allLows = candles.map(\.low)
        let allHighs = candles.map(\.high)
        let low = allLows.min() ?? 0
        let high = allHighs.max() ?? 0
        // 4% headroom either side so candles don't kiss the chart edges
        let pad = max((high - low) * 0.04, 0.05)

        // Trading-window stripes — keep only the windows that overlap visible candles.
        let firstTime = candles.first?.timestamp ?? Date()
        let lastTime = candles.last?.timestamp ?? Date()
        let windows = tradingWindowsForToday(reference: lastTime).filter { w in
            w.end >= firstTime && w.start <= lastTime
        }

        // 30-period rolling volume average for the 200% threshold on the volume panel.
        let recent = Array(candles.suffix(30))
        let avgVol = recent.isEmpty ? 0 : Double(recent.reduce(0) { $0 + $1.volume }) / Double(recent.count)

        // Pattern hits across the whole visible series — Shooting Star / Doji /
        // Hammer / Hanging Man / Bearish Engulfing per the ToS strategy doc.
        let recognizer = PatternRecognizer()
        let patterns = recognizer.detectPatternsAcrossSeries(candles: candles, averageVolume: Int(avgVol))

        return PhoneChartSeries(
            candles: candles,
            vwap: vwap,
            sma20: sma20,
            sma50: sma50,
            priceLow: low - pad,
            priceHigh: high + pad,
            tradingWindows: windows,
            avgVolume: avgVol,
            patterns: patterns
        )
    }

    /// The 3 ToS windows expressed as absolute Date ranges in the reference date's
    /// ET calendar day. Order matches the strategy doc.
    private static func tradingWindowsForToday(reference: Date) -> [(start: Date, end: Date, label: String)] {
        guard let etZone = TimeZone(identifier: "America/New_York") else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etZone
        let comps = cal.dateComponents([.year, .month, .day], from: reference)

        func make(_ h1: Int, _ m1: Int, _ h2: Int, _ m2: Int, _ label: String) -> (Date, Date, String)? {
            var s = comps; s.hour = h1; s.minute = m1; s.timeZone = etZone
            var e = comps; e.hour = h2; e.minute = m2; e.timeZone = etZone
            guard let sd = cal.date(from: s), let ed = cal.date(from: e) else { return nil }
            return (sd, ed, label)
        }

        return [
            make(9, 50, 10, 15, "MORN"),
            make(15, 10, 15, 25, "POWER"),
            make(15, 45, 16, 10, "INST")
        ].compactMap { $0 }
    }

    private static func runningVWAP(_ candles: [Candle]) -> [(Date, Double)] {
        var num: Double = 0
        var den: Double = 0
        var out: [(Date, Double)] = []
        for c in candles {
            let typical = (c.high + c.low + c.close) / 3
            num += typical * Double(c.volume)
            den += Double(c.volume)
            if den > 0 {
                out.append((c.timestamp, num / den))
            }
        }
        return out
    }

    private static func sma(_ candles: [Candle], period: Int) -> [(Date, Double)] {
        guard candles.count >= period, period > 0 else { return [] }
        var out: [(Date, Double)] = []
        for i in (period - 1)..<candles.count {
            let window = candles[(i - period + 1)...i]
            let avg = window.map(\.close).reduce(0, +) / Double(period)
            out.append((candles[i].timestamp, avg))
        }
        return out
    }
}

private struct PhoneCandleChart: View {
    let series: PhoneChartSeries
    let showAxisLabels: Bool
    var windowStripeOpacity: Double = 0.06   // subtle on tile; raise on the sheet
    var showPatternMarkers: Bool = false
    var enableSelection: Bool = false
    @Binding var selectedCandle: Candle?

    init(series: PhoneChartSeries,
         showAxisLabels: Bool,
         windowStripeOpacity: Double = 0.06,
         showPatternMarkers: Bool = false,
         enableSelection: Bool = false,
         selectedCandle: Binding<Candle?> = .constant(nil)) {
        self.series = series
        self.showAxisLabels = showAxisLabels
        self.windowStripeOpacity = windowStripeOpacity
        self.showPatternMarkers = showPatternMarkers
        self.enableSelection = enableSelection
        self._selectedCandle = selectedCandle
    }

    var body: some View {
        baseChart
            .chartOverlay { proxy in
                if enableSelection {
                    selectionOverlay(proxy: proxy)
                }
            }
    }

    private var baseChart: some View {
        Chart {
            // Trading-window stripes (underlay) — faint amber bands for the 3 ToS windows
            ForEach(Array(series.tradingWindows.enumerated()), id: \.offset) { _, w in
                RectangleMark(
                    xStart: .value("Start", w.start),
                    xEnd: .value("End", w.end),
                    yStart: .value("Low", series.priceLow),
                    yEnd: .value("High", series.priceHigh)
                )
                .foregroundStyle(DesignSystem.amber.opacity(windowStripeOpacity))
            }

            // Selected-candle vertical guide (only when something is picked)
            if enableSelection, let sel = selectedCandle {
                RuleMark(x: .value("Selected", sel.timestamp))
                    .foregroundStyle(DesignSystem.text.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }

            // Wick (high to low) — thin rectangle
            ForEach(series.candles) { c in
                RectangleMark(
                    x: .value("Time", c.timestamp),
                    yStart: .value("Low", c.low),
                    yEnd: .value("High", c.high),
                    width: .fixed(1)
                )
                .foregroundStyle(c.isBullish ? DesignSystem.long : DesignSystem.short)
            }

            // Body (open to close)
            ForEach(series.candles) { c in
                RectangleMark(
                    x: .value("Time", c.timestamp),
                    yStart: .value("Open", c.open),
                    yEnd: .value("Close", c.close),
                    width: .ratio(0.65)
                )
                .foregroundStyle(c.isBullish ? DesignSystem.long : DesignSystem.short)
            }

            // VWAP (cyan) — primary institutional bias line
            ForEach(Array(series.vwap.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.0),
                    y: .value("VWAP", point.1),
                    series: .value("Overlay", "VWAP")
                )
                .foregroundStyle(DesignSystem.vwap)
                .lineStyle(StrokeStyle(lineWidth: 1.4))
            }

            // 20 SMA (steel yellow-ish — short-term trend)
            ForEach(Array(series.sma20.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.0),
                    y: .value("20 SMA", point.1),
                    series: .value("Overlay", "20SMA")
                )
                .foregroundStyle(DesignSystem.amber.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [3, 3]))
            }

            // 50 SMA (amber — medium-term, the resistance line)
            ForEach(Array(series.sma50.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.0),
                    y: .value("50 SMA", point.1),
                    series: .value("Overlay", "50SMA")
                )
                .foregroundStyle(DesignSystem.amber)
                .lineStyle(StrokeStyle(lineWidth: 1.2))
            }

            // Pattern markers — only on the sheet. Bearish triggers point down
            // above the candle (puts entry signal); doji is a small amber dot;
            // hammer is a muted up-triangle below the low (warning for puts).
            if showPatternMarkers {
                ForEach(Array(series.patterns.enumerated()), id: \.offset) { _, hit in
                    let above = hit.pattern.type.tradingBias != .bullish
                    PointMark(
                        x: .value("Time", hit.candle.timestamp),
                        y: .value("Marker", above ? hit.candle.high : hit.candle.low)
                    )
                    .symbolSize(0)  // hide the dot itself; we render via annotation
                    .annotation(position: above ? .top : .bottom, spacing: 2) {
                        PatternMarker(pattern: hit.pattern)
                    }
                }
            }
        }
        .chartYScale(domain: series.priceLow...series.priceHigh)
        .chartXAxis {
            if showAxisLabels {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundStyle(DesignSystem.muted)
                    AxisGridLine().foregroundStyle(DesignSystem.hairline)
                }
            } else {
                AxisMarks { _ in AxisGridLine().foregroundStyle(DesignSystem.hairline.opacity(0.4)) }
            }
        }
        .chartYAxis {
            if showAxisLabels {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel()
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundStyle(DesignSystem.muted)
                    AxisGridLine().foregroundStyle(DesignSystem.hairline)
                }
            } else {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine().foregroundStyle(DesignSystem.hairline.opacity(0.4))
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(DesignSystem.bg)
        }
    }

    @ViewBuilder
    private func selectionOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let origin: CGPoint = proxy.plotFrame.map { geo[$0].origin } ?? .zero
                            let xInPlot = value.location.x - origin.x
                            if let date: Date = proxy.value(atX: xInPlot) {
                                selectedCandle = nearestCandle(to: date)
                            }
                        }
                )
        }
    }

    private func nearestCandle(to date: Date) -> Candle? {
        guard !series.candles.isEmpty else { return nil }
        return series.candles.min(by: { a, b in
            abs(a.timestamp.timeIntervalSince(date)) < abs(b.timestamp.timeIntervalSince(date))
        })
    }
}

// Small pattern annotation chip. Color + shape encode the trading bias; the
// short code keeps it readable when several land in a row.
private struct PatternMarker: View {
    let pattern: CandlestickPattern

    var body: some View {
        VStack(spacing: 1) {
            shape
                .fill(color)
                .frame(width: 8, height: 6)
            Text(pattern.type.shortCode)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 2)
    }

    private var shape: AnyShape {
        // `Triangle` (defined alongside the ratio band) has its tip at the
        // bottom-center → that's a down-pointing triangle. Bearish triggers use
        // it as-is; bullish flips it 180° to point up under the candle.
        switch pattern.type.tradingBias {
        case .bearish: return AnyShape(Triangle())
        case .bullish: return AnyShape(Triangle().rotation(.degrees(180)))
        case .neutral: return AnyShape(Circle())
        }
    }

    private var color: Color {
        let base: Color
        switch pattern.type.tradingBias {
        case .bearish: base = DesignSystem.amber
        case .bullish: base = DesignSystem.steel
        case .neutral: base = DesignSystem.amber.opacity(0.7)
        }
        switch pattern.signal {
        case .strong:   return base
        case .moderate: return base.opacity(0.75)
        case .weak:     return base.opacity(0.5)
        }
    }
}

private struct PhoneCandleStrip: View {
    let symbol: TradingInstrument
    let onTap: () -> Void

    @ObservedObject private var liveTape = LiveTapeService.shared

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("CHART · \(symbol.displayName.uppercased()) · 5M")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.6)
                        .foregroundColor(DesignSystem.amber)
                    Spacer()
                    Text("TAP TO READ →")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.4)
                        .foregroundColor(DesignSystem.muted)
                }

                HStack(alignment: .top, spacing: 10) {
                    chartBlock
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                    readoutBlock
                        .frame(width: 76, alignment: .trailing)
                }

                HStack(spacing: 10) {
                    LegendDot(color: DesignSystem.vwap, label: "VWAP")
                    LegendDot(color: DesignSystem.amber, label: "50 SMA")
                    LegendDot(color: DesignSystem.amber.opacity(0.6), label: "20 SMA")
                    Spacer()
                    if let candleCount = currentSeries?.candles.count {
                        Text("\(candleCount) BARS")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.2)
                            .foregroundColor(DesignSystem.muted)
                    }
                }
            }
            .padding(10)
            .background(DesignSystem.bg1)
            .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var chartBlock: some View {
        if let series = currentSeries, !series.candles.isEmpty {
            PhoneCandleChart(series: series, showAxisLabels: false)
        } else {
            VStack(spacing: 4) {
                Text("NO TAPE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.muted)
                Text("ENABLE LIVE IN SETTINGS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.faint)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.bg)
            .overlay(Rectangle().stroke(DesignSystem.hairline.opacity(0.5), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var readoutBlock: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(priceText)
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(priceAccent)
            Text("PRICE")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.faint)
            Spacer().frame(height: 4)
            Text(ratioText)
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(ratioAccent)
            Text("RATIO")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.faint)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var currentSeries: PhoneChartSeries? {
        let bars = liveTape.lastSnapshot?.vxxCandles ?? []
        guard !bars.isEmpty else { return nil }
        return PhoneChartSeries.build(from: bars, bucketSeconds: 5 * 60)
    }

    private var priceText: String {
        guard let p = liveTape.lastSnapshot?.vxxPrice, p > 0 else { return "—" }
        return String(format: "$%.2f", p)
    }

    private var ratioText: String {
        guard let r = liveTape.lastSnapshot?.ratio, r > 0 else { return "—" }
        return String(format: "%.2f", r)
    }

    private var priceAccent: Color {
        guard let snap = liveTape.lastSnapshot else { return DesignSystem.text }
        return snap.vxxPctChange >= 0 ? DesignSystem.long : DesignSystem.short
    }

    private var ratioAccent: Color {
        guard let r = liveTape.lastSnapshot?.ratio else { return DesignSystem.muted }
        if r >= 1.55 { return DesignSystem.long }
        if r >= 1.45 { return DesignSystem.amber }
        if r < 1.35  { return DesignSystem.short }
        return DesignSystem.steel
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Rectangle().fill(color).frame(width: 8, height: 2)
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.muted)
        }
    }
}

private struct PhoneChartSheet: View {
    let symbol: TradingInstrument

    @ObservedObject private var liveTape = LiveTapeService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var interval: ChartInterval = .fiveMin
    @State private var selectedCandle: Candle?

    enum ChartInterval: String, CaseIterable, Identifiable {
        case oneMin = "1M"
        case fiveMin = "5M"
        case fifteenMin = "15M"

        var id: String { rawValue }
        var bucketSeconds: TimeInterval {
            switch self {
            case .oneMin:     return 60
            case .fiveMin:    return 5 * 60
            case .fifteenMin: return 15 * 60
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            intervalPicker
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            if let series = currentSeries, !series.candles.isEmpty {
                PhoneCandleChart(
                    series: series,
                    showAxisLabels: true,
                    windowStripeOpacity: 0.12,
                    showPatternMarkers: true,
                    enableSelection: true,
                    selectedCandle: $selectedCandle
                )
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 6)
                .background(DesignSystem.bg)

                OHLCVReadout(selected: selectedCandle, avgVolume: series.avgVolume) {
                    selectedCandle = nil
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

                PhoneVolumePanel(series: series)
                    .frame(height: 96)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)

                PhoneRatioTierBand(ratio: liveTape.lastSnapshot?.ratio)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            } else {
                emptyState
            }

            footer
        }
        .background(DesignSystem.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("READ THE TAPE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("\(symbol.displayName.uppercased()) · \(interval.rawValue)")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.text)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.text2)
                    .padding(8)
                    .background(DesignSystem.bg1)
                    .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var intervalPicker: some View {
        HStack(spacing: 6) {
            ForEach(ChartInterval.allCases) { opt in
                Button {
                    interval = opt
                } label: {
                    Text(opt.rawValue)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(opt == interval ? DesignSystem.bg : DesignSystem.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(opt == interval ? DesignSystem.amber : DesignSystem.bg1)
                        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("NO TAPE")
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.muted)
            Text("ENABLE LIVE MODE IN SETTINGS.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.faint)
            Text("CONNECT SCHWAB OAUTH IN SETTINGS.")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.faint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.bg)
    }

    private var footer: some View {
        HStack {
            Text("SCHWAB · 1-MIN BARS AGGREGATED")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            Spacer()
            if let tick = liveTape.lastTickAt {
                Text("LAST · \(Self.tickFormatter.string(from: tick))")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.faint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignSystem.bg1)
        .overlay(Rectangle().frame(height: 1).foregroundColor(DesignSystem.hairline), alignment: .top)
    }

    private var currentSeries: PhoneChartSeries? {
        let bars = liveTape.lastSnapshot?.vxxCandles ?? []
        guard !bars.isEmpty else { return nil }
        return PhoneChartSeries.build(from: bars, bucketSeconds: interval.bucketSeconds)
    }

    private static let tickFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()
}

// MARK: Phone Volume Panel
//
// Sub-panel under the price chart in the fullscreen sheet. Green/red bars by
// candle direction, dashed RuleMark at 2× the 30-period average (the 200%
// institutional-participation threshold from the ToS setup).

private struct PhoneVolumePanel: View {
    let series: PhoneChartSeries

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("VOLUME")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("· 30 AVG · 200% LINE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
                if let last = series.candles.last {
                    let pct = series.avgVolume > 0 ? Double(last.volume) / series.avgVolume * 100 : 0
                    Text(String(format: "LAST %.0f%%", pct))
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(pct >= 200 ? DesignSystem.long : DesignSystem.muted)
                }
            }

            Chart {
                ForEach(series.candles) { c in
                    BarMark(
                        x: .value("Time", c.timestamp),
                        y: .value("Volume", c.volume),
                        width: .ratio(0.65)
                    )
                    .foregroundStyle(c.isBullish ? DesignSystem.long : DesignSystem.short)
                }

                if series.avgVolume > 0 {
                    RuleMark(y: .value("200% Avg", series.avgVolume * 2))
                        .foregroundStyle(DesignSystem.amber)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 2)) { _ in
                    AxisGridLine().foregroundStyle(DesignSystem.hairline.opacity(0.4))
                    AxisValueLabel()
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundStyle(DesignSystem.muted)
                }
            }
            .chartPlotStyle { plot in
                plot.background(DesignSystem.bg)
            }
        }
    }
}

// MARK: Phone Ratio Tier Band
//
// Horizontal level meter for the current VXX/VIX ratio against the 5 tiers from
// the ToS strategy doc. Not a time series — the actionable read on a phone is
// "where are we vs the tiers RIGHT NOW." Bigger zones on the band signal more
// of the ratio's typical operating range, which is roughly 1.30–1.70.

private struct PhoneRatioTierBand: View {
    let ratio: Double?

    private struct Tier {
        let upperBound: Double
        let color: Color
        let label: String
    }

    private static let lowerBound: Double = 1.20
    private static let upperBound: Double = 1.80
    private static let tiers: [Tier] = [
        Tier(upperBound: 1.35, color: DesignSystem.short,                   label: "<1.35 NO FADE"),
        Tier(upperBound: 1.45, color: DesignSystem.amber.opacity(0.45),     label: "1.35-1.45 WEAK"),
        Tier(upperBound: 1.55, color: DesignSystem.amber.opacity(0.85),     label: "1.45-1.55 NORMAL"),
        Tier(upperBound: 1.60, color: DesignSystem.long.opacity(0.55),      label: "1.55-1.60 STRONG"),
        Tier(upperBound: 1.80, color: DesignSystem.long,                    label: "≥1.60 PREMIUM")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("VXX / VIX RATIO")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Spacer()
                Text(readout)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(readoutAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 1) {
                        ForEach(Array(Self.tiers.enumerated()), id: \.offset) { _, tier in
                            Rectangle()
                                .fill(tier.color)
                                .frame(width: zoneWidth(tier: tier, total: geo.size.width))
                        }
                    }
                    .frame(height: 18)
                    .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))

                    if let r = ratio, r > 0 {
                        let x = position(for: r, total: geo.size.width)
                        Rectangle()
                            .fill(DesignSystem.text)
                            .frame(width: 2, height: 22)
                            .offset(x: max(0, min(geo.size.width - 2, x - 1)), y: -2)
                        Triangle()
                            .fill(DesignSystem.text)
                            .frame(width: 8, height: 6)
                            .offset(x: max(0, min(geo.size.width - 8, x - 4)), y: -8)
                    }
                }
            }
            .frame(height: 22)

            HStack {
                Text("1.20").tierLabel()
                Spacer()
                Text("1.35").tierLabel()
                Spacer()
                Text("1.45").tierLabel()
                Spacer()
                Text("1.55").tierLabel()
                Spacer()
                Text("1.60").tierLabel()
                Spacer()
                Text("1.80").tierLabel()
            }
        }
    }

    private func zoneWidth(tier: Tier, total: CGFloat) -> CGFloat {
        let prev = Self.tiers.first(where: { $0.upperBound < tier.upperBound })?.upperBound ?? Self.lowerBound
        let lower = max(prev, Self.lowerBound)
        let span = (tier.upperBound - lower) / (Self.upperBound - Self.lowerBound)
        return max(0, total * CGFloat(span))
    }

    private func position(for ratio: Double, total: CGFloat) -> CGFloat {
        let clamped = min(max(ratio, Self.lowerBound), Self.upperBound)
        let frac = (clamped - Self.lowerBound) / (Self.upperBound - Self.lowerBound)
        return total * CGFloat(frac)
    }

    private var readout: String {
        guard let r = ratio, r > 0 else { return "— · NO LIVE TAPE" }
        return String(format: "%.2f · %@", r, tierLabel(for: r))
    }

    private var readoutAccent: Color {
        guard let r = ratio, r > 0 else { return DesignSystem.muted }
        if r >= 1.60 { return DesignSystem.long }
        if r >= 1.55 { return DesignSystem.long.opacity(0.85) }
        if r >= 1.45 { return DesignSystem.amber }
        if r >= 1.35 { return DesignSystem.amber.opacity(0.7) }
        return DesignSystem.short
    }

    private func tierLabel(for ratio: Double) -> String {
        if ratio >= 1.60 { return "PREMIUM FADE" }
        if ratio >= 1.55 { return "STRONG FADE" }
        if ratio >= 1.45 { return "NORMAL FADE" }
        if ratio >= 1.35 { return "WEAK · CAUTION" }
        return "NO FADE"
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

private extension Text {
    func tierLabel() -> some View {
        self
            .font(DesignSystem.Typography.labelFont)
            .tracking(1.0)
            .foregroundColor(DesignSystem.faint)
    }
}

// MARK: OHLCV Readout
//
// Floating row that surfaces when the user taps/scrubs a candle in the sheet.
// Sparse boiler-room formatting: T · O · H · L · C · V · VOL%. Tap the X to
// clear the selection.

private struct OHLCVReadout: View {
    let selected: Candle?
    let avgVolume: Double
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if let c = selected {
                Group {
                    field("T", value: Self.timeFormatter.string(from: c.timestamp))
                    divider
                    field("O", value: String(format: "%.2f", c.open))
                    divider
                    field("H", value: String(format: "%.2f", c.high), accent: DesignSystem.long)
                    divider
                    field("L", value: String(format: "%.2f", c.low), accent: DesignSystem.short)
                    divider
                    field("C", value: String(format: "%.2f", c.close),
                          accent: c.isBullish ? DesignSystem.long : DesignSystem.short)
                    divider
                    field("V", value: Self.compactVolume(c.volume))
                    divider
                    field("VOL%", value: Self.volPercent(c.volume, avg: avgVolume),
                          accent: c.volume > 0 && avgVolume > 0 && (Double(c.volume) / avgVolume) >= 2 ? DesignSystem.long : DesignSystem.muted)
                }
                Spacer(minLength: 6)
                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignSystem.muted)
                        .frame(width: 22, height: 22)
                        .background(DesignSystem.bg)
                        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Text("TAP A CANDLE FOR OHLCV")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(DesignSystem.bg1)
        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private func field(_ label: String, value: String, accent: Color = DesignSystem.text) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.faint)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 4)
    }

    private var divider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 18)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()

    private static func compactVolume(_ v: Int) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", Double(v) / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0fK", Double(v) / 1_000) }
        return "\(v)"
    }

    private static func volPercent(_ v: Int, avg: Double) -> String {
        guard avg > 0 else { return "—" }
        return String(format: "%.0f%%", Double(v) / avg * 100)
    }
}

// MARK: Phone Clock Footer

private struct PhoneClockFooter: View {
    @State private var now = Date()
    @ObservedObject private var liveTape = LiveTapeService.shared
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
                Text("4:15 CLOSE IN")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.muted)
                Text(sessionCloseCountdown)
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(sessionCloseAccent)
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
        .overlay(alignment: .topTrailing) {
            if liveTape.isLive {
                HStack(spacing: 4) {
                    DeskPulseDot(accent: DesignSystem.long, size: 5)
                    Text("LIVE")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(DesignSystem.long)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DesignSystem.long.opacity(0.10))
                .padding(6)
            }
        }
        .onReceive(timer) { now = $0 }
    }

    private var sessionCloseCountdown: String {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 16
        components.minute = 15
        components.second = 0
        guard let target = cal.date(from: components) else { return "—" }
        let interval = target.timeIntervalSince(now)
        if interval <= 0 { return "CLOSED" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var sessionCloseAccent: Color {
        let cal = Calendar(identifier: .gregorian)
        var components = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        components.hour = 16
        components.minute = 15
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

// MARK: Phone Session-Close Takeover (16:10-16:15 ET)

private struct PhoneHardExitTakeover: View {
    @ObservedObject var signalMonitor: SignalMonitor
    let state: VXXStrategyState
    let openRisk: (() -> Void)?

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("SESSION CLOSE WINDOW")
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

            Text("EXTENDED SESSION CLOSES AT 16:15 ET.")
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

                rule("01", "No fresh quote signals after 16:10.")
                rule("02", "Alert session closes at 16:15 ET.")
                rule("03", "After 16:15, stand down until the next session.")
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
        components.hour = 16
        components.minute = 15
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
        case .volume:
            return "\(Int(entry.volumePercent))%"
        case .window:
            return entry.timeWindow.shortName
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
        case .volume:
            return state.volumeStatus == .pass ? DesignSystem.long : DesignSystem.short
        case .window:
            return state.windowStatus == .pass ? DesignSystem.long : DesignSystem.short
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
        case .volume:       return state.volumeDetail
        case .window:       return state.windowDetail
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
        case .volume:
            let pct = entry?.volumePercent ?? 0
            return [
                Tier(label: "INSTITUTIONAL", range: "300%+",   color: DesignSystem.long,  active: pct >= 300),
                Tier(label: "STANDARD",      range: "200-299%",color: DesignSystem.amber, active: pct >= 200 && pct < 300),
                Tier(label: "BELOW",         range: "<200%",   color: DesignSystem.short, active: pct < 200)
            ]
        case .window:
            let window = entry?.timeWindow
            return [
                Tier(label: "MORNING",       range: "9:50-10:15", color: DesignSystem.long,  active: window == .morning),
                Tier(label: "POWER",         range: "3:10-3:25",  color: DesignSystem.long,  active: window == .powerHour),
                Tier(label: "INSTITUTIONAL", range: "3:45-4:10",  color: DesignSystem.long,  active: window == .institutional),
                Tier(label: "OUTSIDE",       range: "no alert",   color: DesignSystem.short, active: window != nil && !(window?.isVXXEntryWindow ?? false))
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
