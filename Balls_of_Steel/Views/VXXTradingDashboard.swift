import SwiftUI

// MARK: - VXX Trading Dashboard
// Enhanced dashboard specifically for VXX trading with ThinkOrSwim-style indicators

struct VXXTradingDashboard: View {
    @StateObject private var viewModel = VXXDashboardViewModel()
    @ObservedObject var signalMonitor: SignalMonitor
    @ObservedObject private var timeManager = TimeManager.shared
    @ObservedObject private var riskManager = DailyRiskManager.shared

    private var isExecutionBlocked: Bool {
        !timeManager.isTradingWindowOpen || riskManager.isTradingLocked
    }

    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(spacing: 16) {
                        TestSessionBanner()
                            .padding(.horizontal)

                        if isExecutionBlocked {
                            TradingLockBanner(
                                windowOpen: timeManager.isTradingWindowOpen,
                                lockReason: riskManager.lockReason,
                                activeWindow: timeManager.activeWindow
                            )
                            .padding(.horizontal)
                        }

                        marketStatusSection

                        if let nextWindow = viewModel.nextTradingWindow {
                            TradingWindowAlertView(
                                window: nextWindow.window,
                                minutesUntil: nextWindow.minutesUntil
                            )
                            .padding(.horizontal)
                        }

                        CloseManagementCard(
                            title: "VXX Close Management",
                            warningTime: AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalWarningTime),
                            hardExitTime: AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.generalHardExitTime),
                            note: "VXX can carry real late flow. Warn first, then leave enough runway for the move that actually matters."
                        )
                        .padding(.horizontal)

                        if let ratioData = viewModel.vxxVixRatio {
                            VXXVIXRatioView(ratio: ratioData)
                                .padding(.horizontal)
                        }

                        if let indicators = viewModel.technicalIndicators {
                            TechnicalIndicatorsCard(indicators: indicators)
                                .padding(.horizontal)
                        }

                        if !viewModel.detectedPatterns.isEmpty {
                            patternsSection
                        }

                        vxxSignalsSection

                        if viewModel.showOptionsChain, let optionsChain = viewModel.optionsChain {
                            OptionsChainQuickView(optionsChain: optionsChain)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("VXX Desk")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { viewModel.refreshAll() }) {
                            Label("Refresh All", systemImage: "arrow.clockwise")
                        }
                        Button(action: { viewModel.showOptionsChain.toggle() }) {
                            Label(viewModel.showOptionsChain ? "Hide Options" : "Show Options",
                                  systemImage: "chart.bar.doc.horizontal")
                        }
                        Button(action: { viewModel.toggleAlerts() }) {
                            Label("Configure Alerts", systemImage: "bell.badge")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DesignSystem.primaryColor)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.startMonitoring()
        }
    }

    // MARK: - Market Status Section
    private var marketStatusSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("VXX TAPE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .foregroundColor(DesignSystem.mutedText)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(viewModel.vxxPrice, specifier: "%.2f")")
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)

                    Text("\(viewModel.vxxChangePercent, specifier: "%+.2f")%")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(viewModel.vxxChangePercent >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                }

                Text("Wait until vol actually gets loud.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: viewModel.vxxChangePercent >= 0 ? DesignSystem.bullishColor.opacity(0.14) : DesignSystem.bearishColor.opacity(0.14))

            VStack(alignment: .leading, spacing: 8) {
                Text("VIX PRESSURE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.1)
                    .foregroundColor(DesignSystem.mutedText)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.vixLevel, specifier: "%.2f")")
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)

                    Text("\(viewModel.vixChangePercent, specifier: "%+.2f")%")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(viewModel.vixChangePercent >= 0 ? DesignSystem.dangerColor : DesignSystem.bullishColor)
                }

                Text(viewModel.vixChangePercent >= 0 ? "Fear is rising. Make it prove itself." : "Pressure is easing. Fade carefully.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .deskPanel(glow: DesignSystem.warningColor.opacity(0.12))
        }
        .padding(.horizontal)
    }

    // MARK: - Patterns Section
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DeskSectionHeader(title: "Pattern Pressure", systemImage: "chart.bar.fill", accent: DesignSystem.primaryColor)
                Spacer()
                DeskCountBadge(value: "\(viewModel.detectedPatterns.count)", accent: DesignSystem.primaryColor)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.detectedPatterns, id: \.timestamp) { pattern in
                        PatternCard(pattern: pattern)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - VXX Signals Section
    private var vxxSignalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DeskSectionHeader(title: "VXX Signals", systemImage: "bolt.fill", accent: DesignSystem.warningColor)
                Spacer()
                DeskCountBadge(value: "\(vxxSignals.count)", accent: DesignSystem.warningColor)
            }
            .padding(.horizontal)

            if vxxSignals.isEmpty {
                InfoCard {
                    Text("No volatility setup. Good. Wait until it actually gets loud.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            } else {
                ForEach(vxxSignals) { signal in
                    EnhancedSignalRowView(
                        signal: signal,
                        pattern: viewModel.detectedPatterns.first,
                        indicators: viewModel.technicalIndicators
                    )
                    .padding(.horizontal)
                    .swipeActions {
                        Button("Trade") {
                            signalMonitor.startTrade(signal)
                        }
                        .tint(isExecutionBlocked ? .gray : .green)
                        .disabled(isExecutionBlocked)

                        Button("Dismiss") {
                            viewModel.dismissSignal(signal)
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }

    private var vxxSignals: [Signal] {
        signalMonitor.activeSignals.filter { $0.symbol == "VXX" }
    }
}

// MARK: - Trading Lock Banner
struct TradingLockBanner: View {
    let windowOpen: Bool
    let lockReason: String?
    let activeWindow: VXXTradingWindow?

    private var isRiskLocked: Bool { lockReason != nil }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRiskLocked ? "lock.fill" : "clock.fill")
                .font(.title3)
                .foregroundColor(isRiskLocked ? DesignSystem.bearishColor : DesignSystem.warningColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(isRiskLocked ? "TRADING LOCKED" : "OUTSIDE TRADING WINDOW")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.0)
                    .foregroundColor(DesignSystem.primaryText)

                Text(bannerMessage)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill((isRiskLocked ? DesignSystem.bearishColor : DesignSystem.warningColor).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isRiskLocked ? DesignSystem.bearishColor : DesignSystem.warningColor).opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var bannerMessage: String {
        if let reason = lockReason { return reason }
        if let window = nextWindowHint() { return "Next window: \(window)" }
        return "Execution disabled outside defined trading windows."
    }

    private func nextWindowHint() -> String? {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: Date())
        guard let h = comps.hour, let m = comps.minute else { return nil }
        let t = h * 60 + m
        let windows: [(String, Int)] = [
            ("Morning 9:50 AM", 9*60+50),
            ("Lunch 12:20 PM", 12*60+20),
            ("Power Hour 3:10 PM", 15*60+10),
            ("Institutional 3:45 PM", 15*60+45),
        ]
        return windows.first(where: { $0.1 > t })?.0
    }
}

// MARK: - Pattern Card
struct PatternCard: View {
    let pattern: CandlestickPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patternIcon)
                    .foregroundColor(patternColor)
                Text(pattern.type.rawValue)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
            }

            Text(pattern.type.description)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
                .lineLimit(2)

            HStack {
                Text(pattern.signal == .strong ? "Strong" : pattern.signal == .moderate ? "Moderate" : "Weak")
                    .font(DesignSystem.Typography.labelFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(strengthColor)
                    .cornerRadius(4)

                Spacer()

                Text("\(pattern.strength * 100, specifier: "%.0f")%")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(patternColor)
            }
        }
        .deskPanel(glow: patternColor.opacity(0.14), padding: 14)
        .frame(width: 200)
    }

    private var patternIcon: String {
        switch pattern.type {
        case .shootingStar: return "arrow.down.right.circle.fill"
        case .doji: return "minus.circle.fill"
        case .hammer: return "arrow.up.right.circle.fill"
        case .hangingMan: return "arrow.down.right.circle.fill"
        }
    }

    private var patternColor: Color {
        switch pattern.type.tradingBias {
        case .bearish: return .red
        case .bullish: return .green
        case .neutral: return .orange
        }
    }

    private var strengthColor: Color {
        switch pattern.signal {
        case .strong: return .green
        case .moderate: return .orange
        case .weak: return .gray
        }
    }
}

