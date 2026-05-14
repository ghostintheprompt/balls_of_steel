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
            lastTickAt = Date()
            lastError = nil
            isLive = true
        } catch {
            lastError = error.localizedDescription
            isLive = false
        }
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
    private func currentTimeWindow() -> TimeWindowInput {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: Date())
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let t = h * 60 + m

        switch t {
        case ..<(9 * 60 + 30):                   return .preMarket
        case (9 * 60 + 30)..<(10 * 60 + 5):      return .open
        case (9 * 60 + 50)..<(10 * 60 + 15):     return .morning
        case (12 * 60 + 20)..<(12 * 60 + 40):    return .lunch
        case (13 * 60 + 30)..<(15 * 60 + 10):    return .afternoonFlex
        case (15 * 60 + 10)..<(15 * 60 + 25):    return .powerHour
        case (15 * 60 + 30)..<(15 * 60 + 45):    return .close
        case (15 * 60 + 45)..<(16 * 60 + 10):    return .institutional
        case (16 * 60 + 10)...:                  return .afterHours
        default:                                  return .morning
        }
    }
}
