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
// Live mode is opt-in via Settings -> Systems after Schwab OAuth. When off, the manual tape
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
        let vxxBid: Double
        let vxxAsk: Double
        let vxxCandles: [Candle]      // today's 1m bars from the provider
        let timestamp: Date

        // Bid/ask moves on essentially every real quote tick, unlike the
        // volume aggregate -- the clearest tell that the feed is genuinely
        // live versus just re-showing the last print.
        var vxxSpread: Double { max(vxxAsk - vxxBid, 0) }

        /// VXX moving more than VIX = divergence. Positive = VXX outpacing
        /// (fade-worthy on stretched ratio). Negative = VIX outpacing
        /// (regime move; wait for a cleaner read).
        var divergencePoints: Double { vxxPctChange - vixPctChange }

        var isDiverging: Bool { abs(divergencePoints) >= 0.5 }
    }

    private static let enabledKey = "liveTape.enabled"
    private static let entryKey = "lastMarketDataEntry"
    private static let pollInterval: TimeInterval = 30
    private static let liveAlertCooldown: TimeInterval = 15 * 60
    // One bad tick is noise (a dropped packet, a momentary Schwab hiccup);
    // two in a row (~60s) is a real outage worth waking someone up for.
    private static let disconnectFailureThreshold = 2


    private var pollTask: Task<Void, Never>?
    private var lastLiveAlertSignature: String?
    private var lastLiveAlertAt: Date?
    private var consecutiveFailureCount = 0
    private var isDisconnectAlertActive = false
    private var sleepPreventionActivity: NSObjectProtocol?

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            if newValue { start() } else { stop() }
        }
    }

    private init() {
        if isEnabled, AppConfig.Schwab.hasOAuthTokens {
            start()
        }
    }

    func start() {
        stop()
        // Hold the Mac awake for as long as live tape is on. Without this,
        // a screen lock or idle sleep during market hours silently pauses
        // the poll loop -- exactly the failure mode alerts exist to catch --
        // with no error, no disconnect notification, nothing.
        sleepPreventionActivity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .userInitiated],
            reason: "Steel Trading Desk: live Schwab quote feed"
        )
        pollTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        isLive = false
        consecutiveFailureCount = 0
        isDisconnectAlertActive = false
        if let sleepPreventionActivity {
            ProcessInfo.processInfo.endActivity(sleepPreventionActivity)
        }
        sleepPreventionActivity = nil
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

            let vxx = try await vxxQuote
            let vix = try await vixQuote

            MarketDataService.shared.updateQuoteCache(vxx)
            MarketDataService.shared.updateQuoteCache(vix)

            let entry = composeEntry(vxx: vxx, vix: vix)
            persist(entry)
            lastSnapshot = LiveSnapshot(
                vxxPrice: vxx.price,
                vxxPctChange: pctChange(price: vxx.price, prevClose: vxx.previousClose),
                vixPrice: vix.price,
                vixPctChange: pctChange(price: vix.price, prevClose: vix.previousClose),
                ratio: vix.price > 0 ? vxx.price / vix.price : 0,
                vxxVwap: vxx.vwap,
                vxxBid: vxx.bid,
                vxxAsk: vxx.ask,
                vxxCandles: vxx.recentCandles,
                timestamp: Date()
            )
            lastTickAt = Date()
            lastError = nil
            isLive = true
            consecutiveFailureCount = 0
            if isDisconnectAlertActive {
                isDisconnectAlertActive = false
                SignalNotification.shared.feedRestored()
            }
            handleClearedAlertIfNeeded(entry)
        } catch {
            lastError = error.localizedDescription
            isLive = false
            consecutiveFailureCount += 1
            if consecutiveFailureCount >= Self.disconnectFailureThreshold, !isDisconnectAlertActive {
                isDisconnectAlertActive = true
                SignalNotification.shared.feedDisconnected(reason: error.localizedDescription)
            }
        }
    }

    private func pctChange(price: Double, prevClose: Double) -> Double {
        guard prevClose > 0 else { return 0 }
        return ((price - prevClose) / prevClose) * 100
    }

    // Matches the audited ThinkOrSwim setup exactly (docs/trading docs/
    // thinkorswim_complete_setup_2026.md): volPercent = (volume /
    // Average(volume, 30)) * 100 on 5-minute bars. This app's whole reason
    // to exist is to fire the same strategy without ThinkOrSwim open --
    // the volume gate previously compared today's cumulative volume against
    // a 20-DAY average, a different measurement that could clear or fail
    // independently of what the real, documented strategy says. Rebuilt
    // from the same live 1-minute candles already fetched for the chart,
    // bucketed into 5-minute bars to match.
    private static func volumePercent(from oneMinuteCandles: [Candle], lookback: Int = 30) -> Double {
        let bars = oneMinuteCandles.aggregated(bucketSeconds: 300)
        guard let current = bars.last else { return 0 }
        let history = Array(bars.dropLast().suffix(lookback))
        guard !history.isEmpty else { return 0 }
        let averageVolume = Double(history.reduce(0) { $0 + $1.volume }) / Double(history.count)
        guard averageVolume > 0 else { return 0 }
        return (Double(current.volume) / averageVolume) * 100
    }

    private func composeEntry(vxx: Quote, vix: Quote) -> MarketDataEntry {
        // Preserve only the fields there's no live source of truth for
        // (news risk is judgment, not derivable from price/volume). Pattern,
        // key level, and arrow signal used to silently carry forward
        // whatever was last typed into the Manual Tape sheet, forever --
        // three of the five real strategy gates were never actually computed
        // live. All three now come from the same candles already driving
        // the chart, matching what a real ThinkOrSwim chart shows.
        let previous: MarketDataEntry? = loadPrevious()

        let vwapPosition: VWAPPosition = {
            let epsilon = max(vxx.price * 0.0005, 0.01)
            if vxx.price > vxx.vwap + epsilon { return .above }
            if vxx.price < vxx.vwap - epsilon { return .below }
            return .at
        }()

        let timeWindow = currentTimeWindow()
        let volumePercent = Self.volumePercent(from: vxx.recentCandles)
        let live = Self.liveGateReadout(candles: vxx.recentCandles, price: vxx.price)

        return MarketDataEntry(
            instrument: .vxx,
            price: vxx.price,
            vixLevel: vix.price,
            volumePercent: volumePercent,
            vwapPosition: vwapPosition,
            vwapValue: vxx.vwap,
            arrowSignal: live.arrowSignal,
            keyLevelConfirmed: live.keyLevelConfirmed,
            patternConfirmed: live.patternConfirmed,
            timeWindow: timeWindow,
            newsRisk: previous?.newsRisk ?? .none,
            timestamp: Date()
        )
    }

    private struct LiveGateReadout {
        let patternConfirmed: Bool
        let keyLevelConfirmed: Bool
        let arrowSignal: ArrowSignalInput
    }

    // Real pattern/key-level/arrow detection off the same live candles
    // already used for the chart -- no fabricated data, and no dependency
    // on the options/earnings/SPY fields the old MarketData-based
    // ArrowSignalDetector call would have needed to fake.
    private static func liveGateReadout(candles: [Candle], price: Double) -> LiveGateReadout {
        guard candles.count >= 20 else {
            return LiveGateReadout(patternConfirmed: false, keyLevelConfirmed: false, arrowSignal: .none)
        }

        let supportResistance = SupportResistance.calculate(candles: candles)
        let recognizer = PatternRecognizer()
        let avgVolume = Int(IndicatorCalculator.calculateVolumeAverage(candles: candles, period: 30))
        let patternHits = recognizer.detectPatternsAcrossSeries(candles: candles, averageVolume: avgVolume)
        let lastCandle = candles.last
        let hasPattern = patternHits.contains { $0.candle.timestamp == lastCandle?.timestamp }

        guard let indicators = IndicatorCalculator.calculateAll(candles: candles) else {
            // Not enough candles yet for the 50 SMA (first ~50 minutes of the
            // session) -- pattern/key-level can still be real, arrow can't.
            let keyLevel = supportResistance.isNearSupport(price) || supportResistance.isNearResistance(price)
            return LiveGateReadout(patternConfirmed: hasPattern, keyLevelConfirmed: keyLevel, arrowSignal: .none)
        }

        let nearSMA50 = indicators.sma50 > 0 && abs(price - indicators.sma50) / indicators.sma50 < 0.003
        let nearVWAP = indicators.vwap > 0 && abs(price - indicators.vwap) / indicators.vwap < 0.003
        let keyLevel = supportResistance.isNearSupport(price)
            || supportResistance.isNearResistance(price)
            || nearSMA50
            || nearVWAP

        let previousCandle = candles.count >= 2 ? candles[candles.count - 2] : nil
        let arrow = ArrowSignalDetector.detectArrowSignal(
            technicalIndicators: indicators,
            timestamp: Date(),
            hasPattern: hasPattern,
            previousCandle: previousCandle,
            supportResistance: supportResistance
        )

        let arrowInput: ArrowSignalInput
        switch arrow?.direction {
        case .bullish: arrowInput = .bullish
        case .bearish: arrowInput = .bearish
        case nil: arrowInput = .none
        }

        return LiveGateReadout(patternConfirmed: hasPattern, keyLevelConfirmed: keyLevel, arrowSignal: arrowInput)
    }

    private func loadPrevious() -> MarketDataEntry? {
        guard let data = UserDefaults.standard.data(forKey: Self.entryKey) else { return nil }
        return try? JSONDecoder().decode(MarketDataEntry.self, from: data)
    }

    private func persist(_ entry: MarketDataEntry) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        UserDefaults.standard.set(data, forKey: Self.entryKey)
    }

    private func handleClearedAlertIfNeeded(_ entry: MarketDataEntry) {
        guard liveEntryIsCleared(entry) else { return }

        let now = Date()
        let signature = liveAlertSignature(for: entry, now: now)
        if signature == lastLiveAlertSignature,
           let lastLiveAlertAt,
           now.timeIntervalSince(lastLiveAlertAt) < Self.liveAlertCooldown {
            return
        }

        lastLiveAlertSignature = signature
        lastLiveAlertAt = now
        SignalMonitor.shared.handleLiveTapeSignal(liveSignal(for: entry, now: now))
    }

    private func liveEntryIsCleared(_ entry: MarketDataEntry) -> Bool {
        entry.instrument == .vxx &&
        entry.volumePercent >= entry.timeWindow.requiredVolumePercent &&
        entry.timeWindow.isVXXEntryWindow &&
        entry.ratio >= StrategySpec.minimumRatioForEntry &&
        entry.keyLevelConfirmed &&
        entry.patternConfirmed
    }

    private func liveSignal(for entry: MarketDataEntry, now: Date) -> Signal {
        let entryPrice = entry.price
        return Signal(
            symbol: entry.instrument.symbol,
            strategy: liveStrategy(for: entry.timeWindow),
            direction: .bearish,
            entry: entryPrice,
            stop: entryPrice * 1.01,
            target: entryPrice * 0.98,
            timestamp: now,
            confidence: liveConfidence(for: entry),
            setupQuality: liveSetupQuality(for: entry),
            positionSizePercent: livePositionSize(for: entry),
            kind: .entry,
            vix: entry.vixLevel,
            vxxVixRatio: entry.ratio
        )
    }

    private func liveStrategy(for window: TimeWindowInput) -> Strategy {
        switch window {
        case .morning:
            return .vxxMorningWindow
        case .powerHour:
            return .vxxPowerHour
        case .institutional:
            return .vxxInstitutionalFlow
        default:
            return .vxxFadeSetup
        }
    }

    private func liveConfidence(for entry: MarketDataEntry) -> Double {
        let volumeScore = min(entry.volumePercent / max(entry.timeWindow.requiredVolumePercent, 1), 1.0)
        let ratioScore = min(entry.ratio / StrategySpec.minimumRatioForEntry, 1.0)
        return min((volumeScore + ratioScore + 1.0) / 3.0, 0.98)
    }

    private func liveSetupQuality(for entry: MarketDataEntry) -> Strategy.SetupQuality {
        if entry.ratio >= 1.60,
           entry.volumePercent >= entry.timeWindow.requiredVolumePercent * 1.25 {
            return .perfect
        }
        return .good
    }

    private func livePositionSize(for entry: MarketDataEntry) -> Double {
        liveStrategy(for: entry.timeWindow).getPositionSize(
            vix: entry.vixLevel,
            setupQuality: liveSetupQuality(for: entry)
        )
    }

    private func liveAlertSignature(for entry: MarketDataEntry, now: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "yyyy-MM-dd"
        return [
            formatter.string(from: now),
            entry.timeWindow.rawValue,
            entry.ratioTier
        ].joined(separator: "|")
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