// MARK: - Options Chain Quick View
struct OptionsChainQuickView: View {
    let optionsChain: OptionsChain

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(DesignSystem.primaryColor)
                Text("Options Chain (0-4 DTE)")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Top OTM Puts")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)

                ForEach(topPuts.prefix(3), id: \.strike) { contract in
                    OptionContractRow(contract: contract, type: .put)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Top OTM Calls")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)

                ForEach(topCalls.prefix(3), id: \.strike) { contract in
                    OptionContractRow(contract: contract, type: .call)
                }
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.1))
    }

    private var topPuts: [OptionContract] {
        // 1-2 strikes OTM
        optionsChain.puts
            .filter { $0.strike < optionsChain.underlyingPrice }
            .sorted { abs($0.strike - optionsChain.underlyingPrice) < abs($1.strike - optionsChain.underlyingPrice) }
    }

    private var topCalls: [OptionContract] {
        // 1-2 strikes OTM
        optionsChain.calls
            .filter { $0.strike > optionsChain.underlyingPrice }
            .sorted { abs($0.strike - optionsChain.underlyingPrice) < abs($1.strike - optionsChain.underlyingPrice) }
    }
}

struct OptionContractRow: View {
    let contract: OptionContract
    let type: OptionType

    enum OptionType {
        case call, put
    }

