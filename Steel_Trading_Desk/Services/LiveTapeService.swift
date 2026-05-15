import Foundation
import Combine

// MARK: - LiveTapeService
//
// Bridges `MarketDataRegistry` (the active provider) to `MarketDataEntry`
// (the gate evaluator's input). Polls VXX + VIX every `pollInterval` seconds
// while enabled, composes a `MarketDataEntry`, and writes it to the same
// `lastMarketDataEntry` UserDefaults key the manual tape view uses. The desk
// re-renders automatically because `TradingDashboard` observes that key via
// `@AppStorage`.
//
// Live mode is opt-in via Settings → Data Source. When off, the manual tape
// remains the only source of truth.

@MainActor
final class LiveTapeService: ObservableObject {
    static let shared = LiveTapeService()

    @Published private(set) var isLive: Bool = false
    @Published private(set) var lastTickAt: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var lastSnapshot: LiveSnapshot?

    /// Captures the live divergence read between VXX and VIX. The ratio gate
    /// looks at absolute ratio; this snapshot adds the *direction* of the move
    /// — VXX outpacing VIX is the fade-worthy expansion the strategy is built
    /// around.
    struct LiveSnapshot {
        let vxxPrice: Double
        let vxxPctChange: Double      // vs previous close, %
        let vixPrice: Double
        let vixPctChange: Double      // vs previous close, %
        let ratio: Double
        let vxxVwap: Double
        let vxxCandles: [Candle]      // today's 1m bars from the provider
        let timestamp: Date

        /// VXX moving more than VIX = divergence. Positive = VXX outpacing
        /// (fade-worthy on stretched ratio). Negative = VIX outpacing
        /// (regime move; ratio likely compressing).
        var divergencePoints: Double { vxxPctChange - vixPctChange }

        var isDiverging: Bool { abs(divergencePoints) >= 0.5 }
    }

    private static let enabledKey = "liveTape.enabled"
    private static let entryKey = "lastMarketDataEntry"
    private static let pollInterval: TimeInterval = 30

    private var pollTask: Task<Void, Never>?

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            if newValue { start() } else { stop() }
        }
    }

    private init() {
        if isEnabled { start() }
    }

    func start() {
        stop()
        pollTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        isLive = false
    }

    /// Force a single tick; useful for the "Refresh now" button in Settings.
    func tickNow() async {
        await fetchAndPersist()
    }

    private func pollLoop() async {
        while !Task.isCancelled {
            await fetchAndPersist()
            try? await Task.sleep(nanoseconds: UInt64(Self.pollInterval * 1_000_000_000))
        }
    }

    private func fetchAndPersist() async {
        let provider = MarketDataRegistry.shared.active
        do {
            async let vxxQuote = provider.quote("VXX")
            async let vixQuote = provider.quote("^VIX")
            async let volMultiple = provider.volumeVsAvg("VXX", period: 20)

            let vxx = try await vxxQuote
            let vix = try await vixQuote
            let volMul = (try? await volMultiple) ?? 0

            let entry = composeEntry(vxx: vxx, vix: vix, volumeMultiple: volMul)
            persist(entry)
            lastSnapshot = LiveSnapshot(
                vxxPrice: vxx.price,
                vxxPctChange: pctChange(price: vxx.price, prevClose: vxx.previousClose),
                vixPrice: vix.price,
                vixPctChange: pctChange(price: vix.price, prevClose: vix.previousClose),
                ratio: vix.price > 0 ? vxx.price / vix.price : 0,
                vxxVwap: vxx.vwap,
                vxxCandles: vxx.recentCandles,
                timestamp: Date()
            )
            lastTickAt = Date()
            lastError = nil
            isLive = true
        } catch {
            lastError = error.localizedDescription
            isLive = false
        }
    }

    private func pctChange(price: Double, prevClose: Double) -> Double {
        guard prevClose > 0 else { return 0 }
        return ((price - prevClose) / prevClose) * 100
    }

    private func composeEntry(vxx: Quote, vix: Quote, volumeMultiple: Double) -> MarketDataEntry {
        // Preserve user-set fields (level, pattern, news, arrow) from the existing
        // entry so live mode doesn't overwrite manual confirmations.
        let previous: MarketDataEntry? = loadPrevious()

        let vwapPosition: VWAPPosition = {
            let epsilon = max(vxx.price * 0.0005, 0.01)
            if vxx.price > vxx.vwap + epsilon { return .above }
            if vxx.price < vxx.vwap - epsilon { return .below }
            return .at
        }()

        let timeWindow = currentTimeWindow()
        let volumePercent = volumeMultiple > 0 ? volumeMultiple * 100 : 0

        return MarketDataEntry(
            instrument: .vxx,
            price: vxx.price,
            vixLevel: vix.price,
            volumePercent: volumePercent,
            vwapPosition: vwapPosition,
            arrowSignal: previous?.arrowSignal ?? .none,
            keyLevelConfirmed: previous?.keyLevelConfirmed ?? false,
            patternConfirmed: previous?.patternConfirmed ?? false,
            timeWindow: timeWindow,
            newsRisk: previous?.newsRisk ?? .none,
            timestamp: Date()
        )
    }

    private func loadPrevious() -> MarketDataEntry? {
        guard let data = UserDefaults.standard.data(forKey: Self.entryKey) else { return nil }
        return try? JSONDecoder().decode(MarketDataEntry.self, from: data)
    }

    private func persist(_ entry: MarketDataEntry) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        UserDefaults.standard.set(data, forKey: Self.entryKey)
    }

    /// Map the current ET clock to the closest `TimeWindowInput` case.
    ///
    /// IMPORTANT: cases are ordered so the doc's three high-conviction entry
    /// windows (Morning 9:50-10:15, Power 15:10-15:25, Institutional 15:45-16:10
    /// per StrategySpec) WIN over the surrounding bookend cases. Earlier
    /// drift had `.open` (9:30-10:05) matching first and silently shadowing
    /// the first 15 minutes of `.morning`. Fixed 2026-05-14.
    private func currentTimeWindow() -> TimeWindowInput {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: Date())
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let t = h * 60 + m

        // Entry windows checked first so they take precedence over `.open` /
        // `.close` / `.afternoonFlex` bookends.
        if t >= StrategySpec.morningWindow.startMinutes && t < StrategySpec.morningWindow.endMinutes {
            return .morning
        }
        if t >= StrategySpec.powerHourWindow.startMinutes && t < StrategySpec.powerHourWindow.endMinutes {
            return .powerHour
        }
        if t >= StrategySpec.institutionalWindow.startMinutes && t < StrategySpec.institutionalWindow.endMinutes {
            return .institutional
        }

        switch t {
        case ..<StrategySpec.preMarketCutoffMinutes:        return .preMarket
        case StrategySpec.preMarketCutoffMinutes..<(9 * 60 + 50):
            return .open                                    // 9:30 → 9:50
        case (10 * 60 + 15)..<(12 * 60 + 20):
            return .afternoonFlex                           // 10:15 → 12:20 dead zone
        case (12 * 60 + 20)..<(12 * 60 + 40):
            return .lunch                                   // 12:20-12:40 (NOT an entry window)
        case (12 * 60 + 40)..<(15 * 60 + 10):
            return .afternoonFlex                           // 12:40 → 15:10
        case (15 * 60 + 25)..<(15 * 60 + 45):
            return .close                                   // 15:25 → 15:45 dead zone between Power and Institutional
        case StrategySpec.afterHoursMinutes...:
            return .afterHours
        default:
            return .afternoonFlex
        }
    }
}
