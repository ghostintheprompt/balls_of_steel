import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let symbol: String
    let strategy: String
    let entryPrice: Double
    let vwap: Double
    let vxxVixRatio: Double
    let vixLevel: Double
    let tradingWindow: String
    let idempotencyKey: String
    var exitPrice: Double?
    var realizedPnL: Double?
    var outcome: String  // "open", "win", "loss"
}

@MainActor
class TradeJournal: ObservableObject {
    static let shared = TradeJournal()

    @Published private(set) var entries: [JournalEntry] = []
    private let storageKey = "tradeJournalEntries"

    init() { load() }

    func record(signal: Signal, idempotencyKey: String) {
        let vwapCalc = VWAPCalculator.shared
        let bands = vwapCalc.currentBands()
        let entry = JournalEntry(
            id: UUID(),
            timestamp: Date(),
            symbol: signal.symbol,
            strategy: signal.strategy.rawValue,
            entryPrice: signal.entry,
            vwap: bands.vwap,
            vxxVixRatio: signal.entry > 0 ? signal.entry / max(bands.vwap, 1) : 0,
            vixLevel: 0,
            tradingWindow: TimeManager.shared.activeWindow?.displayName ?? "Outside window",
            idempotencyKey: idempotencyKey,
            exitPrice: nil,
            realizedPnL: nil,
            outcome: "open"
        )
        entries.insert(entry, at: 0)
        save()
    }

    func close(id: UUID, exitPrice: Double, pnL: Double) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].exitPrice = exitPrice
        entries[idx].realizedPnL = pnL
        entries[idx].outcome = pnL >= 0 ? "win" : "loss"
        DailyRiskManager.shared.updateClosedTradePnL(pnL)
        save()
    }

    var recentEntries: [JournalEntry] { Array(entries.prefix(10)) }

    var lastEntry: JournalEntry? { entries.first }

    func postTradeAnalysisContext() -> String {
        guard let last = lastEntry else { return "" }
        let pnlStr = last.realizedPnL.map { String(format: "%+.2f", $0) } ?? "open"
        return """
        Trade Journal — Last Entry:
        Symbol: \(last.symbol) | Strategy: \(last.strategy)
        Entry: $\(String(format: "%.2f", last.entryPrice)) | VWAP: $\(String(format: "%.2f", last.vwap))
        Window: \(last.tradingWindow) | VXX/VIX ratio: \(String(format: "%.3f", last.vxxVixRatio))
        Outcome: \(last.outcome.uppercased()) | P&L: \(pnlStr)
        Time: \(DateFormatter.localizedString(from: last.timestamp, dateStyle: .none, timeStyle: .short))
        """
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = saved
    }
}
