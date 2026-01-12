import Foundation

class OrderService {
    private let schwabService = SchwabService.shared
    private let optionsCalculator = OptionsCalculator.shared
    
    func submitOrder(signal: Signal) async throws -> OrderResponse {
        // Get the best option contract based on signal
        let optionsEntry = optionsCalculator.calculateOptionsEntry(
            stockPrice: signal.entry,
            strategy: signal.strategy
        )
        
        guard let contract = try await getBestContract(
            symbol: signal.symbol,
            strike: optionsEntry.strike,
            type: optionsEntry.type
        ) else {
            throw TradeError.noSuitableOptions
        }
        
        let order = Order(
            symbol: signal.symbol,
            quantity: 1,  // Start with 1 contract
            orderType: .limit,
            price: contract.ask,  // Use ask price for immediate fill
            strategy: signal.strategy,
            timestamp: Date()
        )
        
        return try await schwabService.placeOrder(order: order)
    }
    
    private func getBestContract(
        symbol: String,
        strike: Double,
        type: OptionType
    ) async throws -> OptionContract? {
        let chain = try await schwabService.fetchOptionsChain(symbol: symbol)
        // Simplified for v3.0 - proper options chain handling in v3.1
        return nil
    }
}

enum TradeError: Error {
    case noSuitableOptions
    case invalidPrice
    case executionFailed
} 