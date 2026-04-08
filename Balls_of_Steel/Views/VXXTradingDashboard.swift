import SwiftUI

// MARK: - VXX Trading Dashboard
// Enhanced dashboard specifically for VXX trading with ThinkOrSwim-style indicators

struct VXXTradingDashboard: View {
    @StateObject private var viewModel = VXXDashboardViewModel()
    @ObservedObject var signalMonitor: SignalMonitor

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TestSessionBanner()
                        .padding(.horizontal)

                    // Market Phase & VXX Status
                    marketStatusSection

                    // Trading Window Alerts
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
                        note: "Institutional flow can stretch to \(AppConfig.CloseManagement.displayTime(AppConfig.CloseManagement.institutionalHardExitTime)), so the app warns first and still leaves room for the later VXX flow."
                    )
                    .padding(.horizontal)

                    // VXX/VIX Ratio Monitor
                    if let ratioData = viewModel.vxxVixRatio {
                        VXXVIXRatioView(ratio: ratioData)
                            .padding(.horizontal)
                    }

                    // Technical Indicators
                    if let indicators = viewModel.technicalIndicators {
                        TechnicalIndicatorsCard(indicators: indicators)
                            .padding(.horizontal)
                    }

                    // Detected Patterns
                    if !viewModel.detectedPatterns.isEmpty {
                        patternsSection
                    }

                    // Active VXX Signals
                    vxxSignalsSection

                    // Options Chain Quick View
                    if viewModel.showOptionsChain, let optionsChain = viewModel.optionsChain {
                        OptionsChainQuickView(optionsChain: optionsChain)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("VXX Trading System")
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
            // VXX Price Card
            VStack(alignment: .leading, spacing: 8) {
                Text("VXX")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(viewModel.vxxPrice, specifier: "%.2f")")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)

                    Text("\(viewModel.vxxChangePercent, specifier: "%+.2f")%")
                        .font(.subheadline)
                        .foregroundColor(viewModel.vxxChangePercent >= 0 ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 2)
            )

            // VIX Card
            VStack(alignment: .leading, spacing: 8) {
                Text("VIX")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.vixLevel, specifier: "%.2f")")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)

                    Text("\(viewModel.vixChangePercent, specifier: "%+.2f")%")
                        .font(.subheadline)
                        .foregroundColor(viewModel.vixChangePercent >= 0 ? .red : .green)
                }
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

    // MARK: - Patterns Section
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                Text("Detected Patterns")
                    .font(.headline)
                Spacer()
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
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("VXX Signals")
                    .font(.headline)
                Spacer()
                Text("\(vxxSignals.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            if vxxSignals.isEmpty {
                Text("No active VXX signals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
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
                        .tint(.green)

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

// MARK: - Pattern Card
struct PatternCard: View {
    let pattern: CandlestickPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patternIcon)
                    .foregroundColor(patternColor)
                Text(pattern.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(pattern.type.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text(pattern.signal == .strong ? "Strong" : pattern.signal == .moderate ? "Moderate" : "Weak")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(strengthColor)
                    .cornerRadius(4)

                Spacer()

                Text("\(pattern.strength * 100, specifier: "%.0f")%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(patternColor)
            }
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(patternColor.opacity(0.3), lineWidth: 2)
                )
        )
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
                    .foregroundColor(.blue)
                Text("Options Chain (0-4 DTE)")
                    .font(.headline)
                Spacer()
            }

            // Top 3 OTM Puts (for fade setups)
            VStack(alignment: .leading, spacing: 8) {
                Text("Top OTM Puts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(topPuts.prefix(3), id: \.strike) { contract in
                    OptionContractRow(contract: contract, type: .put)
                }
            }

            Divider()

            // Top 3 OTM Calls (for reversal setups)
            VStack(alignment: .leading, spacing: 8) {
                Text("Top OTM Calls")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(topCalls.prefix(3), id: \.strike) { contract in
                    OptionContractRow(contract: contract, type: .call)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
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
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(contract.last, specifier: "%.2f")")
                    .font(.system(.caption, design: .monospaced))
                Text("IV: \(contract.impliedVolatility, specifier: "%.0f")%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("Δ \(contract.delta, specifier: "%.2f")")
                .font(.caption2)
                .foregroundColor(type == .call ? .green : .red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((type == .call ? Color.green : Color.red).opacity(0.1))
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
