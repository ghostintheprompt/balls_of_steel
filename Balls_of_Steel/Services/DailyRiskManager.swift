import Foundation

@MainActor
class DailyRiskManager: ObservableObject {
    static let shared = DailyRiskManager()

    @Published private(set) var tradesExecutedToday: Int = 0
    @Published private(set) var dailyPnL: Double = 0
    @Published private(set) var isTradingLocked: Bool = false
    @Published private(set) var lockReason: String? = nil

    var maxTradesPerDay: Int = 2
    var maxDailyDrawdown: Double = 200.0

    private var lastResetDate: Date?
    private let storageKey = "dailyRiskSnapshot"

    init() {
        loadSnapshot()
        resetIfNewDay()
    }

    func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        guard lastResetDate != today else { return }
        tradesExecutedToday = 0
        dailyPnL = 0
        isTradingLocked = false
        lockReason = nil
        lastResetDate = today
        saveSnapshot()
    }

    func recordTrade(pnl: Double = 0) {
        resetIfNewDay()
        tradesExecutedToday += 1
        dailyPnL += pnl
        evaluateLock()
        saveSnapshot()
    }

    func updateClosedTradePnL(_ delta: Double) {
        dailyPnL += delta
        evaluateLock()
        saveSnapshot()
    }

    func manualUnlock(reason: String = "Manual override") {
        isTradingLocked = false
        lockReason = nil
    }

    private func evaluateLock() {
        if tradesExecutedToday >= maxTradesPerDay {
            isTradingLocked = true
            lockReason = "Daily trade limit reached (\(tradesExecutedToday)/\(maxTradesPerDay) trades)."
        } else if dailyPnL <= -maxDailyDrawdown {
            isTradingLocked = true
            lockReason = "Daily drawdown limit hit (-$\(String(format: "%.0f", abs(dailyPnL))) of $\(Int(maxDailyDrawdown)) max)."
        }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var tradesExecutedToday: Int
        var dailyPnL: Double
        var isTradingLocked: Bool
        var lockReason: String?
        var lastResetDate: Date?
    }

    private func saveSnapshot() {
        let snap = Snapshot(
            tradesExecutedToday: tradesExecutedToday,
            dailyPnL: dailyPnL,
            isTradingLocked: isTradingLocked,
            lockReason: lockReason,
            lastResetDate: lastResetDate
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadSnapshot() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        tradesExecutedToday = snap.tradesExecutedToday
        dailyPnL = snap.dailyPnL
        isTradingLocked = snap.isTradingLocked
        lockReason = snap.lockReason
        lastResetDate = snap.lastResetDate
    }
}
