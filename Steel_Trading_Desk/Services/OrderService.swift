import Foundation

@MainActor
class OrderService: ObservableObject {
    static let shared = OrderService()

    private let riskManager = DailyRiskManager.shared

    var isTradingLocked: Bool { riskManager.isTradingLocked }
    var lockReason: String? { riskManager.lockReason }

    func submitOrder(signal: Signal) async throws -> OrderResponse {
        throw TradeError.marketDataOnly
    }
}

enum TradeError: Error {
    case marketDataOnly
    case noSuitableOptions
    case invalidPrice
    case executionFailed
    case tradingLocked(String)
    case duplicateOrder
}
