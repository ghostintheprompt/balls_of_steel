class OrderService {
    private let schwabService = SchwabService.shared
    private let optionsCalculator = OptionsCalculator.shared
    
    func submitOrder(signal: Signal) async throws -> OrderResponse {
        // Get the best option contract based on signal
        let optionsEntry = optionsCalculator.calculateOptionsEntry(
            stockPrice: signal.price,
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
            side: .buy,
            quantity: 1,  // Start with 1 contract
            price: contract.ask,  // Use ask price for immediate fill
            stopLoss: optionsEntry.stopPrice,
            target: optionsEntry.targetPrice,
            strategy: signal.strategy,
            optionType: optionsEntry.type,
            strike: optionsEntry.strike,
            expiration: contract.expiration
        )
        
        return try await schwabService.placeOrder(order: order)
    }
    
    private func getBestContract(
        symbol: String,
        strike: Double,
        type: OptionType
    ) async throws -> OptionContract? {
        let chain = try await schwabService.fetchOptionsChain(symbol)
        return optionsCalculator.selectBestOption(chain: chain.options, strike: strike, type: type)
    }
}

enum TradeError: Error {
    case noSuitableOptions
    case invalidPrice
    case executionFailed
} 