    var body: some View {
        HStack {
            Text("$\(contract.strike, specifier: "%.0f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(DesignSystem.primaryText)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(contract.last, specifier: "%.2f")")
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text("IV: \(contract.impliedVolatility, specifier: "%.0f")%")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Text("Δ \(contract.delta, specifier: "%.2f")")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(type == .call ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((type == .call ? DesignSystem.bullishColor : DesignSystem.bearishColor).opacity(0.12))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
@MainActor
class VXXDashboardViewModel: ObservableObject {
    @Published var vxxPrice: Double = 0
    @Published var vxxChangePercent: Double = 0
    @Published var vixLevel: Double = 0
    @Published var vixChangePercent: Double = 0
    @Published var vxxVixRatio: VXXVIXRatio?
    @Published var technicalIndicators: TechnicalIndicators?
    @Published var detectedPatterns: [CandlestickPattern] = []
    @Published var nextTradingWindow: (window: VXXTradingWindow, minutesUntil: Int)?
    @Published var optionsChain: OptionsChain?
    @Published var showOptionsChain: Bool = false

    private let schwabService = SchwabService.shared
    private let patternRecognizer = PatternRecognizer()
    private var monitoringTask: Task<Void, Never>?

    func startMonitoring() async {
        monitoringTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }

    func refresh() async {
        await fetchVXXVIXData()
        await fetchTechnicalIndicators()
        await detectPatterns()
        checkTradingWindows()

        if showOptionsChain {
            await fetchOptionsChain()
        }
    }

    func refreshAll() {
        Task {
            await refresh()
        }
    }

    private func fetchVXXVIXData() async {
        do {
            let (vxxQuote, vixQuote) = try await schwabService.fetchVXXVIXData()

            vxxPrice = vxxQuote.price
            vxxChangePercent = ((vxxQuote.price - vxxQuote.previousClose) / vxxQuote.previousClose) * 100

            vixLevel = vixQuote.price
            vixChangePercent = ((vixQuote.price - vixQuote.previousClose) / vixQuote.previousClose) * 100

            vxxVixRatio = VXXVIXRatio(vxx: vxxPrice, vix: vixLevel)
        } catch {
            #if DEBUG
            print("Error fetching VXX/VIX data: \(error)")
            #endif
        }
    }

    private func fetchTechnicalIndicators() async {
        do {
            let candles = try await schwabService.fetchHistoricalCandles(symbol: "VXX", period: .fiveMinutes, days: 5)

            // Fetch IV
            let ivData = try await schwabService.fetchImpliedVolatility(symbol: "VXX")

            technicalIndicators = IndicatorCalculator.calculateAll(
                candles: candles,
                impliedVolatility: ivData.iv
            )
        } catch {
            #if DEBUG
            print("Error fetching technical indicators: \(error)")
            #endif
        }
    }

    private func detectPatterns() async {
        do {
            let candles = try await schwabService.fetchHistoricalCandles(symbol: "VXX", period: .fiveMinutes, days: 2)

            let volumeAvg = Int(IndicatorCalculator.calculateVolumeAverage(candles: candles, period: 30))
            detectedPatterns = patternRecognizer.detectPatterns(candles: candles, averageVolume: volumeAvg)
        } catch {
            #if DEBUG
            print("Error detecting patterns: \(error)")
            #endif
        }
    }

    private func checkTradingWindows() {
        let now = Date()
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!

        let components = calendar.dateComponents(in: easternTimeZone, from: now)
        guard let hour = components.hour, let minute = components.minute else { return }

        let currentMinutes = hour * 60 + minute

        // Define windows
        let windows: [(VXXTradingWindow, Int)] = [
            (.morning, 9 * 60 + 50),    // 9:50 AM
            (.lunch, 12 * 60 + 20),      // 12:20 PM
            (.powerHour, 15 * 60 + 10)   // 3:10 PM
        ]

        // Find next window
        for (window, windowMinutes) in windows {
            if currentMinutes < windowMinutes {
                nextTradingWindow = (window, windowMinutes - currentMinutes)
                return
            }
        }

        nextTradingWindow = nil
    }

    private func fetchOptionsChain() async {
        do {
            optionsChain = try await schwabService.fetchOptionsChain(symbol: "VXX", daysToExpiration: 4)
        } catch {
            #if DEBUG
            print("Error fetching options chain: \(error)")
            #endif
        }
    }

    func dismissSignal(_ signal: Signal) {
        // Implement signal dismissal logic
    }

    func toggleAlerts() {
        // Implement alerts configuration
    }

    deinit {
        monitoringTask?.cancel()
    }
}
