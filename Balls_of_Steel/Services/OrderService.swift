import Foundation

@MainActor
class OrderService: ObservableObject {
    static let shared = OrderService()

    private let schwabService = SchwabService.shared
    private let optionsCalculator = OptionsCalculator.shared
    private let riskManager = DailyRiskManager.shared
    private let idempotencyStorageKey = "pendingOrderIdempotencyKeys"

    var isTradingLocked: Bool { riskManager.isTradingLocked }
    var lockReason: String? { riskManager.lockReason }

    func submitOrder(signal: Signal) async throws -> OrderResponse {
        riskManager.resetIfNewDay()

        guard !riskManager.isTradingLocked else {
            throw TradeError.tradingLocked(riskManager.lockReason ?? "Daily limit reached.")
        }

        let idempotencyKey = UUID().uuidString
        guard !isDuplicateOrder(key: idempotencyKey) else {
            throw TradeError.duplicateOrder
        }
        registerPendingKey(idempotencyKey)

        let optionsEntry = optionsCalculator.calculateOptionsEntry(
            stockPrice: signal.entry,
            strategy: signal.strategy
        )

        guard let contract = try await getBestContract(
            symbol: signal.symbol,
            strike: optionsEntry.strike,
            type: optionsEntry.type
        ) else {
            clearPendingKey(idempotencyKey)
            throw TradeError.noSuitableOptions
        }

        let order = Order(
            symbol: signal.symbol,
            quantity: 1,
            orderType: .limit,
            price: contract.ask,
            strategy: signal.strategy,
            timestamp: Date()
        )

        let response = try await schwabService.placeOrder(order: order)
        clearPendingKey(idempotencyKey)
        riskManager.recordTrade()
        TradeJournal.shared.record(signal: signal, idempotencyKey: idempotencyKey)
        return response
    }

    private func getBestContract(
        symbol: String,
        strike: Double,
        type: OptionType
    ) async throws -> OptionContract? {
        let _ = try await schwabService.fetchOptionsChain(symbol: symbol)
        return nil
    }

    // MARK: - Idempotency

    private func isDuplicateOrder(key: String) -> Bool {
        pendingKeys().contains(key)
    }

    private func registerPendingKey(_ key: String) {
        var keys = pendingKeys()
        keys.append(key)
        UserDefaults.standard.set(keys, forKey: idempotencyStorageKey)
    }

    private func clearPendingKey(_ key: String) {
        var keys = pendingKeys()
        keys.removeAll { $0 == key }
        UserDefaults.standard.set(keys, forKey: idempotencyStorageKey)
    }

    private func pendingKeys() -> [String] {
        UserDefaults.standard.stringArray(forKey: idempotencyStorageKey) ?? []
    }
}

enum TradeError: Error {
    case noSuitableOptions
    case invalidPrice
    case executionFailed
    case tradingLocked(String)
    case duplicateOrder
} 