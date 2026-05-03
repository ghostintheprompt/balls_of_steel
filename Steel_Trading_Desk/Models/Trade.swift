import Foundation

struct Trade: Identifiable {
    let id = UUID()
    let symbol: String
    let strategy: Strategy
    let direction: TradeDirection
    let entry: Double
    let stop: Double
    let target: Double
    let timestamp: Date
    var currentPrice: Double
    var priceHistory: [PricePoint]

    var unrealizedPnL: Double {
        let delta = direction == .bullish ? (currentPrice - entry) : (entry - currentPrice)
        return delta * 100  // Simple P&L calculation (assumes 100 shares/contracts)
    }
}

struct PricePoint: Identifiable {
    let id = UUID()
    let price: Double
    let timestamp: Date
} 
