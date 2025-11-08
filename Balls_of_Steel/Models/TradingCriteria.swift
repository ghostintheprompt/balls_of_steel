import Foundation

struct TradeCriteria {
    let timeWindow: ClosedRange<Date>
    let volumeThreshold: Int
    let priceAction: PriceAction
    let stopLoss: Double
    let target: Double
}

struct PatternCriteria {
    let timeWindow: String
    let volumeThreshold: Int
    let priceAction: PriceAction
    let stopLevel: Double
    let targetLevel: Double
}

enum PriceAction {
    case gapUp(Double)
    case vwapCross
    case momentum
    case panicDrop
    
    var threshold: Double {
        switch self {
        case .gapUp(let value): return value
        case .vwapCross: return 0.5 // 0.5% deviation
        case .momentum: return 0.0   // Not used
        case .panicDrop: return 3.0  // 3% drop
        }
    }
} 